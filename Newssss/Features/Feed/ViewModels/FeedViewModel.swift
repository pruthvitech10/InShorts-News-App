//
//  FeedViewModel.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//  Thoroughly reviewed and fixed on 15 November 2025.
//

import Foundation
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    // Published properties for SwiftUI binding
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var canLoadMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoadingMore: Bool = false
    @Published var lastFetchTime: Date? = nil  // Show when data was last fetched

    // Core properties
    var selectedCategory: NewsCategory
    var currentPage: Int = 1
    // NO LIMIT - display all articles from backend
    let seenArticlesService = SeenArticlesService.shared

    // Background tasks - need to track these to cancel when switching categories
    private var currentSummarizationTask: Task<Void, Never>?
    private var currentFetchTask: Task<Void, Never>?
    private var loadingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Setup
    init(selectedCategory: NewsCategory) {
        self.selectedCategory = selectedCategory
        
        // ⚡ Listen for background refresh completion
        NotificationCenter.default.publisher(for: .newsRefreshed)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.loadArticlesFromCache()
                }
            }
            .store(in: &cancellables)
    }
    
    /// ⚡ Load articles from cache when background fetch completes
    private func loadArticlesFromCache() {
        let categoryKey = selectedCategory.rawValue
        
        Task {
            if let cachedArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                let unseenArticles = seenArticlesService.filterUnseenArticles(cachedArticles)
                articles = unseenArticles
                canLoadMore = true
                Logger.debug("⚡ UI updated: \(unseenArticles.count) articles from cache", category: .viewModel)
            }
        }
    }

    // Cancel any running tasks to avoid conflicts
    func cancelAllTasks() {
        loadingTask?.cancel()
        currentFetchTask?.cancel()
        currentSummarizationTask?.cancel()
        loadingTask = nil
        currentFetchTask = nil
        currentSummarizationTask = nil
    }

    // Main function to load articles for the selected category
    func loadArticles(useCache: Bool = true) async {
        // Stop any previous loading first
        cancelAllTasks()
        
        isLoading = true
        errorMessage = nil

        // Recently seen is stored locally, no need to fetch
        if selectedCategory == .recentlySeen {
            articles = SwipeHistoryService.shared.getSwipedArticles()
            canLoadMore = false
            isLoading = false
            return
        }
        
        let categoryKey = selectedCategory.rawValue
        
        // If user manually refreshed (useCache = false), force refresh
        if !useCache {
            Logger.debug("⚡ Manual refresh - using FORCE MODE", category: .viewModel)
            BackgroundRefreshService.shared.forceRefresh()
            isLoading = false  // Don't show loading spinner while background fetching
            return
        }
        
        // HYBRID APPROACH: Check memory store first
        if let cachedArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
            // ⚡ INSTANT: Articles already in memory
            // Filter out articles user already swiped
            let unseenCached = seenArticlesService.filterUnseenArticles(cachedArticles)
            
            // CRITICAL: If all filtered out, show all cached to avoid blank screen
            if unseenCached.isEmpty && !cachedArticles.isEmpty {
                Logger.debug("⚠️ All \(cachedArticles.count) articles marked as seen - showing all to avoid blank screen", category: .viewModel)
                articles = cachedArticles
            } else {
                Logger.debug("⚡ INSTANT: Loaded \(cachedArticles.count) cached → \(unseenCached.count) unseen for \(selectedCategory.displayName)", category: .viewModel)
                articles = unseenCached
            }
            
            canLoadMore = true
            isLoading = false
            lastFetchTime = await NewsMemoryStore.shared.lastFetchTime  // Show when cache was created
            
            // Smart refresh: If data is >30 minutes old, fetch fresh in background
            if let timeSince = await NewsMemoryStore.shared.getTimeSinceLastFetch() {
                let minutesOld = Int(timeSince / 60)
                
                if timeSince > 1800 {  // >30 minutes
                    Logger.debug("🔄 Data is \(minutesOld) minutes old, will auto-refresh soon...", category: .viewModel)
                } else {
                    Logger.debug("✅ Data is \(minutesOld) minutes old, still fresh!", category: .viewModel)
                }
            }
            return
        }
        
        // No memory cache - wait for auto-refresh
        Logger.debug("📡 No memory cache, waiting for auto-refresh...", category: .viewModel)
        
        isLoading = false
    }
    
    // REMOVED - Use BackgroundRefreshService instead!


    // Load more articles - DISABLED (already loading unlimited articles with CategoryEnforcer)
    func loadMoreArticles() async {
        // NO-OP: We already load ALL articles from all sources
        // This prevents bypassing CategoryEnforcer when scrolling
        Logger.debug("⚠️ loadMoreArticles called but disabled - already loading unlimited articles", category: .viewModel)
        return
    }

    // Refresh feed
    func refreshArticles() async {
        // No cache to clear - just reload
        await loadArticles(useCache: false)
    }

    func refreshCategory(category: NewsCategory) async {
        Logger.debug("🔄 MANUAL REFRESH - Clearing JSON files and fetching fresh", category: .viewModel)
        
        guard category == selectedCategory else {
            return
        }
        
        // ⚡ FORCE refresh - This will DELETE JSON files and fetch fresh!
        BackgroundRefreshService.shared.forceRefresh()
        
        Logger.debug("✅ Force refresh triggered", category: .viewModel)
    }

    // Switch categories
    func changeCategory(_ category: NewsCategory) {
        Logger.debug("🔄 Changing category to: \(category.displayName)", category: .viewModel)
        
        // Don't do anything if user taps the same category
        guard category != selectedCategory else {
            Logger.debug("⚠️ Category unchanged: \(category.displayName)", category: .viewModel)
            return
        }
        
        // Stop any ongoing requests to avoid conflicts
        cancelAllTasks()
        
        selectedCategory = category
        currentPage = 1
        
        // ⚡ INSTANT switch - load from cache immediately!
        Task {
            await loadArticles(useCache: true)
        }
    }

    // Cleanup
    deinit {
        // Tasks are automatically cancelled when the view model is deallocated
    }
}
