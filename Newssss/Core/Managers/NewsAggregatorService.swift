import Foundation
import Combine

// Combines news from multiple APIs into one feed
class NewsAggregatorService {
    static let shared = NewsAggregatorService()
     
    // Initializer references fixed by ensuring they are inside the class
    private let newsAPIService = NewsAPIService.shared
    private let newsDataIOService = NewsDataIOService.shared
    private let gNewsAPIService = GNewsAPIService.shared
    private let newsDataHubAPIService = NewsDataHubAPIService.shared
    private let rapidAPIService = RapidAPIService.shared
    private let llmService = LLMService.shared
    private var enabledSources: Set<PopularSource> = Set(PopularSource.allCases)
    private var autoFetchInterval: TimeInterval = 3600 // 1 hour
    private var autoFetchTimer: Timer?
     
    private init() {
        loadConfiguration()
    }
     
    // Try each API one by one until we get results (with timeout)
    func fetchFromAPIsSequentiallyWithTimeout(
        category: NewsCategory? = nil,
        timeout: TimeInterval = 3.0
    ) async throws -> [Article] {
        // The service methods being referenced here must be the private helper methods below
        let apiCalls: [(NewsCategory?) async throws -> [Article]] = [
            { try await self.fetchFromRapidAPI(category: $0) },
            { try await self.fetchFromNewsDataHub(category: $0) },
            { try await self.fetchFromGNews(category: $0) },
            { try await self.fetchFromNewsDataIO(category: $0) },
            { try await self.fetchFromNewsAPI(category: $0) }
        ]
        for apiCall in apiCalls {
            do {
                let articles = try await withTimeout(seconds: timeout) {
                    try await apiCall(category)
                }
                if !articles.isEmpty {
                    Logger.debug("✅ Sequential API succeeded with \(articles.count) articles", category: .network)
                    return articles
                }
            } catch {
                Logger.debug("❌ Sequential API failed or timed out: \(error.localizedDescription)", category: .network)
                continue
            }
        }
        throw NetworkError.noData
    }
     
    // Helper: Timeout wrapper for async calls (Fixed to compile)
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NetworkError.timeout
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
     
    // Settings
    func configure(enabledSources: Set<PopularSource>, autoFetchInterval: TimeInterval) {
        self.enabledSources = enabledSources
        self.autoFetchInterval = autoFetchInterval
        saveConfiguration()
        restartAutoFetch()
        Logger.debug("News Aggregator configured with \(enabledSources.count) sources", category: .general)
    }
     
    func getEnabledSources() -> Set<PopularSource> {
        return enabledSources
    }
     
    func getAutoFetchInterval() -> TimeInterval {
        return autoFetchInterval
    }
     
    // Main function to get news from all sources
    func fetchAggregatedNews(category: NewsCategory? = nil, useLocationBased: Bool = true) async throws -> [EnhancedArticle] {
        var allArticles: [Article] = []
         
        Logger.debug("🔄 AGGREGATOR: Category=\(category?.rawValue ?? "nil"), FetchFromAll=\(AppConfig.fetchFromAllAPIs)", category: .network)
         
        if AppConfig.fetchFromAllAPIs {
            // FETCH FROM ALL APIs SIMULTANEOUSLY - Get the best news from everywhere!
            let articles: [Article] = try await fetchFromAllAPIsSimultaneously(category: category)
            allArticles = articles
        } else if useLocationBased {
            // Fetch location-based news (70% local, 30% global)
            let articles: [Article] = try await fetchLocationBasedNews(category: category)
            allArticles = articles
        } else {
            // Single API fallback mode
            allArticles = try await fetchFromGNews(category: category)
        }
        
        // FILTER OUT OLD NEWS (older than 24 hours)
        let freshArticles = filterByFreshness(allArticles)
        
        // Remove duplicates based on URL
        let uniqueArticles = removeDuplicates(from: freshArticles)
        
        // Sort by newest first
        let sortedArticles = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        Logger.debug("✅ Total fresh unique articles: \(sortedArticles.count)", category: .network)
        
        // Enhance articles with AI
        var enhancedArticles: [EnhancedArticle] = []
        for article in sortedArticles.prefix(20) {
            do {
                let enhanced = try await llmService.enhanceArticle(article)
                enhancedArticles.append(enhanced)
            } catch {
                // If enhancement fails, create basic enhanced article
                enhancedArticles.append(EnhancedArticle(article: article))
            }
        }
        
        return enhancedArticles
    }
    
