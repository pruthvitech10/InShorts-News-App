//
//  BreakingNewsView.swift
//  Newssss
//
//  Breaking News - Most viewed/trending articles from all sources
//

import SwiftUI
import Combine

@available(iOS 26.0, *)
struct BreakingNewsView: View {
    @StateObject private var viewModel = BreakingNewsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading Breaking News...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 12)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.breakingNews.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.secondary)
                            Text("No Breaking News")
                                .font(.headline)
                            Text("Check back soon for the latest updates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        // Breaking News Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                Text("Breaking News")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            
                            Text("\(viewModel.breakingNews.count) trending stories from top sources")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // Articles List
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.breakingNews.enumerated()), id: \.element.id) { index, article in
                                TrendingArticleRow(article: article, rank: index + 1)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                
                                if index < viewModel.breakingNews.count - 1 {
                                    Divider()
                                        .padding(.leading, 80)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .task {
            await viewModel.loadBreakingNews()
        }
    }
}

// Trending Article Row with ranking
struct TrendingArticleRow: View {
    let article: Article
    let rank: Int
    @State private var showingSafari = false
    
    var body: some View {
        Button(action: {
            showingSafari = true
        }) {
            HStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 32, height: 32)
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
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
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "newspaper")
                                .foregroundColor(.secondary)
                                .font(.title2)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Trending badge
                    if rank <= 3 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                            Text("TRENDING")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Text(article.source.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
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
    
    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .gray
        }
    }
}

// ViewModel for Breaking News
@MainActor
class BreakingNewsViewModel: ObservableObject {
    @Published var breakingNews: [Article] = []
    @Published var isLoading: Bool = false
    
    // Top Italian news sources (most reliable and popular)
    private let topSources = [
        "ANSA", "La Repubblica", "Corriere", "Il Sole 24 Ore",
        "La Stampa", "Il Post", "Il Fatto Quotidiano", "Sky TG24"
    ]
    
    func loadBreakingNews() async {
        isLoading = true
        
        Logger.debug("📰 Loading breaking news from all sources...", category: .viewModel)
        
        // Get articles from all categories
        var allArticles: [Article] = []
        let categories = ["politics", "world", "business", "technology", "sports", "entertainment", "crime"]
        
        for categoryKey in categories {
            if let categoryArticles = await NewsMemoryStore.shared.getArticles(for: categoryKey) {
                allArticles.append(contentsOf: categoryArticles)
                Logger.debug("📊 Found \(categoryArticles.count) articles in \(categoryKey)", category: .viewModel)
            }
        }
        
        Logger.debug("📊 Total articles collected: \(allArticles.count)", category: .viewModel)
        
        // Score articles based on multiple factors
        let scoredArticles = allArticles.map { article -> (article: Article, score: Double) in
            var score: Double = 0.0
            
            // 1. Recency (most recent = higher score) - 40% weight
            if let publishedDate = article.publishedDate {
                let hoursSincePublished = abs(publishedDate.timeIntervalSinceNow) / 3600
                let recencyScore = max(0, 100 - hoursSincePublished) // Score decreases with age
                score += recencyScore * 0.4
            }
            
            // 2. Source quality (top sources = higher score) - 30% weight
            let sourceName = article.source.name
            if topSources.contains(where: { sourceName.contains($0) }) {
                score += 30
            }
            
            // 3. Category importance (politics, world, business = higher) - 20% weight
            // We can't directly know category, but we can infer from source
            if sourceName.lowercased().contains("politic") ||
               sourceName.lowercased().contains("world") ||
               sourceName.lowercased().contains("business") {
                score += 20
            }
            
            // 4. Has image (better engagement) - 10% weight
            if article.urlToImage != nil {
                score += 10
            }
            
            return (article, score)
        }
        
        // Sort by score and take top 50
        let topArticles = scoredArticles
            .sorted { $0.score > $1.score }
            .prefix(50)
            .map { $0.article }
        
        // Remove duplicates by URL
        var seen = Set<String>()
        breakingNews = topArticles.filter { article in
            guard !seen.contains(article.url) else { return false }
            seen.insert(article.url)
            return true
        }
        
        isLoading = false
        
        Logger.debug("✅ Loaded \(breakingNews.count) breaking news articles", category: .viewModel)
    }
}
