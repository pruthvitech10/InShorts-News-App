//
//  CurrentsAPIService.swift
//  Newssss
//
//  Currents API integration - Real-time news from 90+ countries
//  Free tier: 600 requests/day
//  Get your free API key: https://currentsapi.services/en/register
//  Created on 16 November 2025.
//

import Foundation

// MARK: - Currents Response Models

struct CurrentsResponse: Codable {
    let status: String
    let news: [CurrentsArticle]
}

struct CurrentsArticle: Codable {
    let id: String
    let title: String
    let description: String
    let url: String
    let author: String?
    let image: String?
    let language: String
    let category: [String]
    let published: String
}

// MARK: - Currents API Service

class CurrentsAPIService {
    static let shared = CurrentsAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://api.currentsapi.services/v1"
    
    private init() {}
    
    // MARK: - Fetch Latest News
    
    /// Fetch latest news from Currents API
    func fetchLatestNews(
        language: String = "en",
        country: String? = nil,
        category: String? = nil,
        limit: Int = 20
    ) async throws -> [Article] {
        
        let apiKey = try await AppConfig.getCurrentsAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/latest-news")
        var queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "language", value: language)
        ]
        
        if let country = country {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        #if DEBUG
        let maskedURL = SecurityUtil.maskURL(url)
        ErrorLogger.logInfo("Fetching from Currents: \(maskedURL)", context: "CurrentsAPIService")
        #endif
        
        let response: CurrentsResponse = try await networkManager.fetch(url: url)
        
        Logger.debug("✅ Received \(response.news.count) articles from Currents API", category: .network)
        
        let articles = response.news.prefix(limit).compactMap { convertToArticle($0) }
        return articles
    }
    
    // MARK: - Fetch by Category
    
    /// Fetch news by category
    func fetchByCategory(
        _ category: NewsCategory,
        language: String = "en",
        limit: Int = 20
    ) async throws -> [Article] {
        
        let currentsCategory = mapCategoryToCurrents(category)
        return try await fetchLatestNews(
            language: language,
            category: currentsCategory,
            limit: limit
        )
    }
    
    // MARK: - Search News
    
    /// Search news on Currents API
    func searchNews(
        query: String,
        language: String = "en",
        limit: Int = 20
    ) async throws -> [Article] {
        
        guard !query.isEmpty else {
            throw NetworkError.invalidRequest
        }
        
        let apiKey = try await AppConfig.getCurrentsAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "apiKey", value: apiKey),
            URLQueryItem(name: "keywords", value: query),
            URLQueryItem(name: "language", value: language)
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        let response: CurrentsResponse = try await networkManager.fetch(url: url)
        
        let articles = response.news.prefix(limit).compactMap { convertToArticle($0) }
        return articles
    }
    
    // MARK: - Private Helper Methods
    
    private func convertToArticle(_ currentsArticle: CurrentsArticle) -> Article? {
        let source = Source(
            id: "currents-\(currentsArticle.language)",
            name: "Currents API"
        )
        
        return Article(
            source: source,
            author: currentsArticle.author,
            title: currentsArticle.title,
            description: currentsArticle.description,
            url: currentsArticle.url,
            urlToImage: currentsArticle.image,
            publishedAt: currentsArticle.published,
            content: currentsArticle.description
        )
    }
    
    private func mapCategoryToCurrents(_ category: NewsCategory) -> String {
        switch category {
        case .general:
            return "general"
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
            return "general"
        }
    }
}

// MARK: - Currents Categories

extension CurrentsAPIService {
    /// Available Currents API categories
    static let categories = [
        "regional",
        "technology",
        "lifestyle",
        "business",
        "general",
        "programming",
        "science",
        "entertainment",
        "world",
        "sports",
        "finance",
        "academia",
        "politics",
        "health",
        "opinion",
        "food",
        "game"
    ]
    
    /// Supported languages
    static let languages = [
        "en", "ar", "de", "es", "fr", "he", "it", "nl", "no", "pt", "ru", "sv", "zh"
    ]
    
    /// Supported countries
    static let countries = [
        "US", "GB", "DE", "FR", "IT", "ES", "PT", "NL", "SE", "NO", "DK", "FI",
        "AU", "CA", "IN", "JP", "CN", "BR", "MX", "AR"
    ]
}
