//
//  SeenArticlesService.swift
//  Newssss
//
//  Tracks articles user has already seen/swiped
//  PERMANENT: Saves to disk so articles stay marked forever
//

import Foundation

class SeenArticlesService {
    static let shared = SeenArticlesService()
    
    // PERMANENT: Saved to disk
    private var seenArticleURLs: Set<String> = []
    private let seenArticlesKey = "seenArticles_permanent"
    
    private init() {
        // Load from disk - articles stay marked forever
        loadSeenArticles()
        Logger.debug("🆕 Loaded \(seenArticleURLs.count) permanently seen articles", category: .general)
    }
    
    // MARK: - Public Methods
    
    /// Mark article as seen (user swiped it) - PERMANENT
    func markAsSeen(_ article: Article) {
        seenArticleURLs.insert(article.url)
        saveSeenArticles()
        Logger.debug("✅ Marked as seen (forever): \(article.title)", category: .general)
    }
    
    /// Check if article has been seen EVER
    func hasBeenSeen(_ article: Article) -> Bool {
        return seenArticleURLs.contains(article.url)
    }
    
    /// Filter out seen articles from array (PERMANENT)
    func filterUnseenArticles(_ articles: [Article]) -> [Article] {
        let unseen = articles.filter { !hasBeenSeen($0) }
        Logger.debug("📊 Filtered (permanent): \(articles.count) total → \(unseen.count) unseen", category: .general)
        return unseen
    }
    
    /// Clear ALL history (user action only)
    func clearSeenArticles() {
        seenArticleURLs.removeAll()
        saveSeenArticles()
        Logger.debug("🗑️ Cleared ALL seen articles", category: .general)
    }
    
    /// Get count of seen articles EVER
    func getSeenCount() -> Int {
        return seenArticleURLs.count
    }
    
    // MARK: - Persistence
    
    private func saveSeenArticles() {
        let urls = Array(seenArticleURLs)
        UserDefaults.standard.set(urls, forKey: seenArticlesKey)
    }
    
    private func loadSeenArticles() {
        if let urls = UserDefaults.standard.array(forKey: seenArticlesKey) as? [String] {
            seenArticleURLs = Set(urls)
        }
    }
}
