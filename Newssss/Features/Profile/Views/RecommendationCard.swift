//
//  RecommendationCard.swift
//  Newssss
//
//  Personalized article recommendation card
//  Created on 6 November 2025.
//

import SwiftUI


// MARK: - RecommendationCard

struct RecommendationCard: View {
    let article: Article
    @State private var showArticle = false
    
    var body: some View {
        Button(action: {
            showArticle = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Article image or placeholder
                ZStack(alignment: .topTrailing) {
                    if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .empty, .failure:
                                Rectangle()
                                    .fill(LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                    }
                    
                    // "Why you're seeing this" tag
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("For You")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(8)
                }
                .frame(height: 140)
                .cornerRadius(12)
                
                // Article info
                VStack(alignment: .leading, spacing: 8) {
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
                        
                        if let date = article.publishedDate {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(date.timeAgoDisplay())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Recommendation reason
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption2)
                            .foregroundColor(.purple)
                        Text(getRecommendationReason())
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 4)
            }
            .frame(width: 260)
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showArticle) {
            NavigationView {
                ArticleDetailView(article: article)
            }
        }
    }
    
    private func getRecommendationReason() -> String {
        // Note: Replace with AI-powered recommendation engine when ready
        let reasons = [
            "Similar to your recent reads",
            "Trending in your interests",
            "Based on your bookmarks",
            "Popular in Technology"
        ]
        return reasons.randomElement() ?? "Recommended for you"
    }
}

// MARK: - RecommendationCardSkeleton

struct RecommendationCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 140)
                .cornerRadius(12)
                .shimmer(isAnimating: isAnimating)
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .cornerRadius(4)
                    .shimmer(isAnimating: isAnimating)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(width: 180)
                    .cornerRadius(4)
                    .shimmer(isAnimating: isAnimating)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(width: 120)
                    .cornerRadius(4)
                    .shimmer(isAnimating: isAnimating)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 260)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        self.modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

// MARK: - ShimmerModifier

struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .opacity(isAnimating ? 1 : 0)
            )
            .onAppear {
                if isAnimating {
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 400
                    }
                }
            }
            .mask(content)
    }
}
