
//
//  FeedView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI


// FeedView

@available(iOS 15.0, *)
struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel(selectedCategory: .forYou)
    @StateObject private var bookmarkService = BookmarkService.shared
    @State private var selectedArticle: Article?
    @StateObject private var toastManager = ToastManager.shared

    var body: some View {
            NavigationStack {
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()
                    VStack(spacing: 0) {
                // Modern header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("InShorts")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Welcome")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    CategoryHeaderView(
                        selectedCategory: $viewModel.selectedCategory,
                        onCategoryChange: { category in
                            viewModel.changeCategory(category)
                        },
                        onCategoryDoubleClick: { category in
                            Task {
                                await viewModel.refreshCategory(category: category)
                            }
                        }
                    )
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))

                // Trending banner removed per user request

                ZStack {
                    // Always show cards with ID for smooth transitions
                    if !viewModel.articles.isEmpty {
                        CardStackView(
                            articles: viewModel.articles,
                            category: viewModel.selectedCategory,
                            onBookmark: { article in
                                try? bookmarkService.addBookmark(article)
                                toastManager.show(
                                    toast: Toast(
                                        style: .success,
                                        message: "Article saved to your bookmarks.",
                                        duration: 3.0
                                    )
                                )
                            },
                            onSkip: { article in
                                // Just skip, don't bookmark
                                Logger.debug("⬅️ Skipped article", category: .general)
                            }
                        )
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .id(viewModel.selectedCategory) // Key for smooth transitions
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    
                    // Show loading overlay when switching categories
                    if viewModel.isLoading && !viewModel.articles.isEmpty {
                        // Smooth loading overlay - keep existing cards visible
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.blue)
                                    Text("Loading \(viewModel.selectedCategory.displayName)...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(24)
                                .background(Color(.systemBackground).opacity(0.95))
                                .cornerRadius(16)
                                .shadow(radius: 10)
                                Spacer()
                            }
                            Spacer()
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
                        .zIndex(1)
                    }
                    
                    if viewModel.isLoading && viewModel.articles.isEmpty {
                        LoadingView()
                    } else if let errorMessage = viewModel.errorMessage, viewModel.articles.isEmpty {
                        ErrorView(message: errorMessage) {
                            Task { await viewModel.loadArticles(useCache: false) }
                        }
                    } else if viewModel.articles.isEmpty {
                        EmptyStateView(
                            icon: "newspaper",
                            title: "No articles available",
                            message: "Try selecting a different category or refresh to load new content.",
                            actionTitle: "Retry",
                            action: { Task { await viewModel.loadArticles(useCache: false) } }
                        )
                    }
                    
                    // Loading more indicator
                    if viewModel.isLoadingMore {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                    .background(Color(.systemBackground).opacity(0.9))
                                    .cornerRadius(8)
                                Spacer()
                            }
                            .padding(.bottom, 120)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: viewModel.selectedCategory)
                .animation(.easeInOut(duration: 0.3), value: viewModel.articles.count)
                    }
                    .navigationBarHidden(true)
                    .task {
                        // Load articles when view appears
                        if viewModel.articles.isEmpty {
                            await viewModel.loadArticles(useCache: false)
                        }
                    }
                    .refreshable {
                        await viewModel.refreshArticles()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CacheClearedRefreshFeed"))) { _ in
                        Task {
                            await viewModel.refreshArticles()
                        }
                    }
                    .sheet(item: $selectedArticle) { article in
                        ArticleDetailView(article: article)
                    }
                    .overlay(
                        toastManager.toast.map { toast in
                            ToastView(toast: toast)
                                .transition(.move(edge: .top))
                        }
                        .animation(.spring(), value: toastManager.toast)
                        , alignment: .top
                    )
                }
            }
    }
}

// Preview

#Preview {
    FeedView()
}
