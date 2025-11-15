//
//  BreakingNewsService.swift
//  dailynews
//
//  Real-time breaking news service with live updates
//

import Foundation
import Combine

// MARK: - BreakingNewsItem

struct BreakingNewsItem: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String?
    let source: String
    let imageUrl: String?
    let articleUrl: String
    let publishedAt: Date
    let category: String
    let priority: Priority
    
    enum Priority: String, Codable, Comparable {
        case critical = "critical"  // Major breaking news
        case high = "high"          // Important updates
        case normal = "normal"      // Regular news
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            let order: [Priority] = [.critical, .high, .normal]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }
    
    var timeAgo: String {
        publishedAt.compactTimeAgo()
    }
    
    var categoryIcon: String {
        switch category.lowercased() {
        case "politics": return "building.columns.fill"
        case "business": return "briefcase.fill"
        case "technology": return "cpu.fill"
        case "sports": return "sportscourt.fill"
        case "entertainment": return "film.fill"
        case "health": return "heart.fill"
        case "science": return "atom"
        default: return "newspaper.fill"
        }
    }
    
    var categoryColor: String {
        switch priority {
        case .critical: return "red"
        case .high: return "orange"
        case .normal: return "blue"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(articleUrl)
    }
    
    static func == (lhs: BreakingNewsItem, rhs: BreakingNewsItem) -> Bool {
        lhs.articleUrl == rhs.articleUrl
    }
}

// MARK: - BreakingNewsService

@MainActor
final class BreakingNewsService: ObservableObject {
    static let shared = BreakingNewsService()
    
    // MARK: - Published Properties
    
