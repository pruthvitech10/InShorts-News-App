//
//  Constants.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//  Additional configuration constants
//

import Foundation
import UIKit

// Constants

struct Constants {
    // API Keys
    
    /// GNews.io (free tier: 100 requests/day, NO credit card required)
    /// 🔗 Get your free API key at: https://gnews.io/
    static func getGNewsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getGNewsKey()
    }
    
    /// NewsData.io (free tier: 500 requests/day, 10 articles per request)
    /// 🔗 Get your free API key at: https://newsdata.io/register
    static func getNewsDataIOKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsDataIOKey()
    }
    
    /// NewsAPI.org (free tier: 100 requests/day, development only)
    /// 🔗 Get your free API key at: https://newsapi.org/register
    static func getNewsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsAPIKey()
    }
    
    /// RapidAPI (from rapidapi.com)
    /// 🔗 Get your free API key at: https://rapidapi.com/hub
    static func getRapidAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getRapidAPIKey()
    }
    
    /// NewsDataHub API (from newsdatahub.com)
    /// 🔗 Get your free API key at: https://newsdatahub.com/dashboards
    static func getNewsDataHubAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsDataHubKey()
    }
    
    // API Configuration
    
    struct API {
        static let newsAPIBaseURL = "https://newsapi.org/v2"
        static let rapidAPIHost = "real-time-news-data.p.rapidapi.com"
        static let rapidAPIBaseURL = "https://real-time-news-data.p.rapidapi.com"
        
        // Request Settings
        static let requestTimeout: TimeInterval = 30
        static let resourceTimeout: TimeInterval = 60
        static let apiCallTimeoutPerService: TimeInterval = 8
        
        // Rate Limiting
        static let maxConcurrentRequests = 3
        static let maxSimultaneousAPICalls = 1  // Sequential, not parallel
        static let retryAttempts = 2
        static let retryDelay: TimeInterval = 1.0
        
        // Content Settings
        static let articlesPerPage = 10
        static let defaultCategory = "general"
    }
    
    // API Strategy
    
    /// Set to `true` to fetch from all configured APIs simultaneously
    static let fetchFromAllAPIs = true
    
    /// Define the APIs you want to use
    static let enabledAPIs: [NewsAPIProvider] = [
        .rapidAPI,
        .newsDataHub,
        .gnews,
        .newsDataIO,
        .newsAPI
    ]
    
    // Cache Configuration
    
    struct Cache {
        static let expirationTime: TimeInterval = 3600  // 1 hour
        static let articleMaxAge: TimeInterval = 24 * 60 * 60  // 24 hours
        static let maxCacheSize = 50
        static let breakingNewsCacheDuration: TimeInterval = 300  // 5 minutes
        
        // Legacy compatibility (use articleMaxAge instead)
        @available(*, deprecated, renamed: "articleMaxAge")
        static let cacheExpirationTime: TimeInterval = 86400  // 24 hours
    }
    
    // News Freshness
    
    struct Article {
        static let maxAge: TimeInterval = 24 * 60 * 60  // 24 hours
        static let preferredAge: TimeInterval = 6 * 60 * 60  // 6 hours (for "fresh" indicator)
        static let minSummaryLength = 100
        static let minSentenceLength = 20
    }
    
    // UI Configuration
    
    struct UI {
        static let animationDuration: TimeInterval = 0.3
        static let cardCornerRadius: CGFloat = 24
        static let defaultPadding: CGFloat = 16
        static let swipeThreshold: CGFloat = 120
        
        // Bookmark Cards
        static let bookmarkCardImageWidth: CGFloat = 80
        static let bookmarkCardImageHeight: CGFloat = 80
    }
    
    // Search Configuration
    
    struct Search {
        static let minQueryLength = 2
        static let maxQueryLength = 200
        static let resultsLimit = 50
    }
    
    // Summarization
    
    struct Summarization {
        static let keywordCount = 10
        static let sentenceCount = 3
        static let positionWeight = 0.3
        static let lengthWeight = 0.2
        static let keywordWeight = 0.5
    }
}

// NewsAPIProvider
// NewsAPIProvider enum is defined in AppConfig.swift

// API Error Types
// APIError enum is defined in AppConfig.swift

// Constants Extensions

extension Constants {
    /// Check if any API keys are configured
    static var hasConfiguredAPIs: Bool {
        !enabledAPIs.isEmpty && enabledAPIs != [.all]
    }
    
    /// Get all active providers (excluding .all)
    static var activeProviders: [NewsAPIProvider] {
        enabledAPIs.filter { $0 != .all }
    }
    
    /// Calculate estimated daily request capacity across all APIs
    static var totalDailyCapacity: Int {
        activeProviders.reduce(0) { $0 + $1.dailyLimit }
    }
}
