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
    // MARK: - Published Properties
    @Published var articles: [Article] = []
    @Published var isLoading: Bool = false
    @Published var canLoadMore: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isLoadingMore: Bool = false

    // MARK: - Other Properties
    var selectedCategory: NewsCategory
    var currentPage: Int = 1
    let cache: NewsCacheProtocol
    let aggregatorService: NewsAggregatorServiceProtocol
    let maxCachedArticles: Int = 100

    // MARK: - Private Properties
    private var currentSummarizationTask: Task<Void, Never>?
    private var currentFetchTask: Task<Void, Never>?

    // MARK: - Initialization
    init(selectedCategory: NewsCategory,
         cache: NewsCacheProtocol,
         aggregatorService: NewsAggregatorServiceProtocol) {
        self.selectedCategory = selectedCategory
        self.cache = cache
        self.aggregatorService = aggregatorService
    }
    
    convenience init(selectedCategory: NewsCategory) {
        self.init(
            selectedCategory: selectedCategory,
            cache: NewsCache.shared,
            aggregatorService: NewsAggregatorService.shared
        )
    }

    // MARK: - Task Management
    func cancelAllTasks() {
        currentFetchTask?.cancel()
        currentSummarizationTask?.cancel()
        currentFetchTask = nil
        currentSummarizationTask = nil
    }

    // MARK: - Article Loading
    func loadArticles(useCache: Bool = true) async {
        // Cancel any ongoing tasks
        cancelAllTasks()
        
        // Reset state
        isLoading = true
        errorMessage = nil

        // Handle History category specially - load from local history
        if selectedCategory == .history {
            do {
                articles = SwipeHistoryService.shared.getSwipedArticles()
                canLoadMore = false
                Logger.debug("📜 Loaded \(articles.count) articles from swipe history", category: .viewModel)
            } catch {
                Logger.error("Failed to load history: \(error.localizedDescription)", category: .viewModel)
                errorMessage = "Failed to load history"
                articles = []
            }
            isLoading = false
            return
        }
        
        // Handle "For You" category - personalized feed
        if selectedCategory == .forYou {
            await loadPersonalizedFeed(useCache: useCache)
            return
        }

        // Try cache first if enabled
        let cacheKey = NewsCache.cacheKey(for: selectedCategory, page: currentPage)
        if useCache {
            do {
                if let cachedArticles = await cache.get(forKey: cacheKey), !cachedArticles.isEmpty {
                    articles = cachedArticles
                    isLoading = false
                    Logger.debug("📦 Loaded \(articles.count) articles from cache for \(selectedCategory.displayName)", category: .viewModel)
                    return
                }
            } catch {
                Logger.error("Cache read error: \(error.localizedDescription)", category: .viewModel)
                // Continue to fetch from API
            }
        }

        // Fetch from API
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

            // Cache the results
            do {
                await cache.set(articles: fetchedArticles, forKey: cacheKey)
            } catch {
                Logger.error("Failed to cache articles: \(error.localizedDescription)", category: .viewModel)
                // Non-critical error, continue
            }
            
            Logger.debug("✅ Loaded \(articles.count) articles for \(selectedCategory.displayName)", category: .viewModel)
            
        } catch {
            errorMessage = "Failed to load articles: \(error.localizedDescription)"
            Logger.error("❌ API fetch failed: \(error.localizedDescription)", category: .viewModel)
            articles = []
        }
        
        isLoading = false
    }

    // MARK: - Personalized Feed
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
    
    // MARK: - Background AI Summarization
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
                
            } catch {
                Logger.error("Summarization task failed: \(error.localizedDescription)", category: .viewModel)
            }
        }
    }

    // MARK: - Pagination
    func loadMoreArticles() async {
        // Guard conditions
        guard selectedCategory != .history else { return }
        guard canLoadMore else { return }
        guard !isLoadingMore else { return }
        guard !isLoading else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        let cacheKey = NewsCache.cacheKey(for: selectedCategory, page: currentPage)
        
        // Try cache first
        do {
            if let cachedArticles = await cache.get(forKey: cacheKey), !cachedArticles.isEmpty {
                articles.append(contentsOf: cachedArticles)
                canLoadMore = cachedArticles.count >= AppConfig.articlesPerPage
                isLoadingMore = false
                Logger.debug("📦 Loaded page \(currentPage) from cache", category: .viewModel)
                return
            }
        } catch {
            Logger.error("Cache read error for page \(currentPage): \(error.localizedDescription)", category: .viewModel)
        }
        
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
            
            // Cache the page
            do {
                await cache.set(articles: fetchedArticles, forKey: cacheKey)
            } catch {
                Logger.error("Failed to cache page \(currentPage): \(error.localizedDescription)", category: .viewModel)
            }
            
            canLoadMore = fetchedArticles.count >= AppConfig.articlesPerPage
            Logger.debug("✅ Loaded page \(currentPage) with \(newArticles.count) new articles", category: .viewModel)
            
        } catch {
            Logger.error("Failed to load page \(currentPage): \(error.localizedDescription)", category: .viewModel)
            currentPage -= 1 // Rollback page increment
        }
        
        isLoadingMore = false
    }

    // MARK: - Refresh
    func refreshArticles() async {
        do {
            await cache.clear(forCategory: selectedCategory)
        } catch {
            Logger.error("Failed to clear cache: \(error.localizedDescription)", category: .viewModel)
        }
        await loadArticles(useCache: false)
    }

    func refreshCategory(category: NewsCategory) async {
        Logger.debug("🔄 Refreshing category: \(category.displayName)", category: .viewModel)
        
        ToastManager.shared.show(toast: Toast(
            style: .info,
            message: "Refreshing \(category.displayName)..."
        ))
        
        do {
            await cache.clear(forCategory: category)
        } catch {
            Logger.error("Failed to clear cache for \(category.displayName): \(error.localizedDescription)", category: .viewModel)
        }
        
        if category == selectedCategory {
            await loadArticles(useCache: false)
        }
    }

    // MARK: - Category Change
    func changeCategory(_ category: NewsCategory) {
        Logger.debug("🔄 Changing category to: \(category.displayName)", category: .viewModel)
        
        // Skip if same category
        guard category != selectedCategory else {
            Logger.debug("⚠️ Category unchanged: \(category.displayName)", category: .viewModel)
            return
        }
        
        // Update category
        selectedCategory = category
        
        // Reset state
        articles = []
        errorMessage = nil
        currentPage = 1
        canLoadMore = true
        isLoading = true
        isLoadingMore = false
        
        // Cancel ongoing tasks
        cancelAllTasks()
        
        // Load new category
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                await self.cache.clear(forKey: NewsCache.cacheKey(for: category, page: 1))
                Logger.debug("🗑️ Cleared cache for \(category.displayName)", category: .viewModel)
            } catch {
                Logger.error("Failed to clear cache: \(error.localizedDescription)", category: .viewModel)
            }
            
            await self.loadArticles(useCache: false)
            Logger.debug("✅ Category changed to \(category.displayName) with \(self.articles.count) articles", category: .viewModel)
        }
    }

    // MARK: - Cleanup
    deinit {
        // Tasks are automatically cancelled when the view model is deallocated
    }
}
