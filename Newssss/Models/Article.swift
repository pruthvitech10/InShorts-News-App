//
//  Article.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

// MARK: - Article
public struct Article: Codable, Identifiable, Hashable {
    public let id: UUID
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
    var aiSummary: String? // AI-generated summary (on-device)
    
    var publishedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: publishedAt) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: publishedAt) {
            return date
        }
        
        // Try with timezone
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.date(from: publishedAt)
    }
    
    /// Create a copy of the article with an AI summary
    nonisolated func withSummary(_ summary: String) -> Article {
        var copy = self
        copy.aiSummary = summary
        return copy
    }
    
    init(source: Source, author: String?, title: String, description: String?, url: String, urlToImage: String?, publishedAt: String, content: String?, aiSummary: String? = nil) {
        self.id = UUID()
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
        self.aiSummary = aiSummary
    }
    
    // Custom coding keys for API response
    enum CodingKeys: String, CodingKey {
        case source, author, title, description, url, urlToImage, publishedAt, content, aiSummary
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.source = try container.decode(Source.self, forKey: .source)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.url = try container.decode(String.self, forKey: .url)
        self.urlToImage = try container.decodeIfPresent(String.self, forKey: .urlToImage)
        self.publishedAt = try container.decode(String.self, forKey: .publishedAt)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.aiSummary = try container.decodeIfPresent(String.self, forKey: .aiSummary)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(urlToImage, forKey: .urlToImage)
        try container.encode(publishedAt, forKey: .publishedAt)
        try container.encodeIfPresent(content, forKey: .content)
        try container.encodeIfPresent(aiSummary, forKey: .aiSummary)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(title)
    }
    
    public static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.url == rhs.url && lhs.title == rhs.title
    }
}

// MARK: - Source
struct Source: Codable, Hashable {
    let id: String?
    let name: String
}
