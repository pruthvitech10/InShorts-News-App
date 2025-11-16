//
//  AppConfig.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation
import UIKit

// App configuration and API keys

struct AppConfig {
    // API key management
    // API Keys are now managed through a simple, robust rotation service.
    // Add multiple keys for each service in APIKeyRotationService.swift to automatically
    // handle rate limits and key expiration. This provides a seamless experience
    // without needing daily manual updates.
    
    // GNews.io (free tier: 100 requests/day, NO credit card required)
    // 🔗 Get your free API key at: https://gnews.io/
    static func getGNewsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getGNewsKey()
    }
    
    // NewsData.io (free tier: 500 requests/day, 10 articles per request)
    // 🔗 Get your free API key at: https://newsdata.io/register
    static func getNewsDataIOKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsDataIOKey()
    }
    
    // NewsAPI.org (free tier: 100 requests/day, development only)
    // 🔗 Get your free API key at: https://newsapi.org/register
    static let newsAPIBaseURL = "https://newsapi.org/v2"
    static func getNewsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsAPIKey()
    }
    
    // RapidAPI (from rapidapi.com)
    // 🔗 Get your free API key at: https://rapidapi.com/hub
    // This key can be used to access multiple news APIs.
    static func getRapidAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getRapidAPIKey()
    }
    
    // RapidAPI News API Settings
    static let rapidAPIHost = "real-time-news-data.p.rapidapi.com"
    static let rapidAPIBaseURL = "https://real-time-news-data.p.rapidapi.com"
    
    // Using premium news APIs for best content quality
    static let enabledAPIs: [NewsAPIProvider] = [
        .guardian,      // Premium journalism (5,000 req/day)
        .nyTimes,       // World-class journalism (4,000 req/day)
        .reddit,        // Viral content (60 req/min)
        .hackerNews,    // Tech news (unlimited)
        .currents,      // Global news (600 req/day)
        .mediaStack,    // 7,500+ sources (500 req/month)
        .gnews,         // Global news (100 req/day)
        .newsDataIO,    // Diverse sources (500 req/day)
        .newsAPI,       // Breaking news (100 req/day)
        .newsDataHub    // Additional coverage (1,000 req/day)
    ]
    
    // NewsDataHub API (from newsdatahub.com)
    // 🔗 Get your free API key at: https://newsdatahub.com/dashboards
    static func getNewsDataHubAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsDataHubKey()
    }
    
    // The Guardian API (Premium quality journalism)
    // 🔗 Get your free API key at: https://open-platform.theguardian.com/access/
    // Free tier: 5,000 requests/day (very generous!)
    static func getGuardianAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getGuardianKey()
    }
    
    // Hacker News API (No key needed!)
    // Free tier: UNLIMITED
    // Tech community's favorite news source
    // API Docs: https://github.com/HackerNews/API
    static let hackerNewsEnabled = true
    
    // Reddit API (No key needed for read-only!)
    // Free tier: 60 requests/minute
    // Viral, trending content from communities
    // API Docs: https://www.reddit.com/dev/api/
    static let redditEnabled = true
    
    // New York Times API (Premium journalism)
    // Free tier: 4,000 requests/day
    // Get your free API key at: https://developer.nytimes.com/get-started
    static func getNYTimesAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNYTimesKey()
    }
    
    // Currents API (Real-time global news)
    // Free tier: 600 requests/day
    // Get your free API key at: https://currentsapi.services/en/register
    static func getCurrentsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getCurrentsKey()
    }
    
    // MediaStack API (7,500+ sources)
    // Free tier: 500 requests/month
    // Get your free API key at: https://mediastack.com/product
    static func getMediaStackAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getMediaStackKey()
    }
    
    // API fetching strategy
    // Set `fetchFromAllAPIs` to `true` to fetch from all configured APIs simultaneously.
    // This provides maximum content diversity and freshness.
    static let fetchFromAllAPIs = true
    
    // General app settings
    static let defaultCategory = "general"
    static let articlesPerPage = 10
    // Cache articles for 24 hours to minimize API calls and stay within free tier limits.
    // Set to 60 seconds for testing to see fresh news
    static let cacheExpirationTime: TimeInterval = 60 // 60 seconds for testing
    
    // News freshness - only show articles from last 48 hours
    // This keeps content relevant without being too strict
    static let maximumArticleAge: TimeInterval = 48 * 60 * 60 // 48 hours
    static let preferredArticleAge: TimeInterval = 24 * 60 * 60  // 24 hours for "fresh" badge
    
    // UI settings
    static let animationDuration: Double = 0.3
    static let cardCornerRadius: CGFloat = 12
    static let defaultPadding: CGFloat = 16
    
    // Rate limiting
    static let maxConcurrentRequests = 3
    static let requestTimeout: TimeInterval = 30
    static let retryAttempts = 2
    static let retryDelay: TimeInterval = 1.0
}

