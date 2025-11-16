import Foundation
import Combine

// Combines news from multiple APIs into one feed
class NewsAggregatorService {
    static let shared = NewsAggregatorService()
     
    // Initializer references fixed by ensuring they are inside the class
    // 🇮🇹 Italian Sources ONLY
    private let italianNewsService = ItalianNewsService.shared
    
    // 🎯 Specialized Services
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
        // Priority order: Italy-focused sources only
        let apiCalls: [(NewsCategory?) async throws -> [Article]] = [
            { _ in try await self.italianNewsService.fetchItalianNews(category: category?.rawValue, limit: 1000) }
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
         
        // Special handling for location-aware categories
        if category == .sports {
            Logger.debug("⚽ Fetching SPORTS news with location-aware team focus", category: .network)
            let sportsArticles = try await fetchSportsNews()
            allArticles = sportsArticles
        } else if category == .politics {
            Logger.debug("🏛️ Fetching POLITICS news with location-aware focus", category: .network)
            let politicsArticles = try await fetchPoliticsNews()
            allArticles = politicsArticles
        } else if category == .technology {
            // Technology is global - no location priority
            Logger.debug("💻 Fetching TECHNOLOGY news (global, no location priority)", category: .network)
            let techArticles = try await fetchFromAllAPIsSimultaneously(category: category)
            allArticles = techArticles
        } else if category != nil {
            // All other categories: Business, Entertainment, Health, Science, etc.
            // Apply location priority: Italy → Europe → Global
            Logger.debug("📰 Fetching \(category?.displayName ?? "news") with location priority", category: .network)
            let prioritizedArticles = try await fetchLocationPrioritizedNews(category: category)
            allArticles = prioritizedArticles
        } else if AppConfig.fetchFromAllAPIs {
            // FETCH FROM ALL APIs SIMULTANEOUSLY - Get the best news from everywhere!
            let articles: [Article] = try await fetchFromAllAPIsSimultaneously(category: category)
            allArticles = articles
        } else {
            // Default: Fetch from Italian sources only (unlimited)
            let italianArticles = try await italianNewsService.fetchItalianNews(category: category?.rawValue, limit: 1000)
            
            // Only Italian articles
            allArticles = italianArticles
        }
        
        // FILTER OUT OLD NEWS (older than 24 hours)
        let freshArticles = filterByFreshness(allArticles)
        
        // Remove duplicates based on URL
        let uniqueArticles = removeDuplicates(from: freshArticles)
        
        // Sort by newest first
        let sortedArticles = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        Logger.debug("✅ Total fresh unique articles: \(sortedArticles.count)", category: .network)
        
        // NO AI ENHANCEMENT - Too slow for 200+ articles
        // Just wrap articles in EnhancedArticle
        let enhancedArticles = sortedArticles.map { EnhancedArticle(article: $0) }
        
        Logger.debug("✅ Returning \(enhancedArticles.count) articles (no AI enhancement for speed)", category: .network)
        
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
        
        // Create tasks for enabled APIs (Italy-focused)
        var tasks: [Task<[Article], Error>] = []
        
        // Fetch from Italian sources (unlimited) + Guardian (minimal)
        tasks.append(Task { 
            try await self.italianNewsService.fetchItalianNews(category: category?.rawValue, limit: 1000)
        })
        
        // Guardian removed - Italian sources only
        
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
    
    // MARK: - Location Prioritized News (All Categories)
    
    /// Fetch news with location priority: Italy → Europe → Global
    /// Used for Business, Entertainment, Health, Science, etc.
    private func fetchLocationPrioritizedNews(category: NewsCategory?) async throws -> [Article] {
        let locationService = LocationService.shared
        let userCountry = locationService.detectedCountry.code.uppercased()
        
        Logger.debug("🌍 Fetching \(category?.displayName ?? "news") with priority for \(userCountry)", category: .network)
        
        var allArticles: [Article] = []
        
        // Priority 1: Local news (Italy if in Italy, US if in US, etc.) - NO LIMIT
        let localArticles = try await fetchLocalNewsForCategory(category: category, country: userCountry)
        allArticles.append(contentsOf: localArticles)  // ALL local articles
        Logger.debug("✅ Added \(localArticles.count) local articles", category: .network)
        
        // Priority 2: Regional news (Europe if in Italy/EU) - NO LIMIT
        if isEuropeanCountry(userCountry) {
            let europeanArticles = try await fetchEuropeanNewsForCategory(category: category)
            allArticles.append(contentsOf: europeanArticles)  // ALL European articles
            Logger.debug("✅ Added \(europeanArticles.count) European articles", category: .network)
        }
        
        // Priority 3: Global news - NO LIMIT
        let globalArticles = try await fetchGlobalNewsForCategory(category: category)
        allArticles.append(contentsOf: globalArticles)  // ALL global articles
        Logger.debug("✅ Added \(globalArticles.count) global articles", category: .network)
        
        // Remove duplicates and sort by date - NO LIMIT
        let uniqueArticles = removeDuplicates(from: allArticles)
        let sortedArticles = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        Logger.debug("✅ Total prioritized articles: \(sortedArticles.count)", category: .network)
        return sortedArticles  // Return ALL articles
    }
    
    /// Fetch local news for a specific country
    private func fetchLocalNewsForCategory(category: NewsCategory?, country: String) async throws -> [Article] {
        var articles: [Article] = []
        
        // SPECIAL: If Italy, use dedicated Italian news sources (ANSA, Repubblica, Corriere)
        if country == "IT" {
            Logger.debug("🇮🇹 Using Italian news sources (ANSA, Repubblica, Corriere)", category: .network)
            do {
                let italianArticles = try await italianNewsService.fetchItalianNews(
                    category: category?.rawValue,
                    limit: 15
                )
                articles.append(contentsOf: italianArticles)
                Logger.debug("✅ Fetched \(italianArticles.count) articles from Italian sources", category: .network)
            } catch {
                Logger.error("❌ Italian news sources failed: \(error)", category: .network)
            }
        }
        
        // Guardian removed - Italian sources only
        
        return articles
    }
    
    /// Fetch European news
    private func fetchEuropeanNewsForCategory(category: NewsCategory?) async throws -> [Article] {
        var articles: [Article] = []
        
        // Guardian removed - Italian sources only
        
        return articles
    }
    
    /// Fetch global news
    private func fetchGlobalNewsForCategory(category: NewsCategory?) async throws -> [Article] {
        var articles: [Article] = []
        
        // All external APIs removed - Italian sources only
        
        return articles
    }
    
    /// Check if country is in Europe
    private func isEuropeanCountry(_ countryCode: String) -> Bool {
        let europeanCountries = ["IT", "FR", "DE", "ES", "GB", "PT", "NL", "BE", "AT", "CH", "SE", "NO", "DK", "FI", "PL", "GR", "IE", "CZ", "HU", "RO"]
        return europeanCountries.contains(countryCode)
    }
}

extension NewsAggregatorService: NewsAggregatorServiceProtocol {}
