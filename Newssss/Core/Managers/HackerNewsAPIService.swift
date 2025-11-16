//
//  HackerNewsAPIService.swift
//  Newssss
//
//  Hacker News API integration - Tech community's favorite
//  Free tier: UNLIMITED (Firebase-based)
//  No API key needed!
//  API Docs: https://github.com/HackerNews/API
//  Created on 16 November 2025.
//

import Foundation
import UIKit

// MARK: - Hacker News Models

struct HackerNewsItem: Codable {
    let id: Int
    let type: String
    let by: String?
    let time: Int
    let text: String?
    let url: String?
    let title: String?
    let score: Int?
    let descendants: Int? // Number of comments
    let kids: [Int]? // Comment IDs
}

// MARK: - Hacker News API Service

class HackerNewsAPIService {
    static let shared = HackerNewsAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://hacker-news.firebaseio.com/v0"
    
    private init() {}
    
    // MARK: - Fetch Top Stories
    
    /// Fetch top stories from Hacker News
    func fetchTopStories(limit: Int = 30) async throws -> [Article] {
        // Get top story IDs
        let url = URL(string: "\(baseURL)/topstories.json")!
        let storyIds: [Int] = try await networkManager.fetch(url: url)
        
        // Fetch details for top stories (limited by limit parameter)
        let limitedIds = Array(storyIds.prefix(limit))
        
        Logger.debug("📡 Fetching \(limitedIds.count) top stories from Hacker News", category: .network)
        
        var articles: [Article] = []
        
        // Fetch stories in parallel (but limit concurrency)
        await withTaskGroup(of: Article?.self) { group in
            for id in limitedIds {
                group.addTask {
                    try? await self.fetchStory(id: id)
                }
            }
            
            for await article in group {
                if let article = article {
                    articles.append(article)
                }
            }
        }
        
        Logger.debug("✅ Received \(articles.count) articles from Hacker News", category: .network)
        
        return articles
    }
    
    // MARK: - Fetch New Stories
    
    /// Fetch newest stories from Hacker News
    func fetchNewStories(limit: Int = 30) async throws -> [Article] {
        let url = URL(string: "\(baseURL)/newstories.json")!
        let storyIds: [Int] = try await networkManager.fetch(url: url)
        
        let limitedIds = Array(storyIds.prefix(limit))
        
        var articles: [Article] = []
        
        await withTaskGroup(of: Article?.self) { group in
            for id in limitedIds {
                group.addTask {
                    try? await self.fetchStory(id: id)
                }
            }
            
            for await article in group {
                if let article = article {
                    articles.append(article)
                }
            }
        }
        
        return articles
    }
    
    // MARK: - Fetch Best Stories
    
    /// Fetch best stories (highest scored) from Hacker News
    func fetchBestStories(limit: Int = 30) async throws -> [Article] {
        let url = URL(string: "\(baseURL)/beststories.json")!
        let storyIds: [Int] = try await networkManager.fetch(url: url)
        
        let limitedIds = Array(storyIds.prefix(limit))
        
        var articles: [Article] = []
        
        await withTaskGroup(of: Article?.self) { group in
            for id in limitedIds {
                group.addTask {
                    try? await self.fetchStory(id: id)
                }
            }
            
            for await article in group {
                if let article = article {
                    articles.append(article)
                }
            }
        }
        
        return articles
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchStory(id: Int) async throws -> Article? {
        let url = URL(string: "\(baseURL)/item/\(id).json")!
        let item: HackerNewsItem = try await networkManager.fetch(url: url)
        
        // Only convert stories (not comments, jobs, etc.)
        guard item.type == "story" else { return nil }
        
        return convertToArticle(item)
    }
    
    private func convertToArticle(_ hnItem: HackerNewsItem) -> Article? {
        // HN stories must have a title
        guard let title = hnItem.title else { return nil }
        
        // Create source
        let source = Source(
            id: "hacker-news",
            name: "Hacker News"
        )
        
        // Convert Unix timestamp to ISO8601 string
        let date = Date(timeIntervalSince1970: TimeInterval(hnItem.time))
        let publishedAt = ISO8601DateFormatter().string(from: date)
        
        // Use HN discussion URL if no external URL
        let articleUrl = hnItem.url ?? "https://news.ycombinator.com/item?id=\(hnItem.id)"
        
        // Create description with score and comment count
        var description = ""
        if let score = hnItem.score {
            description += "⬆️ \(score) points"
        }
        if let comments = hnItem.descendants {
            if !description.isEmpty { description += " • " }
            description += "💬 \(comments) comments"
        }
        if let text = hnItem.text {
            if !description.isEmpty { description += "\n\n" }
            description += text.htmlToString()
        }
        
        return Article(
            source: source,
            author: hnItem.by,
            title: title,
            description: description.isEmpty ? nil : description,
            url: articleUrl,
            urlToImage: nil, // HN doesn't provide images
            publishedAt: publishedAt,
            content: hnItem.text?.htmlToString()
        )
    }
}

// MARK: - String Extension for HTML

private extension String {
    func htmlToString() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }
        
        return attributedString.string
    }
}
