//
//  NewsMemoryStore.swift
//  Newssss
//
//  In-memory storage for fast news access
//  NO DISK CACHE - Memory only, cleared on app close
//

import Foundation
import Combine

@MainActor
class NewsMemoryStore: ObservableObject {
    static let shared = NewsMemoryStore()
    
    // In-memory storage for each category
    @Published private(set) var categoryArticles: [String: [Article]] = [:]
    @Published private(set) var lastFetchTime: Date?
    @Published private(set) var isFetching = false
    
    private init() {}
    
    // MARK: - Get Articles
    
    /// Get articles for a category (instant if available)
    func getArticles(for category: String) -> [Article]? {
        return categoryArticles[category]
    }
    
    /// Check if we have articles for a category
    func hasArticles(for category: String) -> Bool {
        guard let articles = categoryArticles[category] else { return false }
        return !articles.isEmpty
    }
    
    /// Check if store is empty
    func isEmpty() -> Bool {
        return categoryArticles.isEmpty
    }
    
    // MARK: - Store Articles
    
    /// Store articles for a category
    func store(articles: [Article], for category: String) {
        categoryArticles[category] = articles
        lastFetchTime = Date()
        Logger.debug("📦 Stored \(articles.count) articles for \(category)", category: .network)
    }
    
    /// Store all categories at once
    func storeAll(categories: [String: [Article]]) {
        categoryArticles = categories
        lastFetchTime = Date()
        let total = categories.values.reduce(0) { $0 + $1.count }
        Logger.debug("📦 Stored \(total) articles across \(categories.count) categories", category: .network)
    }
    
    // MARK: - Clear
    
    /// WIPE everything - complete refresh
    func clearAll() {
        categoryArticles.removeAll()
        lastFetchTime = nil
        Logger.debug("🗑️ Cleared all articles from memory", category: .network)
    }
    
    /// Clear specific category
    func clear(category: String) {
        categoryArticles.removeValue(forKey: category)
        Logger.debug("🗑️ Cleared \(category) from memory", category: .network)
    }
    
    // MARK: - Fetch Status
    
    func setFetching(_ fetching: Bool) {
        isFetching = fetching
    }
    
    // MARK: - Stats
    
    func getTotalArticleCount() -> Int {
        return categoryArticles.values.reduce(0) { $0 + $1.count }
    }
    
    func getCategoryCount() -> Int {
        return categoryArticles.count
    }
    
    func getTimeSinceLastFetch() -> TimeInterval? {
        guard let lastFetch = lastFetchTime else { return nil }
        return Date().timeIntervalSince(lastFetch)
    }
}
