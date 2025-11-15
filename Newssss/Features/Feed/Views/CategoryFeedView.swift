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

    var category: NewsCategory {
        switch self {
        case .myFeed: return NewsCategory.general
        case .allNews: return NewsCategory.general
        case .topStories: return NewsCategory.general
        case .trending: return NewsCategory.general
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
            } else if viewModel.articles.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "newspaper")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No articles available")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                // Card stack view (requires iOS 26+)
                GeometryReader { geometry in
                    CardStackView(articles: viewModel.articles, category: feedType.category)
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

    private let aggregatorService = NewsAggregatorService.shared

    func loadArticles(for feedType: FeedType) async {
        isLoading = true
        errorMessage = nil
        
        // No cache - always fresh!
    
    do {
        let fetchedEnhancedArticles: [EnhancedArticle]

        switch feedType {
            case .myFeed:
                // Personalized feed based on user preferences (location-based)
                fetchedEnhancedArticles = try await aggregatorService.fetchAggregatedNews(
                    category: feedType.category,
                    useLocationBased: true
                )

            case .allNews:
                // All news from all categories
                fetchedEnhancedArticles = try await aggregatorService.fetchAggregatedNews(
                    category: feedType.category,
                    useLocationBased: false
                )

            case .topStories:
                fetchedEnhancedArticles = try await aggregatorService.fetchAggregatedNews(
                    category: feedType.category,
                    useLocationBased: false
                )

            case .trending:
                fetchedEnhancedArticles = try await aggregatorService.fetchAggregatedNews(
                    category: feedType.category,
                    useLocationBased: false
                )
            }

            // Extract Article objects from EnhancedArticle
            let fetchedArticles = fetchedEnhancedArticles.map { $0.article }
            articles = fetchedArticles

            ErrorLogger.logInfo("Loaded \(articles.count) articles for \(feedType.title)")
        } catch {
            errorMessage = error.localizedDescription
            ErrorLogger.log(error, context: "CategoryFeed - \(feedType.title)")
        }

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
