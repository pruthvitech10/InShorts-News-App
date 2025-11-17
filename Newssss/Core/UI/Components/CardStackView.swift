//
//  CardStackView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI
import UIKit


// CardStackView

@available(iOS 15.0, *)
struct CardStackView: View {
    let articles: [Article]
    let category: NewsCategory

    @State private var currentIndex: Int = 0
    @State private var showDetail: Bool = false
    @State private var selectedArticle: Article?
    @State private var hasTriggeredLoadMore = false

    var onBookmark: ((Article) -> Void)?
    var onSkip: ((Article) -> Void)?
    var onLoadMore: (() -> Void)?

    private let maxVisibleCards = 3
    private let seenArticlesService = SeenArticlesService.shared

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Stacked cards
                ForEach(Array(visibleArticles.enumerated()), id: \.element.id) { index, article in
                    if index < maxVisibleCards {
                        // SwipeableCardView requires iOS 26+ (this struct is already annotated)
                        SwipeableCardView(
                            article: article,
                            currentIndex: currentIndex,
                            totalCount: articles.count,
                            category: category,
                            onSwipeLeft: {
                                handleSwipeLeft(article: article)
                            },
                            onSwipeRight: {
                                handleSwipeRight(article: article)
                            },
                            onTap: {
                                selectedArticle = article
                                showDetail = true
                            }
                        )
                        .frame(width: geometry.size.width - 32, height: geometry.size.height - 40)
                        .scaleEffect(scaleForIndex(index))
                        .offset(y: offsetForIndex(index))
                        .zIndex(Double(maxVisibleCards - index))
                        .opacity(index < 2 ? 1.0 : 0.5)
                        .allowsHitTesting(index == 0)
                    }
                }

                // No "caught up" message - user requirement
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Removed .sheet for article detail to prevent white modal popup on card tap
    }

    // Only show a few cards at a time for performance
    private var visibleArticles: [Article] {
        let endIndex = min(currentIndex + maxVisibleCards, articles.count)
        guard currentIndex < endIndex else { return [] }
        return Array(articles[currentIndex..<endIndex])
    }

    // Make cards look stacked
    private func scaleForIndex(_ index: Int) -> CGFloat {
        return 1.0 - (CGFloat(index) * 0.05)
    }

    private func offsetForIndex(_ index: Int) -> CGFloat {
        return CGFloat(index) * 10
    }

    // Handle left/right swipes
    private func handleSwipeLeft(article: Article) {
        // CRITICAL: Mark as seen - user will NEVER see this article again
        seenArticlesService.markAsSeen(article)
        
        // Track skip in history
        Task { @MainActor in
            SwipeHistoryService.shared.addSwipedArticle(article)
        }
        
        onSkip?(article)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentIndex += 1
        }
        
        // Load more when getting close to end (infinite scrolling)
        checkAndLoadMore()
        
        Logger.debug("⬅️ Skipped article - marked as seen forever", category: .general)
    }

    private func handleSwipeRight(article: Article) {
        // Mark as seen - user will NEVER see this article again
        seenArticlesService.markAsSeen(article)
        
        // Only track in history - NO bookmark
        // Bookmark only happens when user taps bookmark button
        Task { @MainActor in
            SwipeHistoryService.shared.addSwipedArticle(article)
        }
        
        onSkip?(article) // Just move to next card
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentIndex += 1
        }
        
        // Load more when getting close to end (infinite scrolling)
        checkAndLoadMore()
        
        Logger.debug("➡️ Swiped right (read) - marked as seen forever", category: .general)
    }
    
    // Check if we need to load more articles (infinite scrolling)
    private func checkAndLoadMore() {
        let currentArticleNumber = currentIndex + 1 // Article number (1-based)
        let totalArticles = articles.count
        
        // When user reaches article 80 (out of 100), silently fetch next batch
        // So by the time they reach article 100, new articles are ready
        // Only trigger once per batch
        if currentArticleNumber >= 80 && !hasTriggeredLoadMore {
            hasTriggeredLoadMore = true
            Logger.debug("🔄 User at article \(currentArticleNumber)/\(totalArticles) - fetching next batch silently...", category: .general)
            onLoadMore?()
        }
        
        // Reset flag when new articles arrive (total count increases significantly)
        if totalArticles > currentArticleNumber + 50 {
            hasTriggeredLoadMore = false
        }
    }
    
    // Share article
    private func shareArticle(_ article: Article) {
        guard let url = URL(string: article.url) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        // Present from the app's root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// Preview

#Preview {
    CardStackView(
        articles: [
            Article(
                source: Source(id: "test1", name: "Test Source 1"),
                author: "Author 1",
                title: "D Gukesh's grace wins hearts after beating Hikaru Nakamura",
                description: "World champion D Gukesh's humble gesture earned praise for his sportsmanship.",
                url: "https://example.com",
                urlToImage: nil,
                publishedAt: "2025-10-29T10:00:00Z",
                content: "Test content"
            ),
            Article(
                source: Source(id: "test2", name: "Test Source 2"),
                author: "Author 2",
                title: "Second Article Title",
                description: "This is the description for the second article.",
                url: "https://example.com",
                urlToImage: nil,
                publishedAt: "2025-10-29T09:00:00Z",
                content: "Test content"
            )
        ],
        category: .sports
    )
}
