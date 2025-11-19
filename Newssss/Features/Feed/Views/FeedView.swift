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
                    // 1. Blocking No Internet View
                    if !networkMonitor.isConnected {
                        NoInternetView()
                            .transition(.opacity)
                            .zIndex(999)
                    } else {
                        // 2. Main Content (Only shown if connected)
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

                            ZStack {
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
                                            Logger.debug("⬅️ Skipped article", category: .general)
                                        },
                                        onLoadMore: {
                                            Task {
                                                await viewModel.loadMoreArticles()
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                                    .id(viewModel.selectedCategory)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                                }
                                
                                if viewModel.isLoading && !viewModel.articles.isEmpty {
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
                                                
                                                if !networkMonitor.isConnected {
                                                    Text("Waiting for internet...")
                                                        .font(.caption)
                                                        .foregroundColor(.red)
                                                }
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
                                    Color.clear
                                        .onAppear {
                                            Task {
                                                await viewModel.loadArticles(useCache: false)
                                            }
                                        }
                                }
                            }
                            .animation(.easeInOut(duration: 0.4), value: viewModel.selectedCategory)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.articles.count)
                        }
                    }
                }
                .navigationBarHidden(true)
                .task {
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

#Preview {
    FeedView()
}
