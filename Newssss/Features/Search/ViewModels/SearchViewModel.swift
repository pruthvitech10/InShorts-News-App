//
//  SearchViewModel.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation
import Combine

@MainActor
class SearchViewModel: ObservableObject {
    static let shared = SearchViewModel()
    
    @Published var query: String = ""
    @Published var results: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var breakingNews: [Article] = []
    @Published var isLoadingBreaking: Bool = false
    
    private var hasLoadedBreakingNews = false

    private init() {} // Singleton pattern
    
    // Uses FirebaseNewsService to fetch from Firebase Storage (backend provides all news)
    
    // Load breaking news (most recent articles from all categories)
    func loadBreakingNews(force: Bool = false) async {
        // Skip if already loaded (unless forced refresh)
        if hasLoadedBreakingNews && !force {
            Logger.debug("⚡ Breaking news already loaded (\(breakingNews.count) articles)", category: .viewModel)
            return
        }
        
        isLoadingBreaking = true
        
        Logger.debug("📰 Loading breaking news from memory store...", category: .viewModel)
        
        // Get articles from important categories (memory is always populated)
        var allArticles: [Article] = []
        let importantCategories = ["politics", "world", "business", "general"]
        
        for categoryKey in importantCategories {
            if let categoryArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                Logger.debug("📦 Breaking News: Found \(categoryArticles.count) articles in '\(categoryKey)'", category: .viewModel)
                allArticles.append(contentsOf: categoryArticles)
            }
        }
        
        // Sort by date and take top 10 most recent
        let sortedArticles = allArticles.sorted {
            ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast)
        }
        
        breakingNews = Array(sortedArticles.prefix(10))
        isLoadingBreaking = false
        hasLoadedBreakingNews = true
        
        Logger.debug("✅ Loaded \(breakingNews.count) breaking news articles from \(allArticles.count) total", category: .viewModel)
    }

    // Search through ALL articles in Firebase Storage - COMPREHENSIVE!
    func search(useCache: Bool = true) async {
        // Validate first
        let (isValid, error) = ValidationUtil.validateSearchQuery(query)
        guard isValid else {
            errorMessage = error
            isLoading = false
            return
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        isLoading = true
        errorMessage = nil
        
        Logger.debug("🔍 Searching for: '\(trimmed)'", category: .viewModel)
        
        // All available categories
        let categories = ["general", "politics", "business", "technology", "entertainment", "sports", "world", "crime", "automotive", "lifestyle"]
        
        var allArticles: [Article] = []
        var missingCategories: [String] = []
        
        // STEP 1: Check which categories are already in memory
        for categoryKey in categories {
            if let categoryArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                Logger.debug("📦 Found \(categoryArticles.count) articles in '\(categoryKey)' (cached)", category: .viewModel)
                allArticles.append(contentsOf: categoryArticles)
            } else {
                Logger.debug("⚠️ '\(categoryKey)' not cached - will fetch from Firebase", category: .viewModel)
                missingCategories.append(categoryKey)
            }
        }
        
        // STEP 2: Fetch missing categories from Firebase Storage
        if !missingCategories.isEmpty && NetworkMonitor.shared.isConnected {
            Logger.debug("📡 Fetching \(missingCategories.count) missing categories from Firebase...", category: .viewModel)
            
            do {
                // Fetch all missing categories in parallel
                let fetchedArticles = try await withThrowingTaskGroup(of: (String, [Article]).self) { group in
                    for category in missingCategories {
                        group.addTask {
                            let articles = try await FirebaseNewsService.shared.fetchCategory(category)
                            return (category, articles)
                        }
                    }
                    
                    var results: [String: [Article]] = [:]
                    for try await (category, articles) in group {
                        results[category] = articles
                    }
                    return results
                }
                
                // Store fetched categories in memory for future searches
                await MainActor.run {
                    for (category, articles) in fetchedArticles {
                        NewsMemoryStore.shared.store(articles: articles, for: category)
                        allArticles.append(contentsOf: articles)
                        Logger.debug("✅ Fetched \(articles.count) articles for '\(category)'", category: .viewModel)
                    }
                }
                
            } catch {
                Logger.error("❌ Failed to fetch missing categories: \(error)", category: .viewModel)
                // Continue with whatever we have cached
            }
        }
        
        // STEP 3: If still no articles, show error
        if allArticles.isEmpty {
            Logger.debug("📡 No articles available - check internet connection", category: .viewModel)
            errorMessage = "No articles available. Please check your internet connection."
            isLoading = false
            return
        }
        
        Logger.debug("📊 Searching through \(allArticles.count) articles across all categories", category: .viewModel)
        
        // STEP 4: Filter articles matching search query
        let matchingArticles = allArticles.filter { article in
            let titleMatch = article.title.lowercased().contains(trimmed)
            let descriptionMatch = article.description?.lowercased().contains(trimmed) ?? false
            let contentMatch = article.content?.lowercased().contains(trimmed) ?? false
            let sourceMatch = article.source.name.lowercased().contains(trimmed)
            return titleMatch || descriptionMatch || contentMatch || sourceMatch
        }
        
        // STEP 5: Sort by relevance (title matches first) then by date
        results = matchingArticles.sorted { article1, article2 in
            let title1Match = article1.title.lowercased().contains(trimmed)
            let title2Match = article2.title.lowercased().contains(trimmed)
            
            // Prioritize title matches
            if title1Match && !title2Match {
                return true
            } else if !title1Match && title2Match {
                return false
            }
            
            // Then sort by date
            return (article1.publishedDate ?? .distantPast) > (article2.publishedDate ?? .distantPast)
        }
        
        isLoading = false
        
        Logger.debug("✅ Found \(results.count) matching articles for '\(query)'", category: .viewModel)
    }

    // Helper: Filter articles published in the last 48 hours
    private func filterFreshArticles(_ articles: [Article]) -> [Article] {
        let now = Date()
        let maxAge: TimeInterval = 48 * 60 * 60 // 48 hours
        return articles.filter { article in
            if let publishedDate = article.publishedDate {
                return now.timeIntervalSince(publishedDate) <= maxAge
            }
            return false
        }
    }

    // Helper: Deduplicate articles by URL
    private func deduplicateByURL(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        var unique: [Article] = []
        for article in articles {
            if !seen.contains(article.url) {
                seen.insert(article.url)
                unique.append(article)
            }
        }
        return unique
    }

    // Timeout helper
    enum TimeoutError: Error {
        case exceeded
    }

    // Fix: mark operation as @escaping and use nanoseconds variant of sleep
    func withTimeout<T>(_ operation: @escaping () async throws -> T, timeout: TimeInterval) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TimeoutError.exceeded
            }
            if let result = try await group.next() {
                group.cancelAll()
                return result
            }
            throw TimeoutError.exceeded
        }
    }
}