// Available news API providers

enum NewsAPIProvider: String, CaseIterable {
    case guardian     // The Guardian (Premium)
    case nyTimes      // New York Times (Premium)
    case reddit       // Reddit (Viral)
    case hackerNews   // Hacker News (Tech)
    case currents     // Currents API (Global)
    case mediaStack   // MediaStack (7,500+ sources)
    case newsAPI      // NewsAPI.org
    case newsDataIO   // NewsData.io
    case gnews        // GNews.io
    case newsDataHub  // NewsDataHub.com
    case rapidAPI     // RapidAPI.com
    case all          // Fetch from all enabled APIs
    
    var displayName: String {
        switch self {
        case .guardian: return "The Guardian"
        case .nyTimes: return "New York Times"
        case .reddit: return "Reddit"
        case .hackerNews: return "Hacker News"
        case .currents: return "Currents API"
        case .mediaStack: return "MediaStack"
        case .newsAPI: return "NewsAPI"
        case .newsDataIO: return "NewsData.io"
        case .gnews: return "GNews"
        case .newsDataHub: return "NewsDataHub"
        case .rapidAPI: return "RapidAPI"
        case .all: return "All Sources"
        }
    }
    
    var dailyLimit: Int {
        switch self {
        case .guardian: return 5000
        case .nyTimes: return 4000
        case .reddit: return 86400 // 60 req/min
        case .hackerNews: return 999999 // Unlimited
        case .currents: return 600
        case .mediaStack: return 17 // 500/month ≈ 17/day
        case .newsAPI: return 100
        case .newsDataIO: return 500
        case .gnews: return 100
        case .newsDataHub: return 1000
        case .rapidAPI: return 100
        case .all: return 0
        }
    }
    
    var baseURL: String {
        switch self {
        case .guardian: return "https://content.guardianapis.com"
        case .nyTimes: return "https://api.nytimes.com/svc"
        case .reddit: return "https://www.reddit.com"
        case .hackerNews: return "https://hacker-news.firebaseio.com/v0"
        case .currents: return "https://api.currentsapi.services/v1"
        case .mediaStack: return "http://api.mediastack.com/v1"
        case .newsAPI: return AppConfig.newsAPIBaseURL
        case .newsDataIO: return "https://newsdata.io/api/1"
        case .gnews: return "https://gnews.io/api/v4"
        case .newsDataHub: return "https://api.newsdatahub.com/v1"
        case .rapidAPI: return AppConfig.rapidAPIBaseURL
        case .all: return ""
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .guardian, .nyTimes, .reddit, .hackerNews, .currents, .mediaStack:
            return true
        default:
            return false
        }
    }
    
    var badge: String? {
        switch self {
        case .guardian: return "⭐ Premium"
        case .nyTimes: return "🏆 NYT"
        case .reddit: return "🔥 Viral"
        case .hackerNews: return "💻 Tech"
        case .currents: return "🌍 Global"
        case .mediaStack: return "📰 News"
        default: return nil
        }
    }
}

// API error types

enum APIError: LocalizedError {
    case noAPIKey
    case rateLimitExceeded
    case invalidResponse
    case networkError(Error)
    case allAPIsFailed
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key available. Please configure your API keys."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .allAPIsFailed:
            return "Unable to fetch news from any source. Please check your connection."
        }
    }
}

// Helper methods

extension AppConfig {
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
