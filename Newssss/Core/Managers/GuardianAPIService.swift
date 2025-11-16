//
//  GuardianAPIService.swift
//  Newssss
//
//  The Guardian API integration - Premium quality journalism
//  Free tier: 5,000 requests/day (very generous!)
//  Get your free API key: https://open-platform.theguardian.com/access/
//  Created on 16 November 2025.
//

import Foundation

// MARK: - Guardian Response Models

struct GuardianResponse: Codable {
    let response: GuardianResponseData
}

struct GuardianResponseData: Codable {
    let status: String
    let total: Int
    let results: [GuardianArticle]
}

struct GuardianArticle: Codable {
    let id: String
    let type: String
    let sectionId: String
    let sectionName: String
    let webPublicationDate: String
    let webTitle: String
    let webUrl: String
    let apiUrl: String
    let fields: GuardianFields?
    let pillarName: String?
    
    struct GuardianFields: Codable {
        let headline: String?
        let trailText: String?
        let thumbnail: String?
        let bodyText: String?
        let byline: String?
        let wordcount: String?
    }
}

// MARK: - Guardian API Service

class GuardianAPIService {
    static let shared = GuardianAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://content.guardianapis.com"
    
    private init() {}
    
    // MARK: - Fetch Latest News
    
    /// Fetch latest news from The Guardian
    func fetchLatestNews(
        section: String? = nil,
        pageSize: Int = 20,
        orderBy: String = "newest"
    ) async throws -> [Article] {
        
        let apiKey = try await AppConfig.getGuardianAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/search")
        var queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "show-fields", value: "headline,trailText,thumbnail,bodyText,byline,wordcount"),
            URLQueryItem(name: "page-size", value: "\(pageSize)"),
            URLQueryItem(name: "order-by", value: orderBy)
        ]
        
        if let section = section {
            queryItems.append(URLQueryItem(name: "section", value: section))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        #if DEBUG
        let maskedURL = SecurityUtil.maskURL(url)
        ErrorLogger.logInfo("Fetching from Guardian: \(maskedURL)", context: "GuardianAPIService")
        #endif
        
        let response: GuardianResponse = try await networkManager.fetch(url: url)
        
        Logger.debug("✅ Received \(response.response.results.count) articles from The Guardian", category: .network)
        
        return response.response.results.compactMap { convertToArticle($0) }
    }
    
    // MARK: - Fetch by Category
    
    /// Fetch news by category
    func fetchByCategory(
        _ category: NewsCategory,
        pageSize: Int = 20
    ) async throws -> [Article] {
        
        let section = mapCategoryToSection(category)
        return try await fetchLatestNews(section: section, pageSize: pageSize)
    }
    
    // MARK: - Search Articles
    
    /// Search articles on The Guardian
    func searchArticles(
        query: String,
        pageSize: Int = 20
    ) async throws -> [Article] {
        
        guard !query.isEmpty else {
            throw NetworkError.invalidRequest
        }
        
        let apiKey = try await AppConfig.getGuardianAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "show-fields", value: "headline,trailText,thumbnail,bodyText,byline,wordcount"),
            URLQueryItem(name: "page-size", value: "\(pageSize)"),
            URLQueryItem(name: "order-by", value: "relevance")
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        let response: GuardianResponse = try await networkManager.fetch(url: url)
        return response.response.results.compactMap { convertToArticle($0) }
    }
    
    // MARK: - Private Helper Methods
    
    private func convertToArticle(_ guardianArticle: GuardianArticle) -> Article? {
        let source = Source(
            id: "the-guardian",
            name: "The Guardian"
        )
        
        // Use fields if available, otherwise use main properties
        let title = guardianArticle.fields?.headline ?? guardianArticle.webTitle
        let description = guardianArticle.fields?.trailText
        let imageUrl = guardianArticle.fields?.thumbnail
        let author = guardianArticle.fields?.byline
        let content = guardianArticle.fields?.bodyText
        
        return Article(
            source: source,
            author: author,
            title: title,
            description: description,
            url: guardianArticle.webUrl,
            urlToImage: imageUrl,
            publishedAt: guardianArticle.webPublicationDate,
            content: content
        )
    }
    
    private func mapCategoryToSection(_ category: NewsCategory) -> String? {
        switch category {
        case .general:
            return nil // All sections
        case .politics:
            return "politics"
        case .business:
            return "business"
        case .technology:
            return "technology"
        case .entertainment:
            return "culture"
        case .sports:
            return "sport"
        case .science:
            return "science"
        case .health:
            return "society" // Guardian uses 'society' for health/social issues
        default:
            return nil
        }
    }
}

// MARK: - Guardian Sections

extension GuardianAPIService {
    /// Available Guardian sections
    enum Section: String {
        case news
        case politics
        case business
        case technology = "technology"
        case culture
        case sport
        case science
        case society
        case world
        case uk = "uk-news"
        case us = "us-news"
        case environment
        case education
        case media
        case law
        
        var displayName: String {
            rawValue.capitalized
        }
    }
}
