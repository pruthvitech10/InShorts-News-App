//
//  RedditAPIService.swift
//  Newssss
//
//  Reddit API integration - Viral, trending content
//  Free tier: 60 requests/minute (NO credit card required)
//  Get your free API credentials: https://www.reddit.com/prefs/apps
//  Created on 16 November 2025.
//

import Foundation

// MARK: - Reddit Response Models

struct RedditResponse: Codable {
    let kind: String
    let data: RedditData
}

struct RedditData: Codable {
    let children: [RedditPost]
    let after: String?
    let before: String?
}

struct RedditPost: Codable {
    let kind: String
    let data: RedditPostData
}

struct RedditPostData: Codable {
    let id: String
    let title: String
    let author: String
    let subreddit: String
    let url: String
    let permalink: String
    let selftext: String?
    let thumbnail: String?
    let preview: RedditPreview?
    let score: Int
    let numComments: Int
    let created: Double
    let domain: String
    let isVideo: Bool?
    let postHint: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, author, subreddit, url, permalink, selftext, thumbnail, preview, score, domain, created
        case numComments = "num_comments"
        case isVideo = "is_video"
        case postHint = "post_hint"
    }
}

struct RedditPreview: Codable {
    let images: [RedditImage]?
}

struct RedditImage: Codable {
    let source: RedditImageSource
}

struct RedditImageSource: Codable {
    let url: String
    let width: Int
    let height: Int
}

// MARK: - Reddit API Service

class RedditAPIService {
    static let shared = RedditAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://www.reddit.com"
    
    // User agent is required by Reddit API
    private let userAgent = "iOS:com.newssss.app:v1.0.0 (by /u/newsapp)"
    
    private init() {}
    
    // MARK: - Fetch from Subreddit
    
