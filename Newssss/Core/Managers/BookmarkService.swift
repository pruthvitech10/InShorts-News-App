//
//  BookmarkService.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation
import Combine

// Bookmark error types

enum BookmarkError: LocalizedError {
    case alreadyBookmarked
    case notFound
    case limitReached(maxBookmarks: Int)
    case saveFailed(Error)
    case loadFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .alreadyBookmarked:
            return "This article is already bookmarked"
        case .notFound:
            return "Bookmark not found"
        case .limitReached(let max):
            return "Bookmark limit reached (\(max) bookmarks maximum)"
        case .saveFailed(let error):
            return "Failed to save bookmarks: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load bookmarks: \(error.localizedDescription)"
        }
    }
}

// Manages saved articles

@MainActor
final class BookmarkService: ObservableObject {
    static let shared = BookmarkService()
    
    // Observable state
    
    @Published private(set) var bookmarks: [Article] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: BookmarkError?
    
    // Settings
    
    private struct Config {
        static let bookmarksFilename = "bookmarked_articles.json"
        static let maxBookmarks = 500
        static let autoSaveDelay: TimeInterval = 0.5
    }
    
    // Internal state
    
    private let persistenceManager = PersistenceManager.shared
    private var bookmarkSet: Set<String> = [] // Fast lookup by URL
    private var autoSaveTask: Task<Void, Never>?
    private var needsSave = false
    
    // Performance tracking
    private var lastSaveTime: Date?
    
    // Setup
    
    private init() {
        Task {
            await loadBookmarks()
        }
    }
    
    // Load saved bookmarks
    
    func loadBookmarks() async {
        isLoading = true
        error = nil
        
        do {
            let loaded = try await Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return [] }
                return self.persistenceManager.load(
                    from: Config.bookmarksFilename,
                    as: [Article].self
                ) ?? []
            }.value
            
            // Sort by most recent first
            bookmarks = (loaded as? [Article] ?? []).sorted { ($0.savedDate ?? .distantPast) > ($1.savedDate ?? .distantPast) }
            bookmarkSet = Set(bookmarks.map { $0.url })
            
