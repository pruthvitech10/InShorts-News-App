//
//  PersonalizationService.swift
//  Newssss
//
//  AI-powered personalization engine for "For You" feed
//

import Foundation
import Combine

// MARK: - User Preferences

struct UserPreferences: Codable {
    var categoryScores: [String: Double] = [:]
    var sourceScores: [String: Double] = [:]
    var readArticles: Set<String> = []
    var bookmarkedArticles: Set<String> = []
    var skippedArticles: Set<String> = []
    var lastUpdated: Date = Date()
    
    // Reading time tracking
    var totalReadingTime: TimeInterval = 0
    var articlesRead: Int = 0
    
    // Category preferences (0-1 scale)
    var preferredCategories: [NewsCategory] {
        let sorted = categoryScores.sorted { $0.value > $1.value }
        return sorted.prefix(3).compactMap { NewsCategory(rawValue: $0.key) }
    }
}

// MARK: - Personalization Service

@MainActor
final class PersonalizationService: ObservableObject {
    static let shared = PersonalizationService()
    
    @Published private(set) var preferences = UserPreferences()
    
    private let persistenceKey = "user_preferences"
    private let persistenceManager = PersistenceManager.shared
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Tracking Methods
    
    /// Track when user reads an article
    func trackArticleRead(_ article: Article, readingTime: TimeInterval) {
        preferences.readArticles.insert(article.url)
        preferences.totalReadingTime += readingTime
        preferences.articlesRead += 1
        
        // Increase category score (infer from source)
        let category = inferCategory(from: article)
        preferences.categoryScores[category, default: 0] += 1.0
        
        // Increase source score
        preferences.sourceScores[article.source.name, default: 0] += 0.5
        
        savePreferences()
        
        Logger.debug("📊 Tracked read: \(category), time: \(Int(readingTime))s", category: .general)
    }
    
    /// Track when user bookmarks an article (strong positive signal)
    func trackBookmark(_ article: Article) {
        preferences.bookmarkedArticles.insert(article.url)
        
        // Strong positive signal for category
        let category = inferCategory(from: article)
        preferences.categoryScores[category, default: 0] += 3.0
        
        // Strong positive signal for source
        preferences.sourceScores[article.source.name, default: 0] += 2.0
        
        savePreferences()
        
        Logger.debug("⭐ Tracked bookmark: \(category)", category: .general)
    }
    
    /// Track when user skips an article (negative signal)
    func trackSkip(_ article: Article) {
        preferences.skippedArticles.insert(article.url)
        
        // Slight negative signal
        let category = inferCategory(from: article)
        preferences.categoryScores[category, default: 0] -= 0.2
        
        savePreferences()
    }
    
    /// Track when user shares an article (very strong positive signal)
    func trackShare(_ article: Article) {
        let category = inferCategory(from: article)
        preferences.categoryScores[category, default: 0] += 5.0
        preferences.sourceScores[article.source.name, default: 0] += 3.0
        
        savePreferences()
        
        Logger.debug("🚀 Tracked share: \(category)", category: .general)
    }
    
    /// Infer category from article content
    private func inferCategory(from article: Article) -> String {
        let text = "\(article.title) \(article.description ?? "")".lowercased()
        
        if text.contains("tech") || text.contains("apple") || text.contains("google") || text.contains("ai") {
            return "technology"
        } else if text.contains("sport") || text.contains("football") || text.contains("cricket") {
            return "sports"
        } else if text.contains("business") || text.contains("market") || text.contains("stock") {
            return "business"
        } else if text.contains("health") || text.contains("medical") {
            return "health"
        } else if text.contains("science") {
            return "science"
        } else if text.contains("entertainment") || text.contains("movie") || text.contains("music") {
            return "entertainment"
        } else if text.contains("politics") || text.contains("election") {
            return "politics"
        }
        return "general"
    }
    
    // MARK: - Personalization Algorithm
    
    /// Personalize articles for "For You" feed
    func personalizeArticles(_ articles: [Article]) -> [Article] {
        guard !articles.isEmpty else { return [] }
        
        // If no preferences yet, return shuffled articles
        if preferences.categoryScores.isEmpty {
            Logger.debug("📰 No preferences yet, showing diverse content", category: .general)
            return articles.shuffled()
        }
        
        // Score each article based on user preferences
        let scoredArticles = articles.map { article -> (Article, Double) in
            let score = calculateArticleScore(article)
            return (article, score)
        }
        
        // Sort by score (highest first)
        let sorted = scoredArticles.sorted { $0.1 > $1.1 }
        
        // Add some randomness to avoid filter bubble (80% personalized, 20% diverse)
        let personalizedCount = Int(Double(sorted.count) * 0.8)
        let personalized = Array(sorted.prefix(personalizedCount))
        let diverse = Array(sorted.suffix(sorted.count - personalizedCount).shuffled())
        
        let result = (personalized + diverse).map { $0.0 }
        
        Logger.debug("🎯 Personalized \(result.count) articles", category: .general)
        
        return result
    }
    
    /// Calculate relevance score for an article
    private func calculateArticleScore(_ article: Article) -> Double {
        var score = 0.0
        
        // Category preference (weight: 40%)
        let category = inferCategory(from: article)
        let categoryScore = preferences.categoryScores[category, default: 0]
        score += categoryScore * 0.4
        
        // Source preference (weight: 20%)
        let sourceScore = preferences.sourceScores[article.source.name, default: 0]
        score += sourceScore * 0.2
        
        // Freshness (weight: 20%)
        if let publishedDate = article.publishedDate {
            let age = Date().timeIntervalSince(publishedDate)
            let freshnessScore = max(0, 1.0 - (age / (7 * 24 * 3600))) // Decay over 7 days
            score += freshnessScore * 0.2
        }
        
        // Novelty bonus (weight: 20%) - prefer unread articles
        if !preferences.readArticles.contains(article.url) {
            score += 0.2
        }
        
        // Penalty for skipped articles
        if preferences.skippedArticles.contains(article.url) {
            score -= 0.5
        }
        
        return max(0, score)
    }
    
    // MARK: - Insights
    
    /// Get user's top interests
    func getTopInterests() -> [String] {
        let sorted = preferences.categoryScores.sorted { $0.value > $1.value }
        return Array(sorted.prefix(5).map { $0.key.capitalized })
    }
    
    /// Get reading statistics
    func getReadingStats() -> (articlesRead: Int, totalTime: TimeInterval, avgTime: TimeInterval) {
        let avgTime = preferences.articlesRead > 0 
            ? preferences.totalReadingTime / Double(preferences.articlesRead) 
            : 0
        return (preferences.articlesRead, preferences.totalReadingTime, avgTime)
    }
    
    // MARK: - Persistence
    
    private func loadPreferences() {
        if let loaded: UserPreferences = persistenceManager.load(forKey: persistenceKey, as: UserPreferences.self) {
            preferences = loaded
            Logger.debug("✅ Loaded user preferences", category: .general)
        }
    }
    
    private func savePreferences() {
        preferences.lastUpdated = Date()
        persistenceManager.save(preferences, forKey: persistenceKey)
    }
    
    /// Reset all preferences (for testing or user request)
    func resetPreferences() {
        preferences = UserPreferences()
        savePreferences()
        Logger.debug("🔄 Reset user preferences", category: .general)
    }
}
