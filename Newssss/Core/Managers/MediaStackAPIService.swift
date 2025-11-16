//
//  MediaStackAPIService.swift
//  Newssss
//
//  MediaStack API integration - 7,500+ news sources worldwide
//  Free tier: 500 requests/month (16-17 per day)
//  Get your free API key: https://mediastack.com/product
//  Created on 16 November 2025.
//

import Foundation

// MARK: - MediaStack Response Models

struct MediaStackResponse: Codable {
    let pagination: MediaStackPagination
    let data: [MediaStackArticle]
}

struct MediaStackPagination: Codable {
    let limit: Int
    let offset: Int
    let count: Int
    let total: Int
}

struct MediaStackArticle: Codable {
    let author: String?
    let title: String
    let description: String?
    let url: String
    let source: String
    let image: String?
    let category: String
    let language: String
    let country: String
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case author, title, description, url, source, image, category, language, country
        case publishedAt = "published_at"
    }
}

// MARK: - MediaStack API Service

class MediaStackAPIService {
    static let shared = MediaStackAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "http://api.mediastack.com/v1"
    
    private init() {}
    
    // MARK: - Fetch Latest News
    
    /// Fetch latest news from MediaStack
    func fetchLatestNews(
        countries: String? = nil,
        categories: String? = nil,
        languages: String = "en",
        limit: Int = 25
    ) async throws -> [Article] {
        
        let apiKey = try await AppConfig.getMediaStackAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/news")
        var queryItems = [
            URLQueryItem(name: "access_key", value: apiKey),
            URLQueryItem(name: "languages", value: languages),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "sort", value: "published_desc")
        ]
        
        if let countries = countries {
            queryItems.append(URLQueryItem(name: "countries", value: countries))
        }
        
        if let categories = categories {
            queryItems.append(URLQueryItem(name: "categories", value: categories))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        #if DEBUG
        let maskedURL = SecurityUtil.maskURL(url)
        ErrorLogger.logInfo("Fetching from MediaStack: \(maskedURL)", context: "MediaStackAPIService")
        #endif
        
        let response: MediaStackResponse = try await networkManager.fetch(url: url)
        
        Logger.debug("✅ Received \(response.data.count) articles from MediaStack", category: .network)
        
        return response.data.compactMap { convertToArticle($0) }
    }
    
    // MARK: - Fetch by Category
    
    /// Fetch news by category
    func fetchByCategory(
        _ category: NewsCategory,
        countries: String? = nil,
        limit: Int = 25
    ) async throws -> [Article] {
        
        let mediastackCategory = mapCategoryToMediaStack(category)
        return try await fetchLatestNews(
            countries: countries,
            categories: mediastackCategory,
            limit: limit
        )
    }
    
    // MARK: - Fetch by Country
    
    /// Fetch news for specific country
    func fetchByCountry(
        country: String,
        category: NewsCategory? = nil,
        limit: Int = 25
    ) async throws -> [Article] {
        
        let categories = category.map { mapCategoryToMediaStack($0) }
        return try await fetchLatestNews(
            countries: country,
            categories: categories,
            limit: limit
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func convertToArticle(_ mediastackArticle: MediaStackArticle) -> Article? {
        let source = Source(
            id: "mediastack-\(mediastackArticle.source)",
            name: mediastackArticle.source
        )
        
        return Article(
            source: source,
            author: mediastackArticle.author,
            title: mediastackArticle.title,
            description: mediastackArticle.description,
            url: mediastackArticle.url,
            urlToImage: mediastackArticle.image,
            publishedAt: mediastackArticle.publishedAt,
            content: mediastackArticle.description
        )
    }
    
    private func mapCategoryToMediaStack(_ category: NewsCategory) -> String {
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

// MARK: - MediaStack Categories

extension MediaStackAPIService {
    /// Available MediaStack categories
    static let categories = [
        "general",
        "business",
        "entertainment",
        "health",
        "science",
        "sports",
        "technology"
    ]
    
    /// Supported languages (ISO 639-1)
    static let languages = [
        "ar", "de", "en", "es", "fr", "he", "it", "nl", "no", "pt", "ru", "se", "zh"
    ]
    
    /// Supported countries (ISO 3166-1 alpha-2)
    static let countries = [
        "us", "gb", "de", "fr", "it", "es", "pt", "nl", "se", "no", "dk", "fi",
        "au", "ca", "in", "jp", "cn", "br", "mx", "ar", "ae", "sa", "eg"
    ]
}
