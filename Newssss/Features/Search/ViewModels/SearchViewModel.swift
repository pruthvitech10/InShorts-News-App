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

    private let newsAPIService = NewsAPIService.shared
    private let newsDataIOService = NewsDataIOService.shared
    private let gNewsAPIService = GNewsAPIService.shared
    private let newsDataHubAPIService = NewsDataHubAPIService.shared
    private let rapidAPIService = RapidAPIService.shared

    // Search across all APIs until we get results
    func search(useCache: Bool = true) async {
        // Validate first
        let (isValid, error) = ValidationUtil.validateSearchQuery(query)
        guard isValid else {
            errorMessage = error
            isLoading = false
            return
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        isLoading = true
        errorMessage = nil
        
        // No cache - always fresh search results!

        // Sequential API calls with early exit
        let apiProviders: [(name: String, fetch: () async throws -> [Article])] = [
            ("GNews", { try await self.gNewsAPIService.searchArticles(query: trimmed, max: 20) }),
            ("RapidAPI", { try await self.rapidAPIService.searchNews(query: trimmed, language: "it", limit: 20) }),
            ("NewsData.io", { try await self.newsDataIOService.searchNews(query: trimmed, language: "it") }),
            ("NewsAPI", { try await self.newsAPIService.searchArticles(query: trimmed, page: 1, pageSize: 20) }),
            ("NewsDataHub", { try await self.newsDataHubAPIService.searchNews(query: trimmed, language: "it", limit: 20) })
        ]

        var allArticles: [Article] = []
        var successCount = 0

        for (name, fetch) in apiProviders {
            do {
                let articles = try await withTimeout(fetch, timeout: Constants.API.apiCallTimeoutPerService)
                allArticles.append(contentsOf: articles)
                successCount += 1

                Logger.debug("✅ \(name): \(articles.count) results", category: .network)

                // Early exit if got enough results
                if articles.count >= 10 { break }

            } catch let error as TimeoutError {
                Logger.debug("⏱️ \(name) timeout, trying next...", category: .network)
            } catch {
                Logger.debug("❌ \(name) failed, trying next...", category: .network)
            }
        }

        // Deduplicate and filter
        let freshArticles = filterFreshArticles(allArticles)
        let uniqueArticles = deduplicateByURL(freshArticles)

        // Sort by actual date (Article.publishedAt is String; use computed publishedDate)
        results = uniqueArticles.sorted {
            ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast)
        }
        isLoading = false

        if results.isEmpty {
            errorMessage = successCount == 0
                ? "Search unavailable. Check connection and try again."
                : "No recent results found."
        }
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

