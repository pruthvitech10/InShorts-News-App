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
    @Published var query: String = ""
    @Published var results: [Article] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var breakingNews: [Article] = []
    @Published var isLoadingBreaking: Bool = false

    // Uses FirebaseNewsService to fetch from Firebase Storage (backend provides all news)
    
    // Load breaking news (most recent articles from all categories)
    func loadBreakingNews() async {
        isLoadingBreaking = true
        
        Logger.debug("📰 Loading breaking news from memory store...", category: .viewModel)
        
        // Get articles from important categories (memory is always populated)
        var allArticles: [Article] = []
        let importantCategories = ["politics", "world", "business", "general"]
        
        for categoryKey in importantCategories {
            if let categoryArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                Logger.debug("� Breaking News: Found \(categoryArticles.count) articles in '\(categoryKey)'", category: .viewModel)
                allArticles.append(contentsOf: categoryArticles)
            }
        }
        
        // Sort by date and take top 10 most recent
        let sortedArticles = allArticles.sorted {
            ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast)
        }
        
        breakingNews = Array(sortedArticles.prefix(10))
        isLoadingBreaking = false
        
        Logger.debug("✅ Loaded \(breakingNews.count) breaking news articles from \(allArticles.count) total", category: .viewModel)
    }

    // Search through memory store - INSTANT!
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
        
        Logger.debug("🔍 Searching memory store for: '\(trimmed)'", category: .viewModel)
        
        // Search through ALL categories in memory store
        var allArticles: [Article] = []
        let categories = ["general", "politics", "business", "technology", "entertainment", "sports", "world", "crime", "automotive", "lifestyle"]
        
        for categoryKey in categories {
            if let categoryArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                Logger.debug("📦 Found \(categoryArticles.count) articles in '\(categoryKey)' category", category: .viewModel)
                allArticles.append(contentsOf: categoryArticles)
            } else {
                Logger.debug("⚠️ No articles in '\(categoryKey)' category", category: .viewModel)
            }
        }
        
        // If memory is empty, wait for auto-refresh
        if allArticles.isEmpty {
            Logger.debug("📡 Memory empty, waiting for auto-refresh...", category: .viewModel)
            
            // Show message to user
            errorMessage = "Loading articles... Please wait for auto-refresh."
            isLoading = false
            return
        }
        
        Logger.debug("📊 Searching through \(allArticles.count) articles", category: .viewModel)
        
        // Filter articles matching search query
        let matchingArticles = allArticles.filter { article in
            let titleMatch = article.title.lowercased().contains(trimmed)
            let descriptionMatch = article.description?.lowercased().contains(trimmed) ?? false
            let contentMatch = article.content?.lowercased().contains(trimmed) ?? false
            return titleMatch || descriptionMatch || contentMatch
        }
        
        // Sort by date (most recent first)
        results = matchingArticles.sorted {
            ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast)
        }
        
        isLoading = false
        
        Logger.debug("✅ Found \(results.count) matching articles for '\(query)'", category: .viewModel)
        
        // Don't set error message if no results - just show empty state
        // errorMessage is only for actual errors (network, etc.)
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

