//
//  SwipeableCardView.swift
//  DailyNews
//
//  Created on 29 October 2025.
//

import SwiftUI
import Translation

import UIKit

@available(iOS 15.0, *)
struct SwipeableCardView: View {
    let article: Article
    let currentIndex: Int
    let totalCount: Int
    let category: NewsCategory

    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var showingSafari = false
    @State private var isBookmarked = false
    @State private var isTranslated = false
    @State private var translatedTitle: String = ""
    @State private var translatedDescription: String = ""
    @State private var isTranslating = false
    @State private var showTranslationUI = false
    


    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    var onTap: (() -> Void)?

    private let swipeThreshold: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // Image + Category Badge
                    ZStack(alignment: .topLeading) {
                        if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray.opacity(0.2)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Color.gray.opacity(0.2)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray.opacity(0.5))
                                        )
                                @unknown default:
                                    Color.clear
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.45)
                            .clipped()
                            .drawingGroup() // GPU acceleration
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: geometry.size.height * 0.45)
                        }

                        // Category badge
                        HStack {
                            Image(systemName: category.icon)
                                .font(.caption2)
                            Text(category.displayName.uppercased())
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(categoryColor(for: category))
                        .cornerRadius(20)
                        .padding(16)
                    }

                    // Article Info
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Text(article.source.name)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            if let date = article.publishedDate {
                                Text(date.timeAgoDisplay())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Bookmark button
                            Button(action: {
                                BookmarkService.shared.toggleBookmark(article)
                                isBookmarked = BookmarkService.shared.isBookmarked(article)
                                HapticFeedback.light()
                            }) {
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.title3)
                                    .foregroundColor(isBookmarked ? .yellow : .primary)
                                    .frame(width: 40, height: 40)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                        }

                        // Title - Smaller and cleaner
                        Text(isTranslated ? translatedTitle : article.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .animation(.easeInOut(duration: 0.8), value: isTranslated)

                        // InShorts Summary - 60-80 words (6-7 lines)
                        if let description = article.description {
                            let summary = createInShortsSummary(from: description.stripHTML())
                            Text(isTranslated ? translatedDescription : summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(7)
                                .multilineTextAlignment(.leading)
                                .animation(.easeInOut(duration: 0.8), value: isTranslated)
                        }

                        Spacer()

                        // Action Buttons
                        HStack(spacing: 12) {
                            // Translate Button
                            Button(action: {
                                // Show Apple's translation UI
                                showTranslationUI = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "globe")
                                        .font(.subheadline)
                                    Text("Translate")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }

                            // Read Button
                            Button(action: { showingSafari = true }) {
                                HStack(spacing: 8) {
                                    Text("Read More")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Image(systemName: "arrow.right")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    if gesture.translation.width > swipeThreshold {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            offset = CGSize(width: 500, height: 0)
                            rotation = 15
                            scale = 0.8
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeRight?()
                        }
                    } else if gesture.translation.width < -swipeThreshold {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            offset = CGSize(width: -500, height: 0)
                            rotation = -15
                            scale = 0.8
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeLeft?()
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            offset = .zero
                            rotation = 0
                            scale = 1.0
                        }
                    }
                }
        )
        .onTapGesture { onTap?() }
        .translationPresentation(isPresented: $showTranslationUI, text: article.title + "\n\n" + (article.description ?? ""))
        .fullScreenCover(isPresented: $showingSafari) {
            if let url = URL(string: article.url) {
                ArticleWebViewWrapper(url: url, articleTitle: article.title, articleDescription: article.description)
            }
        }
        .onAppear {
            isBookmarked = BookmarkService.shared.isBookmarked(article)
        }
    }

    // Category Color
    private func categoryColor(for category: NewsCategory) -> Color {
        switch category {
        case .technology: return .blue.opacity(0.9)
        case .business: return .green.opacity(0.9)
        case .sports: return .orange.opacity(0.9)
        case .entertainment: return .purple.opacity(0.9)
        case .politics: return .red.opacity(0.9)
        case .world: return .blue.opacity(0.9)
        case .crime: return .red.opacity(0.8)
        case .automotive: return .orange.opacity(0.8)
        case .lifestyle: return .mint.opacity(0.9)
        case .general: return .gray.opacity(0.9)
        case .recentlySeen: return .indigo.opacity(0.9)
        }
    }
    
    // Creates a nice summary like InShorts does - about 6-7 lines
    private func createInShortsSummary(from description: String) -> String {
        let cleaned = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Break into sentences
        let sentences = cleaned.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return cleaned }
        
        // Build summary from first few sentences
        var summary = ""
        var wordCount = 0
        let targetWords = 75 // Aiming for about 75 words
        
        for sentence in sentences.prefix(6) {
            let words = sentence.split(separator: " ")
            if wordCount + words.count <= targetWords + 20 {
                summary += sentence + ". "
                wordCount += words.count
            } else if wordCount < 50 {
                // Add this sentence if we're still short
                summary += sentence + ". "
                wordCount += words.count
            } else {
                break
            }
        }
        
        // Fallback if summary is too short
        if wordCount < 40 {
            let words = cleaned.split(separator: " ").prefix(80)
            return words.joined(separator: " ") + (words.count >= 80 ? "..." : "")
        }
        
        return summary.trimmingCharacters(in: .whitespaces)
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        SwipeableCardView(
            article: Article(
                source: Source(id: "test", name: "TechCrunch"),
                author: "Test Author",
                title: "Apple Unveils Revolutionary AI Features in iOS 26",
                description: "Apple announced groundbreaking AI capabilities in iOS 26, including advanced Siri improvements and system-wide intelligence features.",
                url: "https://example.com",
                urlToImage: nil,
                publishedAt: "2025-10-29T10:00:00Z",
                content: "Test content"
            ),
            currentIndex: 0,
            totalCount: 8,
            category: .technology
        )
        .padding()
    } else {
        Text("Requires iOS 26.0 or later")
    }
}
