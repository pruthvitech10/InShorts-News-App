//
//  NewsCache.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation


// MARK: - NewsCache


actor NewsCache {
    static let shared = NewsCache()

    // Centralized cache constants
    struct Constants {
        static let maxCacheSize = 100 // Increased for better performance
        static let cacheExpirationTime: TimeInterval = 6 * 60 * 60 // 6 hours - faster refresh
        static let maxArticleAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }

    private var cache: [String: CachedArticles] = [:]
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private init() {}
    
    // MARK: - Cache Key Generation
    /// Generates a cache key for a given news category and page.
    /// - Parameters:
    ///   - category: The news category.
    ///   - page: The page number.
    /// - Returns: A unique cache key string.
    static func cacheKey(for category: NewsCategory, page: Int) -> String {
        return "news_\(category.rawValue)_p\(page)_us"
    }
    
    /// Generates a cache key for a search query and page.
    /// - Parameters:
    ///   - query: The search query string.
    ///   - page: The page number.
    /// - Returns: A unique cache key string for the search.
    static func cacheKey(for query: String, page: Int) -> String {
        let sanitized = query.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return "search_\(sanitized)_p\(page)"
    }
    
    // MARK: - Set Cache
    /// Stores articles in the cache for the specified key.
    /// - Parameters:
    ///   - articles: The array of articles to cache.
    ///   - key: The cache key.
    func set(articles: [Article], forKey key: String) {
        // Implement LRU cache eviction if needed
        if cache.count >= Constants.maxCacheSize {
            evictOldestEntry()
        }

        cache[key] = CachedArticles(articles: articles, timestamp: Date())
        #if DEBUG
        print("📦 Cached \(articles.count) articles for: \(key)")
        #endif
    }
    
    // MARK: - Get Cache
    /// Retrieves fresh articles from the cache for the specified key.
    /// - Parameter key: The cache key.
    /// - Returns: An array of fresh articles if available, otherwise nil.
    func get(forKey key: String) -> [Article]? {
        guard let cachedArticles = cache[key] else {
            return nil
        }
        
        // Check cache expiration
        let elapsed = Date().timeIntervalSince(cachedArticles.timestamp)
        guard elapsed <= Constants.cacheExpirationTime else {
            cache.removeValue(forKey: key)
            #if DEBUG
            print("⏰ Cache expired: \(key)")
            #endif
            return nil
        }

        // FILTER OUT OLD ARTICLES (optimized with precomputed formatter)
        let now = Date()
        let cutoffDate = now.addingTimeInterval(-Constants.maxArticleAge)
        
        let freshArticles = cachedArticles.articles.filter { article in
            guard let publishedDate = article.publishedDate else {
                return false
            }
            return publishedDate >= cutoffDate
        }
        
        // If all cached articles are too old, treat as expired
        if freshArticles.isEmpty && !cachedArticles.articles.isEmpty {
            cache.removeValue(forKey: key)
            #if DEBUG
            print("⚠️ Cache contains only stale articles (>24h old): \(key)")
            #endif
            return nil
        }
        
        #if DEBUG
        print("✅ Cache hit: \(key) - \(freshArticles.count) fresh articles")
        #endif
        return freshArticles
    }
    
    // MARK: - Clear Cache
    /// Removes cached articles for the specified key.
    /// - Parameter key: The cache key to clear.
    func clear(forKey key: String) {
        cache.removeValue(forKey: key)
    }

    /// Removes all cached articles for a specific category.
    /// - Parameter category: The news category to clear from cache.
    func clear(forCategory category: NewsCategory) {
        let prefix = "news_\(category.rawValue)_"
        let keysToRemove = cache.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        #if DEBUG
        print("🗑️ Cleared cache for category: \(category.rawValue)")
        #endif
    }
    
    /// Removes all cached articles from the cache.
    func clearAll() {
        cache.removeAll()
        #if DEBUG
        print("🗑️ Cache cleared")
        #endif
    }
    
    /// Removes all expired cache entries based on the cache expiration time.
    func clearExpired() {
        let now = Date()
        cache = cache.filter { _, value in
            now.timeIntervalSince(value.timestamp) <= Constants.cacheExpirationTime
        }
    }
    
    // MARK: - Cache Info
    /// Returns the current number of cache entries.
    /// - Returns: The number of cached entries.
    func cacheSize() -> Int {
        return cache.count
    }
    
    /// Checks if a cache entry exists for the specified key.
    /// - Parameter key: The cache key to check.
    /// - Returns: True if the key is cached, false otherwise.
    func isCached(forKey key: String) -> Bool {
        return cache[key] != nil
    }
    
    // MARK: - Private Methods
    private func evictOldestEntry() {
        guard let oldestKey = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key else {
            return
        }
        cache.removeValue(forKey: oldestKey)
        #if DEBUG
        print("🗑️ Evicted oldest cache: \(oldestKey)")
        #endif
    }
}

extension NewsCache: NewsCacheProtocol {}

// MARK: - CachedArticles

private struct CachedArticles {
    let articles: [Article]
    let timestamp: Date
}
