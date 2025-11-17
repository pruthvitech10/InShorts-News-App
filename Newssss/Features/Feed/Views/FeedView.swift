
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
    @StateObject private var viewModel = FeedViewModel(selectedCategory: .general)
    @StateObject private var bookmarkService = BookmarkService.shared
    @State private var selectedArticle: Article?
    @StateObject private var toastManager = ToastManager.shared
    @ObservedObject private var locationService = LocationService.shared
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

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

                    VStack(spacing: 4) {
                        CategoryHeaderView(
                            selectedCategory: $viewModel.selectedCategory,
                            onCategoryChange: { category in
                                viewModel.changeCategory(category)
                            },
                            onCategoryDoubleClick: { category in
                                // Show refresh toast
                                ToastManager.shared.show(toast: Toast(
                                    style: .info,
                                    message: "Refreshing \(category.displayName)...",
                                    duration: 1.5
                                ))
                                Task {
                                    await viewModel.refreshCategory(category: category)
                                }
                            }
                        )
                    }
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
                            },
                            onLoadMore: {
                                // Infinite scrolling - load more articles
                                Task {
                                    await viewModel.loadMoreArticles()
                                }
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
                    } else if viewModel.articles.isEmpty && !viewModel.isLoading {
                        // Check if offline - show subtle message
                        if !networkMonitor.isConnected {
                            VStack(spacing: 0) {
                                Spacer()
                                Text("Offline")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        } else {
                            // Auto-reload if articles run out and online
                            Color.clear
                                .onAppear {
                                    Task {
                                        await viewModel.loadArticles(useCache: false)
                                    }
                                }
                        }
                    }
                    
                    // NO loading indicator - articles just appear
                }
                .animation(.easeInOut(duration: 0.4), value: viewModel.selectedCategory)
                .animation(.easeInOut(duration: 0.3), value: viewModel.articles.count)
                    }
                    .navigationBarHidden(true)
                    .task {
                        // ⚡ Load articles IMMEDIATELY from cache - don't wait for location!
                        await viewModel.loadArticles(useCache: true)
                    }
                    .onChange(of: locationService.isLocationReady) { isReady in
                        if isReady {
                            Logger.debug("✅ Location ready! Refreshing with location data in background...", category: .general)
                            Task {
                                await viewModel.loadArticles(useCache: true)
                            }
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
                    .onReceive(NotificationCenter.default.publisher(for: .locationDidUpdate)) { _ in
                        Logger.debug("📍 Location changed - will use new location in next auto-refresh", category: .general)
                        // Don't trigger immediate refresh - let auto-refresh handle it
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
