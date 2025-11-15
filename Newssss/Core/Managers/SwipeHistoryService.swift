//
//  SwipeHistoryService.swift
//  Newssss
//
//  Created on [Date].
//

import Foundation
import Combine


@MainActor
class SwipeHistoryService: ObservableObject {
    static let shared = SwipeHistoryService()
    
    @Published private(set) var swipedArticles: [Article] = []
    
    private let maxHistorySize = 100
    private let historyKey = "swipe_history"
    
    private init() {
        loadHistory()
    }
    
    // Public methods
    
    // Add a swiped article to history (most recent first)
    func addSwipedArticle(_ article: Article) {
        // Remove if already exists to avoid duplicates
        swipedArticles.removeAll { $0.url == article.url }
        
        // Add at the beginning (most recent first)
        swipedArticles.insert(article, at: 0)
        
        // Keep only the most recent items
        if swipedArticles.count > maxHistorySize {
            swipedArticles = Array(swipedArticles.prefix(maxHistorySize))
        }
        
        saveHistory()
    }
    
    /// Get all swiped articles in reverse chronological order
    func getSwipedArticles() -> [Article] {
        return swipedArticles
    }
    
    /// Clear all history
    func clearHistory() {
        swipedArticles = []
        saveHistory()
    }
    
    // Save/load from disk
    
    private func loadHistory() {
        swipedArticles = PersistenceManager.shared.loadSwipeHistory()
    }
    
    private func saveHistory() {
        PersistenceManager.shared.saveSwipeHistory(swipedArticles)
    }
}