    // Only keep recent articles
    private func filterByFreshness(_ articles: [Article]) -> [Article] {
        let now = Date()
        let maxAge = AppConfig.maximumArticleAge // 24 hours
        
        Logger.debug("🔍 FRESHNESS FILTER: Checking \(articles.count) articles...", category: .network)
        
        let freshArticles = articles.filter { article in
            let publishedDate = article.publishedDate ?? Date()
            let age = now.timeIntervalSince(publishedDate)
            return age <= maxAge
        }
        
        Logger.debug("🔍 FRESHNESS RESULT: \(freshArticles.count) articles passed filter", category: .network)
        return freshArticles
    }
    
    // Fetch from all APIs at once for speed
    private func fetchFromAllAPIsSimultaneously(category: NewsCategory? = nil) async throws -> [Article] {
        Logger.debug("🚀 Fetching from ALL APIs simultaneously...", category: .network)
        
        // Create tasks for each enabled API
        var tasks: [Task<[Article], Error>] = []
        for provider in AppConfig.enabledAPIs as [NewsAPIProvider] {
            switch provider {
            case .newsAPI:
                tasks.append(Task { try await self.fetchFromNewsAPI(category: category) })
            case .newsDataIO:
                tasks.append(Task { try await self.fetchFromNewsDataIO(category: category) })
            case .gnews:
                tasks.append(Task { try await self.fetchFromGNews(category: category) })
            case .rapidAPI:
                tasks.append(Task { try await self.fetchFromRapidAPI(category: category) })
            case .newsDataHub:
                tasks.append(Task { try await self.fetchFromNewsDataHub(category: category) })
            case .all:
                break // .all is handled by fetching from all APIs
            }
        }
        
        let merged: [Article] = await withTaskGroup(of: [Article].self) { group in
            for task in tasks {
                group.addTask {
                    do {
                        return try await task.value
                    } catch {
                        Logger.error("❌ Parallel API call failed: \(error.localizedDescription)", category: .network)
                        return []
                    }
                }
            }
            
            var collected: [Article] = []
            for await articles in group {
                collected.append(contentsOf: articles)
            }
            return collected
        }
        
        if merged.isEmpty {
            throw NetworkError.noData
        }
        
        return merged
    }
    
    // Remove duplicate articles by URL
    private func removeDuplicates(from articles: [Article]) -> [Article] {
        var seenURLs = Set<String>()
        var uniqueArticles: [Article] = []
         
        for article in articles {
            let url = article.url.lowercased()
            if !seenURLs.contains(url) {
                seenURLs.insert(url)
                uniqueArticles.append(article)
            }
        }
         
        let duplicateCount = articles.count - uniqueArticles.count
        if duplicateCount > 0 {
            Logger.debug("🗑️ Removed \(duplicateCount) duplicate articles", category: .network)
        }
         
        return uniqueArticles
    }
     
    // Get news from NewsAPI
    private func fetchFromNewsAPI(category: NewsCategory? = nil, page: Int = 1, pageSize: Int = 10) async throws -> [Article] {
        var articles: [Article] = []
        if let category = category {
            let fetchedArticles = try await newsAPIService.fetchTopHeadlines(category: category, page: page, pageSize: pageSize)
            articles = filterByEnabledSources(fetchedArticles)
        } else {
            for category in NewsCategory.allCases.prefix(3) {
                let fetchedArticles = try await newsAPIService.fetchTopHeadlines(category: category, page: page, pageSize: pageSize)
                articles.append(contentsOf: filterByEnabledSources(fetchedArticles))
            }
        }
        Logger.debug("📡 Fetched \(articles.count) articles from NewsAPI.org", category: .network)
        return articles
    }
     
