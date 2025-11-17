//
//  ArticleCardView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI


struct ArticleCardView: View {
    let article: Article
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageUrl = article.urlToImage,
               let url = URL(string: imageUrl),
               !imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        // Always return a View. Do logging via a modifier to avoid returning Void from the ViewBuilder.
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo").foregroundColor(.gray))
                            .onAppear {
                                #if DEBUG
                                print("[ArticleCardView] Failed to load image: \(imageUrl)")
                                #endif
                            }
                    @unknown default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            }
            
            // Debug logging must not be a standalone statement inside a ViewBuilder branch.
            // Use a background/onAppear modifier so the branch still returns a View.
            Color.clear
                .frame(height: 0)
                .onAppear {
                    #if DEBUG
                    if article.urlToImage == nil || article.urlToImage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                        print("[ArticleCardView] No valid image URL for article: \(article.title)")
                    }
                    #endif
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                if let description = article.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                HStack {
                    // Source name
                    Text(article.source.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Published time - show both relative and exact
                    if let date = article.publishedDate {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(date.timeAgoDisplay())
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                            
                            // Exact date/time from RSS feed
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("Just now")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .cardStyle()
    }
}
