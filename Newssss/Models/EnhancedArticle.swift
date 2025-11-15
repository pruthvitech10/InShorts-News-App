//
//  EnhancedArticle.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation


// MARK: - EnhancedArticle

struct EnhancedArticle: Identifiable, Codable {
    let id: UUID
    let article: Article
    let aiSummary: String?
    let keyPoints: [String]?
    let sentiment: String?
    let readingTime: Int? // in seconds
    let fetchedAt: Date
    let sourceType: SourceType?
    
    init(article: Article, aiSummary: String? = nil, keyPoints: [String]? = nil, sentiment: String? = nil, readingTime: Int? = nil, fetchedAt: Date = Date(), sourceType: SourceType? = nil) {
        self.id = UUID()
        self.article = article
        self.aiSummary = aiSummary
        self.keyPoints = keyPoints
        self.sentiment = sentiment
        self.readingTime = readingTime
        self.fetchedAt = fetchedAt
        self.sourceType = sourceType
    }
}

// MARK: - SourceType

enum SourceType: String, Codable {
    case cnn = "CNN"
    case bbc = "BBC"
    case reuters = "Reuters"
    case apNews = "AP News"
    case techCrunch = "TechCrunch"
    case theVerge = "The Verge"
    case other = "Other"
    
    var displayName: String {
        rawValue
    }
    
    static func from(sourceName: String) -> SourceType {
        let lowercased = sourceName.lowercased()
        if lowercased.contains("cnn") {
            return .cnn
        } else if lowercased.contains("bbc") {
            return .bbc
        } else if lowercased.contains("reuters") {
            return .reuters
        } else if lowercased.contains("ap") || lowercased.contains("associated press") {
            return .apNews
        } else if lowercased.contains("techcrunch") {
            return .techCrunch
        } else if lowercased.contains("verge") {
            return .theVerge
        } else {
            return .other
        }
    }
}
