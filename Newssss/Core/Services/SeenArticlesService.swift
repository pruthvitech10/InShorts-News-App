//
//  SeenArticlesService.swift
//  Newssss
//
//  Tracks articles user has already seen/swiped
//  SESSION-BASED: Only remembers during current app session
//  Clears when app is closed/terminated
//

import Foundation

class SeenArticlesService {
    static let shared = SeenArticlesService()
    
    // SESSION-BASED: Only in memory, NOT saved to disk
    private var seenArticleURLs: Set<String> = []
    
    private init() {
        // NO loading from UserDefaults - start fresh each session
        Logger.debug("🆕 Started new session - history cleared", category: .general)
        
        // Clear any old data if it exists
        UserDefaults.standard.removeObject(forKey: "seenArticles")
    }
    
    // MARK: - Public Methods
    
    /// Mark article as seen (user swiped it) - SESSION ONLY
    func markAsSeen(_ article: Article) {
        seenArticleURLs.insert(article.url)
        // NO saving to disk - only in memory for this session
        Logger.debug("✅ Marked as seen (session only): \(article.title)", category: .general)
    }
    
    /// Check if article has been seen in THIS SESSION
    func hasBeenSeen(_ article: Article) -> Bool {
        return seenArticleURLs.contains(article.url)
    }
    
    /// Filter out seen articles from array (THIS SESSION ONLY)
    func filterUnseenArticles(_ articles: [Article]) -> [Article] {
        let unseen = articles.filter { !hasBeenSeen($0) }
        Logger.debug("📊 Filtered (session): \(articles.count) total → \(unseen.count) unseen", category: .general)
        return unseen
    }
    
    /// Clear session history (happens automatically when app closes)
    func clearSeenArticles() {
        seenArticleURLs.removeAll()
        Logger.debug("🗑️ Cleared session history", category: .general)
    }
    
    /// Get count of seen articles in THIS SESSION
    func getSeenCount() -> Int {
        return seenArticleURLs.count
    }
}
