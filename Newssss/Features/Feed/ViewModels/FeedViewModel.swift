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
        
        // For You uses personalization logic
        if selectedCategory == .forYou {
            await loadPersonalizedFeed(useCache: false)
            return
        }

        // Fetch fresh articles from our APIs
        do {
            Logger.debug("🌐 Fetching articles for \(selectedCategory.displayName)...", category: .viewModel)
            
            let enhancedArticles = try await aggregatorService.fetchAggregatedNews(
                category: selectedCategory,
                useLocationBased: true
            )
            
            let fetchedArticles = enhancedArticles.map { $0.article }.shuffled()
            
            guard !fetchedArticles.isEmpty else {
                errorMessage = "No articles found for \(selectedCategory.displayName)"
                isLoading = false
                return
            }
            
            articles = fetchedArticles
            canLoadMore = fetchedArticles.count >= AppConfig.articlesPerPage

            // Generate AI summaries in background (non-blocking)
            startBackgroundSummarization(for: fetchedArticles)
            
            Logger.debug("✅ Loaded \(articles.count) FRESH articles for \(selectedCategory.displayName)", category: .viewModel)
            
        } catch {
            errorMessage = "Failed to load articles: \(error.localizedDescription)"
            Logger.error("❌ API fetch failed: \(error.localizedDescription)", category: .viewModel)
            articles = []
        }
        
        isLoading = false
    }

    // Load personalized For You feed
    private func loadPersonalizedFeed(useCache: Bool) async {
        do {
            Logger.debug("🎯 Loading personalized 'For You' feed", category: .viewModel)
            
            // Fetch from all categories
            let enhancedArticles = try await aggregatorService.fetchAggregatedNews(
                category: nil, // Get all categories
                useLocationBased: true
            )
            
            let fetchedArticles = enhancedArticles.map { $0.article }
            
            // Personalize using AI
            let personalized = PersonalizationService.shared.personalizeArticles(fetchedArticles)
            
            guard !personalized.isEmpty else {
                errorMessage = "No personalized articles available"
                isLoading = false
                return
            }
            
            articles = personalized
            canLoadMore = false // For You feed doesn't support pagination
            
            Logger.debug("✅ Loaded \(articles.count) personalized articles", category: .viewModel)
            
        } catch {
            errorMessage = "Failed to load personalized feed: \(error.localizedDescription)"
            Logger.error("❌ Personalized feed failed: \(error.localizedDescription)", category: .viewModel)
            articles = []
        }
        
        isLoading = false
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

    // Load more articles
    func loadMoreArticles() async {
        // Guard conditions
        guard selectedCategory != .history else { return }
        guard canLoadMore else { return }
        guard !isLoadingMore else { return }
        guard !isLoading else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        // Fetch from API
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
            
            articles.append(contentsOf: newArticles)
            
            // Trim if too many articles
            if articles.count > maxCachedArticles {
                articles = Array(articles.suffix(maxCachedArticles))
                Logger.debug("⚠️ Trimmed to \(maxCachedArticles) articles", category: .viewModel)
            }
            
            // No caching - always fresh!
            
            canLoadMore = fetchedArticles.count >= AppConfig.articlesPerPage
            Logger.debug("✅ Loaded page \(currentPage) with \(newArticles.count) new articles", category: .viewModel)
            
        } catch {
            Logger.error("Failed to load page \(currentPage): \(error.localizedDescription)", category: .viewModel)
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
        
        ToastManager.shared.show(toast: Toast(
            style: .info,
            message: "Refreshing \(category.displayName)..."
        ))
        
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
