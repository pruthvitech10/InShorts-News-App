//
//  BookmarksView.swift
//  Newssss
//
//  Bookmarked articles view
//

import SwiftUI


// BookmarksView

struct BookmarksView: View {
    @StateObject private var bookmarkService = BookmarkService.shared
    @State private var selectedArticle: Article?
    @State private var showDeleteConfirmation = false
    @State private var articleToDelete: Article?
    
    var body: some View {
        Group {
            if bookmarkService.bookmarks.isEmpty {
                emptyState
            } else {
                bookmarksList
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedArticle) { article in
            NavigationView {
                ArticleDetailView(article: article)
            }
        }
        .alert("Remove Bookmark", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                articleToDelete = nil
            }
            Button("Remove", role: .destructive) {
                if let article = articleToDelete {
                    try? bookmarkService.removeBookmark(article)
                    articleToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to remove this bookmark?")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("No Bookmarks")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Save articles you want to read later by tapping the bookmark button")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // Bookmarks List
    
    private var bookmarksList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(bookmarkService.bookmarks, id: \.url) { article in
                        BookmarkCard(
                            article: article,
                            onTap: {
                                selectedArticle = article
                            },
                            onDelete: {
                                articleToDelete = article
                                showDeleteConfirmation = true
                            }
                        )
                        .id(article.url)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .refreshable {
                // Reload bookmarks from disk
                await bookmarkService.loadBookmarks()
            }
            .onChange(of: bookmarkService.bookmarks.count) { _ in
                // when a new bookmark is added, scroll to the last (new) item so it appears in the down section
                if let last = bookmarkService.bookmarks.last {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(last.url, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// BookmarkCard

private struct BookmarkCard: View {
    let article: Article
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Article Image
                if let imageUrl = article.urlToImage, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure(_):
                            placeholderImage
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
                
                // Article Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(timeAgo(from: article.publishedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .contextMenu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove Bookmark", systemImage: "bookmark.slash")
                }
                
                Button {
                    if let url = URL(string: article.url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open in Browser", systemImage: "safari")
                }
                
                Button {
                    if let url = URL(string: article.url) {
                        UIPasteboard.general.string = url.absoluteString
                    }
                } label: {
                    Label("Copy Link", systemImage: "doc.on.doc")
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "newspaper")
                    .font(.title2)
                    .foregroundColor(.gray)
            )
    }
    
    private func timeAgo(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            return ""
        }
        
        let now = Date()
        let seconds = Int(now.timeIntervalSince(date))
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}

// Preview

#Preview {
    NavigationStack {
        BookmarksView()
    }
}
