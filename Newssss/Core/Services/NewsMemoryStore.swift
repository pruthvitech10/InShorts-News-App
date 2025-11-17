//
//  NewsMemoryStore.swift
//  Newssss
//
//  FAST CACHE: Memory + JSON files per category
//  Load INSTANTLY from disk on app launch!
//

import Foundation
import Combine

class NewsMemoryStore: ObservableObject {
    static let shared = NewsMemoryStore()
    
    // In-memory storage for each category - ONLY these need MainActor
    @MainActor @Published private(set) var categoryArticles: [String: [Article]] = [:]
    @MainActor @Published private(set) var lastFetchTime: Date?
    @MainActor @Published private(set) var isFetching = false
    
    // Cache directory for JSON files
    private let cacheDir: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("NewsCache")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    private init() {
        // ⚡ Load from JSON in background - DON'T block init!
        Task {
            await loadAllFromDisk()
        }
    }
    
    // MARK: - Get Articles
    
    /// Get articles for a category (instant if available)
    @MainActor
    func getArticles(for category: String) -> [Article]? {
        return categoryArticles[category]
    }
    
    /// Check if we have articles for a category
    @MainActor
    func hasArticles(for category: String) -> Bool {
        guard let articles = categoryArticles[category] else { return false }
        return !articles.isEmpty
    }
    
    /// Check if store is empty
    @MainActor
    func isEmpty() -> Bool {
        return categoryArticles.isEmpty
    }
    
    // MARK: - Store Articles
    
    /// Store articles for a category
    @MainActor
    func store(articles: [Article], for category: String) {
        categoryArticles[category] = articles
        lastFetchTime = Date()
        Logger.debug("📦 Stored \(articles.count) articles for \(category)", category: .network)
    }
    
    /// Store all categories at once
    @MainActor
    func storeAll(categories: [String: [Article]]) {
        categoryArticles = categories
        lastFetchTime = Date()
        let total = categories.values.reduce(0) { $0 + $1.count }
        Logger.debug("📦 Stored \(total) articles across \(categories.count) categories", category: .network)
        
        // ⚡ Save each category to its own JSON file (OFF MAIN THREAD!)
        Task.detached(priority: .utility) {
            await self.saveToDisk(categories: categories)
        }
    }
    
    // MARK: - Clear
    
    /// WIPE everything - complete refresh (INCLUDING JSON files)
    @MainActor
    func clearAll() {
        categoryArticles.removeAll()
        lastFetchTime = nil
        Logger.debug("🗑️ Cleared all articles from memory", category: .network)
        
        // ⚡ DELETE JSON files on refresh (OFF MAIN THREAD!)
        Task.detached(priority: .utility) {
            await self.deleteAllJSONFiles()
        }
    }
    
    /// Clear specific category
    @MainActor
    func clear(category: String) {
        categoryArticles.removeValue(forKey: category)
        Logger.debug("🗑️ Cleared \(category) from memory", category: .network)
    }
    
    // MARK: - Fetch Status
    
    @MainActor
    func setFetching(_ fetching: Bool) {
        isFetching = fetching
    }
    
    // MARK: - Stats
    
    @MainActor
    func getTotalArticleCount() -> Int {
        return categoryArticles.values.reduce(0) { $0 + $1.count }
    }
    
    @MainActor
    func getCategoryCount() -> Int {
        return categoryArticles.count
    }
    
    @MainActor
    func getTimeSinceLastFetch() -> TimeInterval? {
        guard let lastFetch = lastFetchTime else { return nil }
        return Date().timeIntervalSince(lastFetch)
    }
    
    // MARK: - JSON File Cache (Per Category)
    
    /// ⚡ Save each category to its own JSON file
    private func saveToDisk(categories: [String: [Article]]) async {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        for (category, articles) in categories {
            do {
                let data = try encoder.encode(articles)
                let fileURL = cacheDir.appendingPathComponent("\(category).json")
                try data.write(to: fileURL)
                Logger.debug("💾 Saved \(articles.count) articles to \(category).json", category: .network)
            } catch {
                Logger.error("❌ Failed to save \(category): \(error)", category: .network)
            }
        }
        
        // Save timestamp
        if let timestamp = lastFetchTime {
            do {
                let timestampData = try encoder.encode(timestamp)
                let timestampURL = cacheDir.appendingPathComponent("timestamp.json")
                try timestampData.write(to: timestampURL)
            } catch {
                Logger.error("❌ Failed to save timestamp: \(error)", category: .network)
            }
        }
    }
    
    /// ⚡ DELETE all JSON files (called on refresh)
    private func deleteAllJSONFiles() async {
        let categories = ["general"] + AppConstants.categories
        
        for category in categories {
            let fileURL = cacheDir.appendingPathComponent("\(category).json")
            do {
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                    Logger.debug("🗑️ Deleted \(category).json", category: .network)
                }
            } catch {
                Logger.error("❌ Failed to delete \(category).json: \(error)", category: .network)
            }
        }
        
        // Delete timestamp
        let timestampURL = cacheDir.appendingPathComponent("timestamp.json")
        do {
            if FileManager.default.fileExists(atPath: timestampURL.path) {
                try FileManager.default.removeItem(at: timestampURL)
                Logger.debug("🗑️ Deleted timestamp.json", category: .network)
            }
        } catch {
            Logger.error("❌ Failed to delete timestamp: \(error)", category: .network)
        }
    }
    
    /// ⚡ Load all categories from JSON files on app launch
    private func loadAllFromDisk() async {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let categories = ["general"] + AppConstants.categories
        
        var loadedCategories: [String: [Article]] = [:]
        var totalArticles = 0
        
        for category in categories {
            let fileURL = cacheDir.appendingPathComponent("\(category).json")
            
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                continue
            }
            
            do {
                let data = try Data(contentsOf: fileURL)
                let articles = try decoder.decode([Article].self, from: data)
                loadedCategories[category] = articles
                totalArticles += articles.count
                Logger.debug("⚡ Loaded \(articles.count) articles from \(category).json", category: .network)
            } catch {
                Logger.error("❌ Failed to load \(category): \(error)", category: .network)
            }
        }
        
        // Load timestamp (still off main thread)
        var loadedTimestamp: Date?
        let timestampURL = cacheDir.appendingPathComponent("timestamp.json")
        if FileManager.default.fileExists(atPath: timestampURL.path) {
            do {
                let data = try Data(contentsOf: timestampURL)
                loadedTimestamp = try decoder.decode(Date.self, from: data)
            } catch {
                Logger.error("❌ Failed to load timestamp: \(error)", category: .network)
            }
        }
        
        // Update UI properties on MainActor
        if !loadedCategories.isEmpty {
            await MainActor.run {
                self.categoryArticles = loadedCategories
                self.lastFetchTime = loadedTimestamp
            }
            
            let age = loadedTimestamp.map { Int(Date().timeIntervalSince($0) / 60) } ?? 0
            Logger.debug("⚡⚡⚡ INSTANT LOAD: \(totalArticles) articles from \(loadedCategories.count) categories (\(age)m old)", category: .network)
        } else {
            Logger.debug("📂 No cached articles found (first launch)", category: .network)
        }
    }
}