    /// Fetch hot posts from a subreddit
    func fetchHotPosts(
        subreddit: String = "worldnews",
        limit: Int = 25,
        after: String? = nil
    ) async throws -> [Article] {
        
        var components = URLComponents(string: "\(baseURL)/r/\(subreddit)/hot.json")
        var queryItems = [
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        if let after = after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        Logger.debug("📡 Fetching hot posts from r/\(subreddit)", category: .network)
        
        let response: RedditResponse = try await networkManager.fetchWithRequest(request)
        
        let articles = response.data.children.compactMap { convertToArticle($0.data) }
        
        Logger.debug("✅ Received \(articles.count) posts from r/\(subreddit)", category: .network)
        
        return articles
    }
    
    // MARK: - Fetch Top Posts
    
    /// Fetch top posts from a subreddit
    func fetchTopPosts(
        subreddit: String = "worldnews",
        timeframe: RedditTimeframe = .day,
        limit: Int = 25
    ) async throws -> [Article] {
        
        var components = URLComponents(string: "\(baseURL)/r/\(subreddit)/top.json")
        components?.queryItems = [
            URLQueryItem(name: "t", value: timeframe.rawValue),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let response: RedditResponse = try await networkManager.fetchWithRequest(request)
        return response.data.children.compactMap { convertToArticle($0.data) }
    }
    
    // MARK: - Fetch Multiple Subreddits
    
    /// Fetch news from multiple news subreddits
    func fetchNewsFromMultipleSubreddits(limit: Int = 30) async throws -> [Article] {
        let subreddits = ["worldnews", "news", "technology", "science", "business"]
        
        var allArticles: [Article] = []
        
        // Fetch from each subreddit
        for subreddit in subreddits {
            do {
                let articles = try await fetchHotPosts(subreddit: subreddit, limit: 6)
                allArticles.append(contentsOf: articles)
            } catch {
                Logger.error("Failed to fetch from r/\(subreddit): \(error.localizedDescription)", category: .network)
            }
        }
        
        // Sort by score (upvotes)
        let sortedArticles = allArticles.sorted { ($0.metadata?["score"] as? Int ?? 0) > ($1.metadata?["score"] as? Int ?? 0) }
        
        return Array(sortedArticles.prefix(limit))
    }
    
    // MARK: - Fetch by Category
    
    /// Fetch Reddit posts by news category
    func fetchByCategory(_ category: NewsCategory, limit: Int = 20) async throws -> [Article] {
        let subreddit = mapCategoryToSubreddit(category)
        return try await fetchHotPosts(subreddit: subreddit, limit: limit)
    }
    
    // MARK: - Private Helper Methods
    
    private func convertToArticle(_ post: RedditPostData) -> Article? {
        // Skip self posts without external links (unless they're very popular)
        if post.domain.contains("self.") && post.score < 1000 {
            return nil
        }
        
        // Create source
        let source = Source(
            id: "reddit-\(post.subreddit)",
            name: "r/\(post.subreddit)"
        )
        
        // Get image URL
        var imageUrl: String?
        if let preview = post.preview?.images?.first?.source.url {
            imageUrl = preview.replacingOccurrences(of: "&amp;", with: "&")
        } else if let thumbnail = post.thumbnail, thumbnail.starts(with: "http") {
            imageUrl = thumbnail
        }
        
        // Create description with Reddit metrics
        var description = ""
        description += "⬆️ \(formatScore(post.score)) upvotes"
        description += " • 💬 \(formatNumber(post.numComments)) comments"
        
        if let selftext = post.selftext, !selftext.isEmpty {
            description += "\n\n\(selftext.prefix(200))"
            if selftext.count > 200 {
                description += "..."
            }
        }
        
        // Convert Unix timestamp to ISO8601
        let date = Date(timeIntervalSince1970: post.created)
        let publishedAt = ISO8601DateFormatter().string(from: date)
        
        // Use Reddit discussion URL if it's a self post
        let articleUrl = post.domain.contains("self.") ? "https://reddit.com\(post.permalink)" : post.url
        
        // Create article with metadata
        var article = Article(
            source: source,
            author: "u/\(post.author)",
            title: post.title,
            description: description,
            url: articleUrl,
            urlToImage: imageUrl,
            publishedAt: publishedAt,
            content: post.selftext
        )
        
        // Add Reddit-specific metadata
        article.metadata = [
            "score": post.score,
            "comments": post.numComments,
            "subreddit": post.subreddit,
            "reddit_id": post.id,
            "permalink": post.permalink
        ]
        
        return article
    }
    
    private func mapCategoryToSubreddit(_ category: NewsCategory) -> String {
        switch category {
        case .general:
            return "news"
        case .politics:
            return "politics"
        case .business:
            return "business"
        case .technology:
            return "technology"
        case .entertainment:
            return "entertainment"
        case .sports:
            return "sports"
        case .science:
            return "science"
        case .health:
            return "health"
        default:
            return "worldnews"
        }
    }
    
    private func formatScore(_ score: Int) -> String {
        if score >= 10000 {
            return String(format: "%.1fk", Double(score) / 1000.0)
        } else if score >= 1000 {
            return String(format: "%.1fk", Double(score) / 1000.0)
        }
        return "\(score)"
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}

// MARK: - Reddit Timeframe

extension RedditAPIService {
    enum RedditTimeframe: String {
        case hour
        case day
        case week
        case month
        case year
        case all
    }
}

// MARK: - Popular News Subreddits

extension RedditAPIService {
    static let newsSubreddits = [
        "worldnews",      // International news
        "news",           // US & World news
        "technology",     // Tech news
        "science",        // Science news
        "business",       // Business news
        "politics",       // Political news
        "UpliftingNews",  // Positive news
        "nottheonion",    // Satirical-seeming real news
        "TrueReddit",     // In-depth articles
        "neutralnews"     // Fact-based news
    ]
}

// MARK: - NetworkManager Extension for Custom Requests

extension NetworkManager {
    func fetchWithRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}
