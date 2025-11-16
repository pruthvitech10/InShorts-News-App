import Foundation
import Combine

// Combines news from multiple APIs into one feed
class NewsAggregatorService {
    static let shared = NewsAggregatorService()
     
    // Initializer references fixed by ensuring they are inside the class
    private let guardianAPIService = GuardianAPIService.shared
    private let nyTimesAPIService = NYTimesAPIService.shared
    private let redditAPIService = RedditAPIService.shared
    private let hackerNewsAPIService = HackerNewsAPIService.shared
    private let currentsAPIService = CurrentsAPIService.shared
    private let mediaStackAPIService = MediaStackAPIService.shared
    private let newsAPIService = NewsAPIService.shared
    private let newsDataIOService = NewsDataIOService.shared
    private let gNewsAPIService = GNewsAPIService.shared
    private let newsDataHubAPIService = NewsDataHubAPIService.shared
    private let rapidAPIService = RapidAPIService.shared
    private let sportsNewsService = SportsNewsService.shared
    private let politicalNewsService = PoliticalNewsService.shared
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
        // Priority order: Premium sources first for best quality
        let apiCalls: [(NewsCategory?) async throws -> [Article]] = [
            { try await self.fetchFromGuardian(category: $0) },
            { try await self.fetchFromNYTimes(category: $0) },
            { try await self.fetchFromReddit(category: $0) },
            { try await self.fetchFromHackerNews(category: $0) },
            { try await self.fetchFromCurrents(category: $0) },
            { try await self.fetchFromMediaStack(category: $0) },
            { try await self.fetchFromGNews(category: $0) },
            { try await self.fetchFromNewsDataHub(category: $0) },
            { try await self.fetchFromNewsDataIO(category: $0) },
            { try await self.fetchFromNewsAPI(category: $0) },
            { try await self.fetchFromRapidAPI(category: $0) }
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
         
        // Special handling for sports category
        if category == .sports {
            Logger.debug("⚽ Fetching SPORTS news with location-aware team focus", category: .network)
            let sportsArticles = try await fetchSportsNews()
            allArticles = sportsArticles
        } else if category == .politics {
            Logger.debug("🏛️ Fetching POLITICS news with location-aware focus", category: .network)
            let politicsArticles = try await fetchPoliticsNews()
            allArticles = politicsArticles
        } else if AppConfig.fetchFromAllAPIs {
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
            case .guardian:
                tasks.append(Task { try await self.fetchFromGuardian(category: category) })
            case .nyTimes:
                tasks.append(Task { try await self.fetchFromNYTimes(category: category) })
            case .reddit:
                tasks.append(Task { try await self.fetchFromReddit(category: category) })
            case .hackerNews:
                tasks.append(Task { try await self.fetchFromHackerNews(category: category) })
            case .currents:
                tasks.append(Task { try await self.fetchFromCurrents(category: category) })
            case .mediaStack:
                tasks.append(Task { try await self.fetchFromMediaStack(category: category) })
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
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode()
        
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
        Logger.debug("📡 Fetched \(articles.count) articles from NewsAPI.org (country: \(country))", category: .network)
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
                case .guardian:
                    articles = try await fetchFromGuardian(category: category)
                case .nyTimes:
                    articles = try await fetchFromNYTimes(category: category)
                case .reddit:
                    articles = try await fetchFromReddit(category: category)
                case .hackerNews:
                    articles = try await fetchFromHackerNews(category: category)
                case .currents:
                    articles = try await fetchFromCurrents(category: category)
                case .mediaStack:
                    articles = try await fetchFromMediaStack(category: category)
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
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode()
        let language = locationService.getNewsLanguageCode()
        
        var articles: [Article] = []
         
        if let category = category {
            articles = try await newsDataIOService.fetchLatestNews(category: category, country: country, language: language)
        } else {
            let categories = Array(NewsCategory.allCases.prefix(3))
            articles = try await newsDataIOService.fetchMultipleCategories(categories: categories, country: country)
        }
         
        Logger.debug("📡 Fetched \(articles.count) articles from NewsData.io (\(country), \(language))", category: .network)
        return articles
    }
     
    // Get news from RapidAPI
    private func fetchFromRapidAPI(category: NewsCategory? = nil) async throws -> [Article] {
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode().uppercased()
        let language = locationService.getNewsLanguageCode()
        
        let articles = try await rapidAPIService.fetchLatestNews(
            category: category,
            country: country,
            language: language,
            limit: 10
        )
         
        Logger.debug("📡 Fetched \(articles.count) articles from RapidAPI (\(country), \(language))", category: .network)
        return articles
    }
     
    // Get news from NewsDataHub
    private func fetchFromNewsDataHub(category: NewsCategory? = nil) async throws -> [Article] {
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode()
        let language = locationService.getNewsLanguageCode()
        
        let articles = try await newsDataHubAPIService.fetchLatestNews(
            category: category,
            country: country,
            language: language,
            limit: 10
        )
         
        Logger.debug("📡 Fetched \(articles.count) articles from NewsDataHub (\(country), \(language))", category: .network)
        return articles
    }
     
    // Get news from GNews
    private func fetchFromGNews(category: NewsCategory? = nil) async throws -> [Article] {
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode()
        let language = locationService.getNewsLanguageCode()
        
        let articles = try await gNewsAPIService.fetchTopHeadlines(
            category: category,
            country: country,
            language: language,
            max: 10
        )
         
        Logger.debug("📡 Fetched \(articles.count) articles from GNews (\(country), \(language))", category: .network)
        return articles
    }
    
    // Get news from The Guardian (Premium)
    private func fetchFromGuardian(category: NewsCategory? = nil) async throws -> [Article] {
        let articles: [Article]
        
        if let category = category {
            articles = try await guardianAPIService.fetchByCategory(category, pageSize: 20)
        } else {
            articles = try await guardianAPIService.fetchLatestNews(pageSize: 30)
        }
        
        Logger.debug("📡 Fetched \(articles.count) articles from The Guardian ⭐", category: .network)
        return articles
    }
    
    // Get news from Hacker News (Tech)
    private func fetchFromHackerNews(category: NewsCategory? = nil) async throws -> [Article] {
        // Hacker News is primarily tech news, so only fetch for tech/general categories
        guard category == nil || category == .technology || category == .general || category == .forYou else {
            return []
        }
        
        let articles = try await hackerNewsAPIService.fetchTopStories(limit: 30)
        
        Logger.debug("📡 Fetched \(articles.count) articles from Hacker News 💻", category: .network)
        return articles
    }
    
    // Get news from Reddit (Viral)
    private func fetchFromReddit(category: NewsCategory? = nil) async throws -> [Article] {
        let articles: [Article]
        
        if let category = category {
            articles = try await redditAPIService.fetchByCategory(category, limit: 20)
        } else {
            // Fetch from multiple news subreddits for variety
            articles = try await redditAPIService.fetchNewsFromMultipleSubreddits(limit: 30)
        }
        
        Logger.debug("📡 Fetched \(articles.count) articles from Reddit 🔥", category: .network)
        return articles
    }
    
    // Get news from New York Times (Premium)
    private func fetchFromNYTimes(category: NewsCategory? = nil) async throws -> [Article] {
        let articles: [Article]
        
        if let category = category {
            articles = try await nyTimesAPIService.fetchByCategory(category, limit: 20)
        } else {
            articles = try await nyTimesAPIService.fetchTopStories(limit: 30)
        }
        
        Logger.debug("📡 Fetched \(articles.count) articles from New York Times 🏆", category: .network)
        return articles
    }
    
    // Get news from Currents API (Global)
    private func fetchFromCurrents(category: NewsCategory? = nil) async throws -> [Article] {
        let locationService = LocationService.shared
        let language = locationService.getNewsLanguageCode()
        
        let articles: [Article]
        
        if let category = category {
            articles = try await currentsAPIService.fetchByCategory(category, language: language, limit: 20)
        } else {
            articles = try await currentsAPIService.fetchLatestNews(language: language, limit: 25)
        }
        
        Logger.debug("📡 Fetched \(articles.count) articles from Currents API 🌍", category: .network)
        return articles
    }
    
    // Get news from MediaStack (7,500+ sources)
    private func fetchFromMediaStack(category: NewsCategory? = nil) async throws -> [Article] {
        let locationService = LocationService.shared
        let country = locationService.getNewsCountryCode()
        
        let articles: [Article]
        
        if let category = category {
            articles = try await mediaStackAPIService.fetchByCategory(category, countries: country, limit: 20)
        } else {
            articles = try await mediaStackAPIService.fetchLatestNews(countries: country, limit: 25)
        }
        
        Logger.debug("📡 Fetched \(articles.count) articles from MediaStack 📰", category: .network)
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
    
    // MARK: - Sports News Integration
    
    /// Fetch sports news with location-aware team prioritization
    /// If user is in Naples/Italy, prioritizes Napoli and Serie A news
    private func fetchSportsNews() async throws -> [Article] {
        Logger.debug("⚽ Fetching sports news from SportsNewsService", category: .network)
        
        do {
            let sportsArticles = try await sportsNewsService.fetchSportsNews(limit: 30)
            Logger.debug("✅ Fetched \(sportsArticles.count) sports articles", category: .network)
            return sportsArticles
        } catch {
            Logger.error("❌ Failed to fetch sports news: \(error)", category: .network)
            throw error
        }
    }
    
    // MARK: - Political News Integration
    
    /// Fetch political news with location-aware prioritization
    /// If user is in Italy, prioritizes Giorgia Meloni and Italian politics
    private func fetchPoliticsNews() async throws -> [Article] {
        Logger.debug("🏛️ Fetching political news from PoliticalNewsService", category: .network)
        
        do {
            let politicsArticles = try await politicalNewsService.fetchPoliticalNews(limit: 30)
            Logger.debug("✅ Fetched \(politicsArticles.count) political articles", category: .network)
            return politicsArticles
        } catch {
            Logger.error("❌ Failed to fetch political news: \(error)", category: .network)
            throw error
        }
    }
}

extension NewsAggregatorService: NewsAggregatorServiceProtocol {}
