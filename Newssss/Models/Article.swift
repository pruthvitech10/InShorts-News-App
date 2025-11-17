//
//  Article.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

// Article
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
    var metadata: [String: String]?
    
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
    
    init(source: Source, author: String?, title: String, description: String?, url: String, urlToImage: String?, publishedAt: String, content: String?, metadata: [String: String]? = nil) {
        self.id = UUID()
        self.source = source
        self.author = author
        self.title = title
        self.description = description
        self.url = url
        self.urlToImage = urlToImage
        self.publishedAt = publishedAt
        self.content = content
        self.metadata = metadata
    }
    
    // Custom coding keys for API response
    enum CodingKeys: String, CodingKey {
        case source, author, title, description, url, urlToImage, publishedAt, publishedDate, content, metadata, category
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        
        // Handle source as either String or Source object
        if let sourceString = try? container.decode(String.self, forKey: .source) {
            // Firebase sends source as a string
            self.source = Source(id: nil, name: sourceString)
        } else {
            // Legacy format or other APIs might send it as an object
            self.source = try container.decode(Source.self, forKey: .source)
        }
        
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        
        // Handle url as either String or object
        if let urlString = try? container.decode(String.self, forKey: .url) {
            self.url = urlString
        } else if let urlDict = try? container.decode([String: String].self, forKey: .url),
                  let link = urlDict["href"] ?? urlDict["link"] {
            self.url = link
        } else {
            self.url = ""
        }
        
        self.urlToImage = try container.decodeIfPresent(String.self, forKey: .urlToImage)
        
        // Handle both publishedDate (Firebase) and publishedAt (standard)
        if let publishedDate = try? container.decode(String.self, forKey: .publishedDate) {
            self.publishedAt = publishedDate
        } else if let publishedAt = try? container.decode(String.self, forKey: .publishedAt) {
            self.publishedAt = publishedAt
        } else {
            self.publishedAt = ISO8601DateFormatter().string(from: Date())
        }
        
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
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
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(title)
    }
    
    public static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.url == rhs.url && lhs.title == rhs.title
    }
}

// Source
struct Source: Codable, Hashable {
    let id: String?
    let name: String
}