    // Get news based on user's location
    private func fetchLocationBasedNews(category: NewsCategory? = nil) async throws -> [Article] {
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode()
        let language = locationService.getNewsLanguageCode()
         
        Logger.debug("📍 LOCATION NEWS: Fetching for \(locationService.detectedCountry.displayName) (\(country), \(language))", category: .network)
         
        var localArticles: [Article] = []
        var globalArticles: [Article] = []
         
        // TRY ALL APIs FOR LOCAL NEWS (with fallback)
        localArticles = await fetchLocationNewsWithFallback(
            category: category,
            country: country,
            language: language,
            isLocal: true
        )
         
        // TRY ALL APIs FOR GLOBAL NEWS (with fallback)
        globalArticles = await fetchLocationNewsWithFallback(
            category: category,
            country: nil as String?,
            language: "en",
            isLocal: false
        )
         
        // Mix articles: 70% local, 30% global
        let totalArticles = 30
        let localCount = Int(Double(totalArticles) * 0.7) // 21 local
        let globalCount = totalArticles - localCount // 9 global
         
        let selectedLocal = Array(localArticles.prefix(localCount))
        let selectedGlobal = Array(globalArticles.prefix(globalCount))
         
        var mixedArticles = selectedLocal + selectedGlobal
        mixedArticles.shuffle() // Mix them up for variety
         
        Logger.debug("✅ Mixed news: \(selectedLocal.count) local + \(selectedGlobal.count) global = \(mixedArticles.count) total", category: .network)
         
        return mixedArticles
    }
     
    // Try location-based news, fallback to US if it fails
    private func fetchLocationNewsWithFallback(
        category: NewsCategory?,
        country: String?,
        language: String,
        isLocal: Bool
    ) async -> [Article] {
        let newsType = isLocal ? "LOCAL" : "GLOBAL"
         
        Logger.debug("🔄 Fetching \(newsType) news with fallback (country: \(country ?? "nil"))", category: .network)
         
        // Try each API in enabled APIs list
        for provider in AppConfig.enabledAPIs as [NewsAPIProvider] {
            do {
                Logger.debug("🔄 Trying \(provider.displayName) for \(newsType) news...", category: .network)
                 
                var articles: [Article] = []
                 
                switch provider {
                case .newsAPI:
                    articles = try await fetchFromNewsAPI(category: category)
                case .newsDataIO:
                    articles = try await fetchFromNewsDataIO(category: category)
                case .gnews:
                    articles = try await fetchFromGNews(category: category)
                case .rapidAPI:
                    articles = try await rapidAPIService.fetchLatestNews(
                        category: category ?? NewsCategory.general,
                        country: country ?? "it",
                        language: language,
                        limit: 10
                    )
                case .newsDataHub:
                    articles = try await newsDataHubAPIService.fetchLatestNews(
                        category: category,
                        country: country ?? "it",
                        language: language,
                        limit: 10
                    )
                case .all:
                    break // .all is not used in fallback mode
                }
                 
                if !articles.isEmpty {
                    Logger.debug("✅ SUCCESS: \(provider.displayName) returned \(articles.count) \(newsType) articles", category: .network)
                    return articles
                } else {
                    Logger.debug("⚠️ \(provider.displayName) returned 0 \(newsType) articles, trying next...", category: .network)
                }
                 
            } catch {
                Logger.error("❌ \(provider.displayName) FAILED for \(newsType): \(error.localizedDescription)", category: .network)
            }
        }
         
        Logger.error("⚠️ All APIs failed for \(newsType) news, returning empty array", category: .network)
        return [] // Return empty instead of throwing
    }
     
