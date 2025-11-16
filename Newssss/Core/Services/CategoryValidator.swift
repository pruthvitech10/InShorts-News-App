//
//  CategoryValidator.swift
//  Newssss
//
//  Validates that articles are in correct categories
//  Helps debug cross-category issues
//

import Foundation

class CategoryValidator {
    static let shared = CategoryValidator()
    
    private init() {}
    
    /// Check if an article appears in multiple categories
    func findDuplicateArticles() async -> [String: [String]] {
        var articleURLs: [String: [String]] = [:] // URL -> [categories]
        
        let categories = ["general", "politics", "business", "technology", "entertainment", "sports", "world", "crime", "automotive", "lifestyle"]
        
        for category in categories {
            if let articles = await NewsMemoryStore.shared.getArticles(for: category) {
                for article in articles {
                    if articleURLs[article.url] == nil {
                        articleURLs[article.url] = []
                    }
                    articleURLs[article.url]?.append(category)
                }
            }
        }
        
        // Filter to only duplicates (appears in 2+ categories)
        let duplicates = articleURLs.filter { $0.value.count > 1 }
        
        if !duplicates.isEmpty {
            Logger.debug("🔍 Found \(duplicates.count) articles appearing in multiple categories", category: .network)
            for (url, cats) in duplicates.prefix(5) {
                Logger.debug("   📰 Article in: \(cats.joined(separator: ", "))", category: .network)
            }
        }
        
        return duplicates
    }
    
    /// Validate category integrity
    func validateCategories() async {
        Logger.debug("🔍 Validating category integrity...", category: .network)
        
        let categories = ["general", "politics", "business", "technology", "entertainment", "sports", "world", "crime", "automotive", "lifestyle"]
        
        for category in categories {
            if let articles = await NewsMemoryStore.shared.getArticles(for: category) {
                Logger.debug("✅ \(category): \(articles.count) articles", category: .network)
            } else {
                Logger.debug("⚠️ \(category): NO ARTICLES", category: .network)
            }
        }
        
        // Check for duplicates
        let duplicates = await findDuplicateArticles()
        
        if duplicates.isEmpty {
            Logger.debug("✅ No duplicate articles across categories", category: .network)
        } else {
            Logger.debug("⚠️ \(duplicates.count) articles appear in multiple categories (this is normal for cross-category news)", category: .network)
        }
    }
}