    @Published private(set) var breakingNews: [BreakingNewsItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var lastUpdateTime: Date?
    
    // MARK: - Configuration
    
    private struct Config {
        static let refreshInterval: TimeInterval = 300 // 5 minutes
        static let cacheKey = "cached_breaking_news"
        static let cacheTimeKey = "breaking_cache_timestamp"
        static let cacheDuration: TimeInterval = 300 // 5 minutes
        static let maxItems = 30
        static let maxArticleAge: TimeInterval = 7 * 24 * 3600 // 7 days (same as main feed)
        static let itemsPerCategory = 5
    }
    
    // MARK: - Private Properties
    
    private var refreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // API Services
    private let newsDataIOService = NewsDataIOService.shared
    private let gNewsAPIService = GNewsAPIService.shared
    private let newsAPIService = NewsAPIService.shared
    private let newsDataHubAPIService = NewsDataHubAPIService.shared
    private let rapidAPIService = RapidAPIService.shared
    
    // MARK: - Initialization
    
    private init() {
        // Load cached data immediately
        loadCachedNews()
        
        // Start background refresh
        startAutoRefresh()
    }
    
    deinit {
        // Timer is automatically invalidated when deallocated
    }
    
    // MARK: - Public API
    
    func fetchBreakingNews(forceRefresh: Bool = false) async {
        // Prevent multiple simultaneous fetches
        guard !isLoading else {
            Logger.debug("Breaking news fetch already in progress", category: .network)
            return
        }
        
        // Check cache if not forcing refresh
        if !forceRefresh, let cached = getCachedNews(), !cached.isEmpty {
            Logger.debug("Using cached breaking news (\(cached.count) items)", category: .network)
            breakingNews = cached
            return
        }
        
        isLoading = true
        error = nil
        
        Logger.debug("🔥 Fetching breaking news from all APIs", category: .network)
        
        do {
            let items = try await fetchFromAllAPIs()
            
            // Process results
            let processed = processBreakingNews(items)
            
            breakingNews = processed
            lastUpdateTime = Date()
            error = nil
            
            // Cache results
            cacheNews(processed)
            
            Logger.debug("✅ Breaking news updated: \(processed.count) items", category: .network)
        } catch {
            self.error = error.localizedDescription
            Logger.error("❌ Failed to fetch breaking news: \(error)", category: .network)
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await fetchBreakingNews(forceRefresh: true)
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        stopAutoRefresh()
        
        refreshTask = Task { [weak self] in
            // Initial fetch
            await self?.fetchBreakingNews()
            
            // Periodic refresh
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Config.refreshInterval * 1_000_000_000))
                
                guard !Task.isCancelled else { break }
                await self?.fetchBreakingNews(forceRefresh: true)
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    // MARK: - Fetching Logic
    
    private func fetchFromAllAPIs() async throws -> [BreakingNewsItem] {
        await withTaskGroup(of: Result<[BreakingNewsItem], Error>.self) { group in
            var allItems: [BreakingNewsItem] = []
            var successCount = 0
            var failCount = 0
            
            // Add tasks for each API
            if AppConfig.enabledAPIs.contains(.rapidAPI) {
                group.addTask { await self.fetchFromAPI(.rapidAPI) }
            }
            if AppConfig.enabledAPIs.contains(.newsDataHub) {
                group.addTask { await self.fetchFromAPI(.newsDataHub) }
            }
            if AppConfig.enabledAPIs.contains(.gnews) {
                group.addTask { await self.fetchFromAPI(.gnews) }
            }
            if AppConfig.enabledAPIs.contains(.newsDataIO) {
                group.addTask { await self.fetchFromAPI(.newsDataIO) }
            }
            if AppConfig.enabledAPIs.contains(.newsAPI) {
                group.addTask { await self.fetchFromAPI(.newsAPI) }
            }
            
            // Collect results
            for await result in group {
                switch result {
                case .success(let items):
                    allItems.append(contentsOf: items)
                    successCount += 1
                case .failure(let error):
                    failCount += 1
                    Logger.error("API failed: \(error.localizedDescription)", category: .network)
                }
            }
            
            Logger.debug("📊 Breaking news: \(successCount) APIs succeeded, \(failCount) failed, \(allItems.count) total items", category: .network)
            
            return allItems
        }
    }
    
    private func fetchFromAPI(_ provider: NewsAPIProvider) async -> Result<[BreakingNewsItem], Error> {
        do {
            let items = try await fetchBreakingNewsFromProvider(provider)
            Logger.debug("✅ \(provider.displayName): \(items.count) breaking news", category: .network)
            return .success(items)
        } catch {
            Logger.error("❌ \(provider.displayName) failed: \(error.localizedDescription)", category: .network)
            return .failure(error)
        }
    }
    
    private func fetchBreakingNewsFromProvider(_ provider: NewsAPIProvider) async throws -> [BreakingNewsItem] {
        let categories: [NewsCategory] = [.general, .business, .technology, .politics]
        var allItems: [BreakingNewsItem] = []
        
        switch provider {
        case .rapidAPI:
            let articles = try await rapidAPIService.fetchLatestNews(
                category: nil,
                country: "it",
                language: "it",
                limit: Config.itemsPerCategory
            )
            allItems = articles.compactMap { convertToBreakingNews(article: $0, category: "general") }
            
        case .newsDataHub:
            let articles = try await newsDataHubAPIService.fetchLatestNews(
                category: nil,
                country: "it",
                language: "it",
                limit: Config.itemsPerCategory
            )
            allItems = articles.compactMap { convertToBreakingNews(article: $0, category: "general") }
            
        case .gnews:
            for category in categories.prefix(2) { // Limit categories for free tier
                let articles = try await gNewsAPIService.fetchTopHeadlines(
                    category: category,
                    country: "it",
                    language: "it",
                    max: Config.itemsPerCategory
                )
                let items = articles.compactMap { convertToBreakingNews(article: $0, category: category.rawValue) }
                allItems.append(contentsOf: items)
            }
            
        case .newsDataIO:
            for category in categories.prefix(2) { // Limit categories for free tier
                let articles = try await newsDataIOService.fetchLatestNews(
                    category: category,
                    country: nil,
                    language: "it"
                )
                let items = articles.compactMap { convertToBreakingNews(article: $0, category: category.rawValue) }
                allItems.append(contentsOf: items)
            }
            
        case .newsAPI:
            for category in categories.prefix(2) { // Limit categories for free tier
                let articles = try await newsAPIService.fetchTopHeadlines(
                    category: category,
                    page: 1,
                    pageSize: Config.itemsPerCategory
                )
                let items = articles.compactMap { convertToBreakingNews(article: $0, category: category.rawValue) }
                allItems.append(contentsOf: items)
            }
            
        case .all:
            break
        }
        
        return allItems
    }
    
    // MARK: - Processing
    
    private func processBreakingNews(_ items: [BreakingNewsItem]) -> [BreakingNewsItem] {
        // 1. Filter by freshness
        let fresh = filterByFreshness(items)
        
        // 2. Remove duplicates
        let unique = removeDuplicates(from: fresh)
        
        // 3. Sort by priority and date
        let sorted = unique.sorted { first, second in
            if first.priority != second.priority {
                return first.priority < second.priority
            }
            return first.publishedAt > second.publishedAt
        }
        
        // 4. Take top items
        return Array(sorted.prefix(Config.maxItems))
    }
    
    private func filterByFreshness(_ items: [BreakingNewsItem]) -> [BreakingNewsItem] {
        let now = Date()
        let maxAge = Config.maxArticleAge
        
        let fresh = items.filter { item in
            let age = now.timeIntervalSince(item.publishedAt)
            return age <= maxAge && age >= 0 // Also filter future dates
        }
        
        let filtered = items.count - fresh.count
        if filtered > 0 {
            Logger.debug("🗑️ Filtered \(filtered) old items", category: .network)
        }
        
        return fresh
    }
    
    private func removeDuplicates(from items: [BreakingNewsItem]) -> [BreakingNewsItem] {
        let unique = Array(Set(items))
        
        let duplicates = items.count - unique.count
        if duplicates > 0 {
            Logger.debug("🗑️ Removed \(duplicates) duplicates", category: .network)
        }
        
        return unique
    }
    
    // MARK: - Conversion
    
    private func convertToBreakingNews(article: Article, category: String) -> BreakingNewsItem? {
        guard let publishedDate = article.publishedDate else {
            return nil
        }
        
        // Only include recent news
        let age = Date().timeIntervalSince(publishedDate)
        guard age <= Config.maxArticleAge && age >= 0 else {
            return nil
        }
        
        let priority = determinePriority(
            title: article.title,
            description: article.description
        )
        
        return BreakingNewsItem(
            id: article.id.uuidString,
            title: article.title,
            description: article.description,
            source: article.source.name,
            imageUrl: article.urlToImage,
            articleUrl: article.url,
            publishedAt: publishedDate,
            category: category,
            priority: priority
        )
    }
    
    private func determinePriority(title: String, description: String?) -> BreakingNewsItem.Priority {
        let text = "\(title) \(description ?? "")".lowercased()
        
        // Critical keywords
        let criticalKeywords = [
            "breaking", "urgent", "alert", "emergency",
            "major", "tragedy", "disaster", "crisis"
        ]
        if criticalKeywords.contains(where: text.contains) {
            return .critical
        }
        
        // High priority keywords
        let highKeywords = [
            "announces", "launches", "reports", "confirms",
            "reveals", "wins", "unveils", "introduces"
        ]
        if highKeywords.contains(where: text.contains) {
            return .high
        }
        
        return .normal
    }
    
    // MARK: - Caching
    
    private func cacheNews(_ news: [BreakingNewsItem]) {
        Task.detached(priority: .utility) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            if let encoded = try? encoder.encode(news) {
                UserDefaults.standard.set(encoded, forKey: Config.cacheKey)
                UserDefaults.standard.set(Date(), forKey: Config.cacheTimeKey)
            }
        }
    }
    
    private func getCachedNews() -> [BreakingNewsItem]? {
        // Check cache age
        if let cacheDate = UserDefaults.standard.object(forKey: Config.cacheTimeKey) as? Date {
            let cacheAge = Date().timeIntervalSince(cacheDate)
            guard cacheAge < Config.cacheDuration else {
                Logger.debug("Cache expired (\(Int(cacheAge))s old)", category: .network)
                return nil
            }
        } else {
            return nil
        }
        
        // Load cached data
        guard let data = UserDefaults.standard.data(forKey: Config.cacheKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode([BreakingNewsItem].self, from: data)
    }
    
    private func loadCachedNews() {
        if let cached = getCachedNews() {
            breakingNews = cached
            lastUpdateTime = UserDefaults.standard.object(forKey: Config.cacheTimeKey) as? Date
            Logger.debug("Loaded \(cached.count) breaking news from cache", category: .network)
        }
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: Config.cacheKey)
        UserDefaults.standard.removeObject(forKey: Config.cacheTimeKey)
        Logger.debug("Breaking news cache cleared", category: .network)
    }
}

// MARK: - Statistics

extension BreakingNewsService {
    struct Statistics {
        let totalItems: Int
        let criticalItems: Int
        let highItems: Int
        let normalItems: Int
        let uniqueSources: Int
        let categories: [String: Int]
        let oldestItem: Date?
        let newestItem: Date?
        
        var priorityBreakdown: String {
            "Critical: \(criticalItems), High: \(highItems), Normal: \(normalItems)"
        }
    }
    
    func getStatistics() -> Statistics {
        let sources = Set(breakingNews.map { $0.source })
        let categories = Dictionary(grouping: breakingNews, by: { $0.category })
            .mapValues { $0.count }
        
        return Statistics(
            totalItems: breakingNews.count,
            criticalItems: breakingNews.filter { $0.priority == .critical }.count,
            highItems: breakingNews.filter { $0.priority == .high }.count,
            normalItems: breakingNews.filter { $0.priority == .normal }.count,
            uniqueSources: sources.count,
            categories: categories,
            oldestItem: breakingNews.map { $0.publishedAt }.min(),
            newestItem: breakingNews.map { $0.publishedAt }.max()
        )
    }
}
