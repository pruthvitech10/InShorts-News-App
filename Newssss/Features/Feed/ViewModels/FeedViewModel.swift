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

    // Core properties
    var selectedCategory: NewsCategory
    var currentPage: Int = 1
    let aggregatorService: NewsAggregatorServiceProtocol
    let maxCachedArticles: Int = 100
    let seenArticlesService = SeenArticlesService.shared

    // Background tasks - need to track these to cancel when switching categories
    private var currentSummarizationTask: Task<Void, Never>?
    private var currentFetchTask: Task<Void, Never>?
    private var loadingTask: Task<Void, Never>?

    // Setup
    init(selectedCategory: NewsCategory,
         aggregatorService: NewsAggregatorServiceProtocol) {
        self.selectedCategory = selectedCategory
        self.aggregatorService = aggregatorService
    }
    
    convenience init(selectedCategory: NewsCategory) {
        self.init(
            selectedCategory: selectedCategory,
            aggregatorService: NewsAggregatorService.shared
        )
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

        // History is stored locally, no need to fetch
        if selectedCategory == .history {
            articles = SwipeHistoryService.shared.getSwipedArticles()
            canLoadMore = false
            isLoading = false
            return
        }
        
        // HYBRID APPROACH: Check memory store first
        let categoryKey = selectedCategory.rawValue
        
        if let cachedArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
            // ⚡ INSTANT: Articles already in memory
            Logger.debug("⚡ INSTANT: Loaded \(cachedArticles.count) articles from memory for \(selectedCategory.displayName)", category: .viewModel)
            articles = cachedArticles
            canLoadMore = true
            isLoading = false
            
            // Smart refresh: If data is >30 minutes old, fetch fresh in background
            if let timeSince = await NewsMemoryStore.shared.getTimeSinceLastFetch() {
                let minutesOld = Int(timeSince / 60)
                
                if timeSince > 1800 {  // >30 minutes
                    Logger.debug("🔄 Data is \(minutesOld) minutes old, fetching fresh in background...", category: .viewModel)
                    Task {
                        await fetchFreshArticles(for: categoryKey, silent: true)
                    }
                } else {
                    Logger.debug("✅ Data is \(minutesOld) minutes old, still fresh!", category: .viewModel)
                }
            }
            return
        }
        
        // No memory cache - fetch from internet
        Logger.debug("📡 No memory cache, fetching from internet...", category: .viewModel)
        await fetchFreshArticles(for: categoryKey)
    }
    
    // Fetch fresh articles from internet
    private func fetchFreshArticles(for categoryKey: String, silent: Bool = false) async {
        // Check internet connection
        guard NetworkMonitor.shared.isConnected else {
            if !silent {
                errorMessage = "No internet connection"
                Logger.error("❌ No internet - stopping", category: .viewModel)
                isLoading = false
                articles = []
            }
            return
        }
        
        do {
            Logger.debug("🌐 Fetching fresh articles for \(selectedCategory.displayName) (silent: \(silent))...", category: .viewModel)
            
            // Fetch from Italian news service
            let italianNewsService = ItalianNewsService.shared
            let fetchedArticles = try await italianNewsService.fetchItalianNews(category: categoryKey, limit: Int.max)
            
            Logger.debug("✅ Fetched \(fetchedArticles.count) fresh articles", category: .viewModel)
            
            // Store in memory for next time
            await NewsMemoryStore.shared.store(articles: fetchedArticles, for: categoryKey)
            
            // Update UI ONLY if not silent
            if !silent {
                articles = fetchedArticles
                canLoadMore = true
                isLoading = false
            } else {
                // Silent update: Only update if user is still on this category
                if selectedCategory.rawValue == categoryKey {
                    Logger.debug("🔄 Silent update: Refreshing articles in background", category: .viewModel)
                    articles = fetchedArticles
                    canLoadMore = true
                }
            }
            
            Logger.debug("✅ Loaded \(articles.count) articles for \(selectedCategory.displayName)", category: .viewModel)
            
        } catch {
            if !silent {
                errorMessage = "Failed to load articles: \(error.localizedDescription)"
                Logger.error("❌ Fetch failed: \(error.localizedDescription)", category: .viewModel)
                articles = []
                isLoading = false
            } else {
                Logger.debug("⚠️ Silent fetch failed (ignored): \(error.localizedDescription)", category: .viewModel)
            }
        }
    }

    // Generate AI summaries in background
    private func startBackgroundSummarization(for fetchedArticles: [Article]) {
        currentSummarizationTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                Logger.debug("🤖 Starting AI summarization for \(fetchedArticles.count) articles", category: .viewModel)
                
                var summarizedArticles = fetchedArticles
                
                for (index, article) in fetchedArticles.enumerated() {
                    // Check if task was cancelled
                    guard !Task.isCancelled else {
                        Logger.debug("⚠️ Summarization cancelled", category: .viewModel)
                        return
                    }
                    
                    // Skip if already has summary
                    guard article.aiSummary == nil else { continue }
                    
                    // Get text to summarize
                    let text = article.content ?? article.description ?? article.title
                    
                    // Generate summary
                    do {
                        let summary = try await ArticleSummarizationService.shared.summarize(text)
                        summarizedArticles[index] = article.withSummary(summary)
                        
                        // Update UI on main actor
                        await MainActor.run { [weak self] in
                            guard let self = self else { return }
                            self.articles = summarizedArticles
                        }
                    } catch {
                        Logger.error("Failed to summarize article '\(article.title.prefix(30))...': \(error.localizedDescription)", category: .viewModel)
                        // Continue with next article
                    }
                }
                
                Logger.debug("✅ AI summarization completed", category: .viewModel)
            }
        }
    }

    // Load more articles - SILENTLY (no loading indicator)
    func loadMoreArticles() async {
        // Guard conditions
        guard selectedCategory != .history else { return }
        guard !isLoadingMore else { return }
        guard !isLoading else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        // Fetch from API - SILENTLY
        do {
            let enhancedArticles = try await aggregatorService.fetchAggregatedNews(
                category: selectedCategory,
                useLocationBased: true
            )
            
            let fetchedArticles = enhancedArticles.map { $0.article }
            
            // Filter out duplicates
            let newArticles = fetchedArticles.filter { newArticle in
                !articles.contains(where: { $0.id == newArticle.id })
            }
            
            // Just append new articles - NO LIMIT
            articles.append(contentsOf: newArticles)
            
            Logger.debug("✅ Loaded \(newArticles.count) new articles silently", category: .viewModel)
            
        } catch {
            Logger.error("Failed to load more: \(error.localizedDescription)", category: .viewModel)
            currentPage -= 1 // Rollback page increment
        }
        
        isLoadingMore = false
    }

    // Refresh feed
    func refreshArticles() async {
        // No cache to clear - just reload
        await loadArticles(useCache: false)
    }

    func refreshCategory(category: NewsCategory) async {
        Logger.debug("🔄 Refreshing category: \(category.displayName)", category: .viewModel)
        
        // Silent refresh - no toast notification
        if category == selectedCategory {
            await loadArticles(useCache: false)
        }
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
        
        // Keep old articles visible while loading new ones
        // This makes the transition feel smoother
        
        Task {
            await loadArticles(useCache: false)
        }
    }

    // Cleanup
    deinit {
        // Tasks are automatically cancelled when the view model is deallocated
    }
}
