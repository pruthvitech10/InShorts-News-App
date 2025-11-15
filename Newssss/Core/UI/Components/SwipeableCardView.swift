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
    


    var onSwipeLeft: (() -> Void)?
    var onSwipeRight: (() -> Void)?
    var onTap: (() -> Void)?

    private let swipeThreshold: CGFloat = 120

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // MARK: - Image + Category Badge
                    ZStack(alignment: .topLeading) {
                        if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .font(.system(size: 50))
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.45)
                            .clipped()
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

                    // MARK: - Article Info
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Text(article.source.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("•")
                                .foregroundColor(.secondary)

                            if let date = article.publishedDate {
                                Text(date.timeAgoDisplay())
                                    .font(.subheadline)
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
                                    .font(.title2)
                                    .foregroundColor(isBookmarked ? .yellow : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                        }

                        // Title
                        Text(isTranslated ? translatedTitle : article.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .animation(.easeInOut(duration: 0.8), value: isTranslated)

                        // Description
                        if let description = article.description {
                            Text(isTranslated ? translatedDescription : description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(4)
                                .fixedSize(horizontal: false, vertical: true)
                                .animation(.easeInOut(duration: 0.8), value: isTranslated)
                        }

                        Spacer()

                        // MARK: - Action Buttons
                        HStack(spacing: 12) {
                            // Translate Button
                            Button(action: {
                                if isTranslating { return }
                                
                                if isTranslated {
                                    // Switch back to original
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        isTranslated = false
                                    }
                                } else {
                                    // Translate
                                    Task {
                                        await translateArticle()
                                    }
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isTranslating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: isTranslated ? "globe.badge.chevron.backward" : "globe")
                                            .font(.subheadline)
                                    }
                                    Text(isTranslated ? "Original" : "Translate")
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
                    .padding(20)
                }
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
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
        .fullScreenCover(isPresented: $showingSafari) {
            if let url = URL(string: article.url) {
                SafariView(url: url).ignoresSafeArea()
            }
        }
        .onAppear {
            isBookmarked = BookmarkService.shared.isBookmarked(article)
        }
    }

    // MARK: - Category Color
    private func categoryColor(for category: NewsCategory) -> Color {
        switch category {
        case .forYou: return .teal.opacity(0.9)
        case .technology: return .blue.opacity(0.9)
        case .business: return .green.opacity(0.9)
        case .sports: return .orange.opacity(0.9)
        case .entertainment: return .purple.opacity(0.9)
        case .politics: return .red.opacity(0.9)
        case .science: return .cyan.opacity(0.9)
        case .health: return .pink.opacity(0.9)
        case .general: return .gray.opacity(0.9)
        case .history: return .indigo.opacity(0.9)
        }
    }
    
    // MARK: - Inline Translation
    @MainActor
    private func translateArticle() async {
        isTranslating = true
        
        let targetLanguage = Locale.Language(identifier: "en")
        let commonSources = ["it", "es", "fr", "de", "pt", "nl", "ru", "zh", "ja", "ko", "ar", "hi", "tr"]
        
        do {
            for sourceCode in commonSources {
                do {
                    let sourceLanguage = Locale.Language(identifier: sourceCode)
                    let session = try TranslationSession(installedSource: sourceLanguage, target: targetLanguage)
                    
                    if !article.title.isEmpty {
                        let response = try await session.translate(article.title)
                        translatedTitle = response.targetText
                    }
                    
                    if let description = article.description, !description.isEmpty {
                        let response = try await session.translate(description)
                        translatedDescription = response.targetText
                    }
                    
                    withAnimation(.easeInOut(duration: 0.8)) {
                        isTranslated = true
                    }
                    
                    isTranslating = false
                    Logger.debug("Translated from \(sourceCode) to English", category: .general)
                    return
                    
                } catch {
                    continue
                }
            }
            
            isTranslating = false
            Logger.debug("No compatible source language detected", category: .general)
        } catch {
            isTranslating = false
            ErrorLogger.log(error, context: "Translation")
        }
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
