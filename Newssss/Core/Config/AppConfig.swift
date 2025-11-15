//
//  AppConfig.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation
import UIKit

// MARK: - AppConfig

struct AppConfig {
    // MARK: - API Configuration
    // API Keys are now managed through a simple, robust rotation service.
    // Add multiple keys for each service in APIKeyRotationService.swift to automatically
    // handle rate limits and key expiration. This provides a seamless experience
    // without needing daily manual updates.
    
    // MARK: - GNews.io (free tier: 100 requests/day, NO credit card required)
    // 🔗 Get your free API key at: https://gnews.io/
    static func getGNewsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getGNewsKey()
    }
    
    // MARK: - NewsData.io (free tier: 500 requests/day, 10 articles per request)
    // 🔗 Get your free API key at: https://newsdata.io/register
    static func getNewsDataIOKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsDataIOKey()
    }
    
    // MARK: - NewsAPI.org (free tier: 100 requests/day, development only)
    // 🔗 Get your free API key at: https://newsapi.org/register
    static let newsAPIBaseURL = "https://newsapi.org/v2"
    static func getNewsAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsAPIKey()
    }
    
    // MARK: - RapidAPI (from rapidapi.com)
    // 🔗 Get your free API key at: https://rapidapi.com/hub
    // This key can be used to access multiple news APIs.
    static func getRapidAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getRapidAPIKey()
    }
    
    // RapidAPI News API Settings
    static let rapidAPIHost = "real-time-news-data.p.rapidapi.com"
    static let rapidAPIBaseURL = "https://real-time-news-data.p.rapidapi.com"
    
    // MARK: - Enabled APIs
    /// List of enabled API providers in order of preference
    /// RapidAPI disabled due to rate limit (429 error)
    static let enabledAPIs: [NewsAPIProvider] = [
        .gnews,
        .newsDataIO,
        .newsAPI,
        .newsDataHub
        // .rapidAPI  // Disabled - rate limit exceeded
    ]
    
    // MARK: - NewsDataHub API (from newsdatahub.com)
    // 🔗 Get your free API key at: https://newsdatahub.com/dashboards
    static func getNewsDataHubAPIKey() async throws -> String {
        try await APIKeyRotationService.shared.getNewsDataHubKey()
    }
    
    // MARK: - API Strategy
    // Set `fetchFromAllAPIs` to `true` to fetch from all configured APIs simultaneously.
    // This provides maximum content diversity and freshness.
    static let fetchFromAllAPIs = true
    
    // MARK: - App Settings
    static let defaultCategory = "general"
    static let articlesPerPage = 10
    // Cache articles for 24 hours to minimize API calls and stay within free tier limits.
    // Set to 60 seconds for testing to see fresh news
    static let cacheExpirationTime: TimeInterval = 60 // 60 seconds for testing
    
    // MARK: - News Freshness Settings
    // Show news from the last 7 days to ensure we always have content
    static let maximumArticleAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    static let preferredArticleAge: TimeInterval = 24 * 60 * 60  // 24 hours (for "fresh" indicator)
    
    // MARK: - UI Configuration
    static let animationDuration: Double = 0.3
    static let cardCornerRadius: CGFloat = 12
    static let defaultPadding: CGFloat = 16
    
    // MARK: - Rate Limiting
    static let maxConcurrentRequests = 3
    static let requestTimeout: TimeInterval = 30
    static let retryAttempts = 2
    static let retryDelay: TimeInterval = 1.0
}

// MARK: - NewsAPIProvider

enum NewsAPIProvider: String, CaseIterable {
    case newsAPI      // NewsAPI.org
    case newsDataIO   // NewsData.io
    case gnews        // GNews.io
    case newsDataHub  // NewsDataHub.com
    case rapidAPI     // RapidAPI.com
    case all          // Fetch from all enabled APIs
    
    var displayName: String {
        switch self {
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
        case .newsAPI: return AppConfig.newsAPIBaseURL
        case .newsDataIO: return "https://newsdata.io/api/1"
        case .gnews: return "https://gnews.io/api/v4"
        case .newsDataHub: return "https://api.newsdatahub.com/v1"
        case .rapidAPI: return AppConfig.rapidAPIBaseURL
        case .all: return ""
        }
    }
}

// MARK: - API Error Types

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

// MARK: - API Configuration Extension

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