            Logger.debug("✅ Loaded \(bookmarks.count) bookmarks", category: .persistence)
        } catch {
            self.error = .loadFailed(error)
            Logger.error("❌ Failed to load bookmarks: \(error)", category: .persistence)
        }
        
        isLoading = false
    }
    
    // Get bookmarks
    
    /// Get all bookmarks
    func getBookmarks() -> [Article] {
        bookmarks
    }
    
    /// Get bookmarks sorted by date
    func getBookmarks(sortedBy sort: BookmarkSort) -> [Article] {
        switch sort {
        case .newest:
            return bookmarks.sorted { ($0.savedDate ?? .distantPast) > ($1.savedDate ?? .distantPast) }
        case .oldest:
            return bookmarks.sorted { ($0.savedDate ?? .distantPast) < ($1.savedDate ?? .distantPast) }
        case .title:
            return bookmarks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .source:
            return bookmarks.sorted { $0.source.name.localizedCaseInsensitiveCompare($1.source.name) == .orderedAscending }
        }
    }
    
    /// Get bookmarks count
    var count: Int {
        bookmarks.count
    }
    
    /// Check if at capacity
    var isAtCapacity: Bool {
        bookmarks.count >= Config.maxBookmarks
    }
    
    // Add bookmark
    
    /// Add a bookmark
    /// - Throws: BookmarkError if already bookmarked or limit reached
    func addBookmark(_ article: Article) throws {
        // Validation
        guard !isBookmarked(article) else {
            throw BookmarkError.alreadyBookmarked
        }
        
        guard bookmarks.count < Config.maxBookmarks else {
            throw BookmarkError.limitReached(maxBookmarks: Config.maxBookmarks)
        }
        
        // Add saved date if not present
        var articleToSave = article
        if articleToSave.savedDate == nil {
            articleToSave.savedDate = Date()
        }
        
        // Add to collections
        bookmarks.insert(articleToSave, at: 0) // Add to front
        bookmarkSet.insert(article.url)
        
        // Schedule save
        scheduleSave()
        
        // Haptic feedback
        HapticFeedback.success()
        
        Logger.debug("✅ Added bookmark: \(article.title)", category: .persistence)
    }
    
    // Remove bookmark
    
    /// Remove a bookmark
    /// - Throws: BookmarkError if not found
    func removeBookmark(_ article: Article) throws {
        guard let index = bookmarks.firstIndex(where: { $0.url == article.url }) else {
            throw BookmarkError.notFound
        }
        
        bookmarks.remove(at: index)
        bookmarkSet.remove(article.url)
        
        // Schedule save
        scheduleSave()
        
        // Haptic feedback
        HapticFeedback.light()
        
        Logger.debug("✅ Removed bookmark: \(article.title)", category: .persistence)
    }
    
    /// Remove bookmark by URL
    func removeBookmark(url: String) throws {
        guard let index = bookmarks.firstIndex(where: { $0.url == url }) else {
            throw BookmarkError.notFound
        }
        
        let article = bookmarks[index]
        bookmarks.remove(at: index)
        bookmarkSet.remove(url)
        
        scheduleSave()
        
        Logger.debug("✅ Removed bookmark: \(article.title)", category: .persistence)
    }
    
    // Toggle bookmark on/off
    
    /// Toggle bookmark status
    /// - Returns: True if bookmarked, false if removed
    @discardableResult
    func toggleBookmark(_ article: Article) -> Bool {
        if isBookmarked(article) {
            try? removeBookmark(article)
            return false
        } else {
            do {
                try addBookmark(article)
                return true
            } catch {
                self.error = error as? BookmarkError
                Logger.error("Failed to toggle bookmark: \(error)", category: .persistence)
                return false
            }
        }
    }
    
    // Check if bookmarked
    
    /// Check if article is bookmarked (O(1) lookup)
    func isBookmarked(_ article: Article) -> Bool {
        bookmarkSet.contains(article.url)
    }
    
    /// Check if URL is bookmarked
    func isBookmarked(url: String) -> Bool {
        bookmarkSet.contains(url)
    }
    
    // Clear all bookmarks
    
    /// Clear all bookmarks
    func clearAllBookmarks() {
        let count = bookmarks.count
        bookmarks.removeAll()
        bookmarkSet.removeAll()
        
        saveBookmarksImmediately()
        
        Logger.debug("✅ Cleared \(count) bookmarks", category: .persistence)
    }
    
    /// Remove old bookmarks (older than specified date)
    func removeBookmarks(olderThan date: Date) {
        let initialCount = bookmarks.count
        
        bookmarks.removeAll { article in
            if let savedDate = article.savedDate, savedDate < date {
                bookmarkSet.remove(article.url)
                return true
            }
            return false
        }
        
        let removedCount = initialCount - bookmarks.count
        
        if removedCount > 0 {
            scheduleSave()
            Logger.debug("✅ Removed \(removedCount) old bookmarks", category: .persistence)
        }
    }
    
    // Search bookmarks
    
    /// Search bookmarks
    func searchBookmarks(query: String) -> [Article] {
        guard !query.isEmpty else { return bookmarks }
        
        let lowercaseQuery = query.lowercased()
        
        return bookmarks.filter { article in
            article.title.lowercased().contains(lowercaseQuery) ||
            article.description?.lowercased().contains(lowercaseQuery) == true ||
            article.source.name.lowercased().contains(lowercaseQuery)
        }
    }
    
    /// Filter bookmarks by source
    func getBookmarks(fromSource source: String) -> [Article] {
        bookmarks.filter { $0.source.name.lowercased() == source.lowercased() }
    }
    
    // Save to disk
    
    private func scheduleSave() {
        needsSave = true
        
        // Cancel existing task
        autoSaveTask?.cancel()
        
        // Schedule new save with debouncing
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Config.autoSaveDelay * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            await self?.saveBookmarksImmediately()
        }
    }
    
    private func saveBookmarksImmediately() {
        guard needsSave else { return }
        needsSave = false
        
        let startTime = Date()
        
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            
            do {
                await self.persistenceManager.save(self.bookmarks, to: Config.bookmarksFilename)
                
                await MainActor.run {
                    self.lastSaveTime = Date()
                    let duration = Date().timeIntervalSince(startTime)
                    Logger.debug("✅ Saved \(self.bookmarks.count) bookmarks in \(String(format: "%.2f", duration))s", category: .persistence)
                }
            } catch {
                await MainActor.run {
                    self.error = .saveFailed(error)
                    Logger.error("❌ Failed to save bookmarks: \(error)", category: .persistence)
                }
            }
        }
    }
    
    /// Force immediate save (useful before app termination)
    func saveNow() async {
        needsSave = true
        saveBookmarksImmediately()
        
        // Wait a bit to ensure save completes
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    }
    
    // Get bookmark stats
    
    func getStatistics() -> BookmarkStatistics {
        let sources = Dictionary(grouping: bookmarks, by: { $0.source })
        let mostBookmarkedSource = sources.max(by: { $0.value.count < $1.value.count })
        
        return BookmarkStatistics(
            totalBookmarks: bookmarks.count,
            uniqueSources: sources.count,
            mostBookmarkedSource: mostBookmarkedSource?.key.name,
            oldestBookmark: bookmarks.map { $0.savedDate ?? .distantPast }.min(),
            newestBookmark: bookmarks.map { $0.savedDate ?? .distantPast }.max(),
            capacityUsed: Double(bookmarks.count) / Double(Config.maxBookmarks)
        )
    }
}

// Helper types

enum BookmarkSort {
    case newest
    case oldest
    case title
    case source
}

struct BookmarkStatistics {
    let totalBookmarks: Int
    let uniqueSources: Int
    let mostBookmarkedSource: String?
    let oldestBookmark: Date?
    let newestBookmark: Date?
    let capacityUsed: Double
    
    var capacityPercentage: String {
        String(format: "%.1f%%", capacityUsed * 100)
    }
}

// Article bookmark helpers

extension Article {
    var savedDate: Date? {
        get {
            // Assuming Article has a savedDate property
            // Adjust based on your actual Article model
            return nil
        }
        set {
            // Store savedDate
        }
    }
}