    // Get news from NewsData.io
    private func fetchFromNewsDataIO(category: NewsCategory? = nil) async throws -> [Article] {
        var articles: [Article] = []
         
        if let category = category {
            articles = try await newsDataIOService.fetchLatestNews(category: category, country: "us", language: "en")
        } else {
            let categories = Array(NewsCategory.allCases.prefix(3))
            articles = try await newsDataIOService.fetchMultipleCategories(categories: categories, country: "us")
        }
         
        Logger.debug("📡 Fetched \(articles.count) articles from NewsData.io", category: .network)
        return articles
    }
     
    // Get news from RapidAPI
    private func fetchFromRapidAPI(category: NewsCategory? = nil) async throws -> [Article] {
        let articles = try await rapidAPIService.fetchLatestNews(
            category: category,
            country: "us",
            language: "en",
            limit: 10
        )
         
        Logger.debug("📡 Fetched \(articles.count) articles from RapidAPI", category: .network)
        return articles
    }
     
    // Get news from NewsDataHub
    private func fetchFromNewsDataHub(category: NewsCategory? = nil) async throws -> [Article] {
        let articles = try await newsDataHubAPIService.fetchLatestNews(
            category: category,
            country: "us",
            language: "en",
            limit: 10
        )
         
        Logger.debug("📡 Fetched \(articles.count) articles from NewsDataHub", category: .network)
        return articles
    }
     
    // Get news from GNews
    private func fetchFromGNews(category: NewsCategory? = nil) async throws -> [Article] {
        let articles = try await gNewsAPIService.fetchTopHeadlines(
            category: category,
            country: "us",
            language: "en",
            max: 10
        )
         
        Logger.debug("📡 Fetched \(articles.count) articles from GNews", category: .network)
        return articles
    }
     
    // Background auto-refresh
    func startAutoFetch(completion: @escaping ([EnhancedArticle]) -> Void) {
        stopAutoFetch()
         
        autoFetchTimer = Timer.scheduledTimer(withTimeInterval: autoFetchInterval, repeats: true) { [weak self] _ in
            Task {
                guard let self = self else { return }
                do {
                    let articles = try await self.fetchAggregatedNews()
                    await MainActor.run {
                        completion(articles)
                    }
                } catch {
                    Logger.error("Auto-fetch failed: \(error.localizedDescription)", category: .general)
                }
            }
        }
         
        Logger.debug("Started auto-fetch with interval: \(autoFetchInterval)s", category: .general)
    }
     
    func stopAutoFetch() {
        autoFetchTimer?.invalidate()
        autoFetchTimer = nil
        Logger.debug("Stopped auto-fetch", category: .general)
    }
     
    func restartAutoFetch() {
        if autoFetchTimer != nil {
            stopAutoFetch()
        }
    }
     
    // Helper functions
    private func filterByEnabledSources(_ articles: [Article]) -> [Article] {
        let enabledSourceIds = enabledSources.map { $0.sourceId }
        return articles.filter { article in
            enabledSourceIds.contains { sourceId in
                article.source.name.lowercased().contains(sourceId.lowercased()) ||
                article.source.id?.lowercased() == sourceId.lowercased()
            }
        }
    }
     
    private func loadConfiguration() {
        if let sourcesData = UserDefaults.standard.data(forKey: "aggregator_sources"),
            let sources = try? JSONDecoder().decode(Set<PopularSource>.self, from: sourcesData) {
            self.enabledSources = sources
        }
         
        self.autoFetchInterval = UserDefaults.standard.double(forKey: "aggregator_interval")
        if self.autoFetchInterval == 0 {
            self.autoFetchInterval = 3600 // Default 1 hour
        }
    }
     
    private func saveConfiguration() {
        if let sourcesData = try? JSONEncoder().encode(enabledSources) {
            UserDefaults.standard.set(sourcesData, forKey: "aggregator_sources")
        }
        UserDefaults.standard.set(autoFetchInterval, forKey: "aggregator_interval")
    }
}

extension NewsAggregatorService: NewsAggregatorServiceProtocol {}
