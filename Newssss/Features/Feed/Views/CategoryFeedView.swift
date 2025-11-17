//
//  CategoryFeedView.swift
//  DailyNews
//
//  Created on 5 November 2025.
//

import SwiftUI
import Combine


// Types of feeds available

enum FeedType {
    case myFeed
    case allNews
    case topStories
    case trending

    var title: String {
        switch self {
        case .myFeed: return "My Feed"
        case .allNews: return "All News"
        case .topStories: return "Top Stories"
        case .trending: return "Trending"
        }
    }

    var icon: String {
        switch self {
        case .myFeed: return "newspaper.fill"
        case .allNews: return "doc.text.fill"
        case .topStories: return "star.fill"
        case .trending: return "flame.fill"
        }
    }

    var categories: [String] {
        switch self {
        case .myFeed: return ["general"] // User's personalized feed
        case .allNews: return ["general", "politics", "business", "technology", "entertainment", "sports", "world", "crime", "automotive", "lifestyle"] // All categories
        case .topStories: return ["politics", "world", "business"] // Important news
        case .trending: return ["entertainment", "sports", "technology"] // Popular topics
        }
    }
}

// CategoryFeedView

@available(iOS 26.0, *)
struct CategoryFeedView: View {
    let feedType: FeedType
    @StateObject private var viewModel = CategoryFeedViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: feedType.icon)
                        .font(.title3)
                        .foregroundColor(.primary)
                    Text(feedType.title)
                        .font(.headline)
                }

                Spacer()

                // Placeholder for symmetry
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .opacity(0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))

            // Content
            if viewModel.isLoading && viewModel.articles.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Spacer()
            } else if let error = viewModel.errorMessage {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button("Try Again") {
                        Task {
                            await viewModel.loadArticles(for: feedType)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Spacer()
            } else {
                // No empty state - with memory store, there's always content!
                // Card stack view (requires iOS 26+)
                GeometryReader { geometry in
                    CardStackView(articles: viewModel.articles, category: .general)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .task {
            await viewModel.loadArticles(for: feedType)
        }
    }
}

// View model for category feed

@available(iOS 26.0, *)
@MainActor
class CategoryFeedViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadArticles(for feedType: FeedType) async {
        isLoading = true
        errorMessage = nil
        
        Logger.debug("📰 Loading \(feedType.title) from memory store...", category: .viewModel)
        
        // Load from memory store (instant!)
        var allArticles: [Article] = []
        
        for categoryKey in feedType.categories {
            if let categoryArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                allArticles.append(contentsOf: categoryArticles)
                Logger.debug("✅ Loaded \(categoryArticles.count) articles from \(categoryKey)", category: .viewModel)
            }
        }
        
        if !allArticles.isEmpty {
            // ⚡ INSTANT: Show articles from memory
            articles = allArticles.shuffled() // Mix articles for variety
            isLoading = false
            Logger.debug("⚡ INSTANT: Showing \(articles.count) articles for \(feedType.title)", category: .viewModel)
            return
        }
        
        // No memory - wait for auto-refresh (runs every 20 minutes)
        Logger.debug("📡 No memory cache, waiting for auto-refresh...", category: .viewModel)
        
        isLoading = false
    }
}

// Preview

@available(iOS 26.0, *)
struct CategoryFeedView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CategoryFeedView(feedType: .trending)
        }
    }
}
