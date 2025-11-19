//
//  SearchView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI


// SearchView

@available(iOS 26.0, *)
struct SearchView: View {
    @ObservedObject private var viewModel = SearchViewModel.shared
    @State private var searchTask: Task<Void, Never>? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SearchTab = .myFeed

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    TextField("Search for News, Topics", text: $viewModel.query)
                        .font(.system(size: 15))
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.search() }
                        }

                    if !viewModel.query.isEmpty {
                        Button(action: {
                            viewModel.query = ""
                            viewModel.results = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // Category shortcuts
            if viewModel.query.isEmpty {
                CategoryShortcutsView()
                    .padding(.top, 8)
            }

            // Results area
            if viewModel.isLoading {
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
                        Task { await viewModel.search() }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                Spacer()
            } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.headline)
                    Text("Try searching for something else")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else if viewModel.results.isEmpty {
                ScrollView {
                    VStack(spacing: 24) {
                        // Word Wheel Game Banner removed - feature disabled

                        // Notifications Section
                        NotificationsSection(viewModel: viewModel)
                            .padding(.horizontal, 16)

                        // Trending searches
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Try searching for:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)

                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    TrendingSearchButton(text: "Politics", icon: "building.columns") {
                                        viewModel.query = "Politics"
                                        Task { await viewModel.search() }
                                    }
                                    TrendingSearchButton(text: "Sports", icon: "sportscourt") {
                                        viewModel.query = "Sports"
                                        Task { await viewModel.search() }
                                    }
                                }

                                HStack(spacing: 12) {
                                    TrendingSearchButton(text: "Technology", icon: "laptopcomputer") {
                                        viewModel.query = "Technology"
                                        Task { await viewModel.search() }
                                    }
                                    TrendingSearchButton(text: "Entertainment", icon: "theatermasks") {
                                        viewModel.query = "Entertainment"
                                        Task { await viewModel.search() }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Insights Section
                        // InsightsSection removed - AI feature disabled
                    }
                }
            } else {
                // Search results
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.results) { article in
                            SearchResultRow(article: article)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)

                            if article.id != viewModel.results.last?.id {
                                Divider()
                                    .padding(.leading, 80)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .onChange(of: viewModel.query) { newValue in
            // Debounce: cancel previous task and start a new delayed search
            searchTask?.cancel()
            guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                viewModel.results = []
                return
            }
            searchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
                await viewModel.search()
            }
        }
    }
}

// Search tabs

enum SearchTab {
    case myFeed, allNews, topStories, trending
}

// Quick category shortcuts

@available(iOS 26.0, *)
struct CategoryShortcutsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.headline)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    NavigationLink(destination: CategoryFeedView(feedType: .myFeed)) {
                        CategoryShortcutCard(
                            icon: "newspaper.fill",
                            iconColor: .blue,
                            title: "My Feed",
                            subtitle: "Personalized"
                        )
                    }

                    NavigationLink(destination: CategoryFeedView(feedType: .allNews)) {
                        CategoryShortcutCard(
                            icon: "doc.text.fill",
                            iconColor: .green,
                            title: "All News",
                            subtitle: "Latest updates"
                        )
                    }

                    NavigationLink(destination: CategoryFeedView(feedType: .topStories)) {
                        CategoryShortcutCard(
                            icon: "star.fill",
                            iconColor: .orange,
                            title: "Top Stories",
                            subtitle: "Most popular"
                        )
                    }

                    NavigationLink(destination: CategoryFeedView(feedType: .trending)) {
                        CategoryShortcutCard(
                            icon: "flame.fill",
                            iconColor: .red,
                            title: "Trending",
                            subtitle: "Hot topics"
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 16)
    }
}

// Category shortcut card

struct CategoryShortcutCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 56, height: 56)
                .background(iconColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(16)
    }
}

// Trending search button

struct TrendingSearchButton: View {
    let text: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.subheadline)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
    }
}

// Search result row

struct SearchResultRow: View {
    let article: Article
    @State private var showingSafari = false

    var body: some View {
        Button(action: {
            showingSafari = true
        }) {
            HStack(spacing: 12) {
                // Thumbnail
                if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(ProgressView())
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "newspaper")
                                .foregroundColor(.secondary)
                        )
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let date = article.publishedDate {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(date.timeAgoDisplay())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingSafari) {
            if let url = URL(string: article.url) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

// Breaking news section - Shows trending/most viewed articles

struct NotificationsSection: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var showBreakingNewsView = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Text("Breaking News")
                        .font(.title3)
                        .fontWeight(.bold)

                    if viewModel.isLoadingBreaking {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .overlay(
                                Circle()
                                    .fill(Color.red.opacity(0.3))
                                    .scaleEffect(1.5)
                            )
                    }
                }

                Spacer()

                Button(action: {
                    showBreakingNewsView = true
                }) {
                    Text("VIEW ALL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }

            // Show breaking news articles
            if viewModel.breakingNews.isEmpty && !viewModel.isLoadingBreaking {
                VStack(spacing: 8) {
                    Image(systemName: "newspaper.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("No breaking news available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ForEach(viewModel.breakingNews.prefix(3), id: \.url) { article in
                    BreakingNewsRow(article: article)
                }
            }

            Button(action: {
                Task {
                    await viewModel.loadBreakingNews(force: true)
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
        }
        .task {
            await viewModel.loadBreakingNews()
        }
        .sheet(isPresented: $showBreakingNewsView) {
            BreakingNewsView()
        }
    }
}

// Breaking news row (clickable)

struct BreakingNewsRow: View {
    let article: Article
    @State private var showingSafari = false
    
    var body: some View {
        Button(action: {
            showingSafari = true
        }) {
            HStack(spacing: 12) {
                // Article image
                if let imageURL = article.urlToImage, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "newspaper.fill")
                                .foregroundColor(.gray)
                        )
                }
                
                // Article info
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 4) {
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let publishedDate = article.publishedDate {
                            Text(timeAgo(from: publishedDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingSafari) {
            if let url = URL(string: article.url) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        if hours < 1 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }
}

// AI Insights (disabled)
// The AI Insights feature has been temporarily disabled

// Hex color support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview

@available(iOS 26.0, *)
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SearchView()
        }
    }
}
