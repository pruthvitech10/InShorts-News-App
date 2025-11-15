//
//  NewsDataHubAPIService.swift
//  Newssss
//
//  NewsDataHub API integration (from newsdatahub.com)
//  Get your free API key: https://newsdatahub.com/dashboards
//  Created on 10 November 2025.
//

import Foundation


// NewsDataHubResponse

struct NewsDataHubResponse: Codable {
    let status: String
    let totalResults: Int?
    let articles: [NewsDataHubArticle]
}

// NewsDataHubArticle

struct NewsDataHubArticle: Codable {
    let title: String
    let description: String?
    let content: String?
    let url: String
    let image: String?
    let publishedAt: String
    let source: NewsDataHubSource
    
    struct NewsDataHubSource: Codable {
        let name: String
        let url: String?
    }
}

// NewsDataHubAPIService

class NewsDataHubAPIService {
    static let shared = NewsDataHubAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://newsdatahub.com/v1"
    
    private init() {}
    
    // Fetch Latest News
    func fetchLatestNews(
        category: NewsCategory? = nil,
        country: String = "it",
        language: String = "it",
        limit: Int = 10
    ) async throws -> [Article] {
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getNewsDataHubAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("NewsDataHubAPIService: Using key identifier \(keyIdentifier)", context: "NewsDataHubAPIService")
                #endif
                
                var components = URLComponents(string: "\(baseURL)/news")
                var queryItems = [
                    URLQueryItem(name: "country", value: country),
                    URLQueryItem(name: "language", value: language),
                    URLQueryItem(name: "apikey", value: apiKey)
                ]
                
                if let category = category, let hubCategory = category.newsDataHubCategory {
                    queryItems.append(URLQueryItem(name: "category", value: hubCategory))
                }
                
                components?.queryItems = queryItems
                
                guard let url = components?.url else {
                    throw NetworkError.invalidURL
                }

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "NewsDataHubAPIService")
                #endif
                
                let response: NewsDataHubResponse = try await networkManager.fetch(url: url)
                
                guard response.status == "success" || response.status == "ok" else {
                    throw NewsDataHubAPIError.invalidResponse
                }
                
                return response.articles.prefix(limit).compactMap { convertToArticle($0) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("NewsDataHub key failed (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "NewsDataHubAPIService")
                    await APIKeyRotationService.shared.rotateNewsDataHubKey()
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw NetworkError.rateLimitExceeded
    }
    
    // Search News
    func searchNews(
        query: String,
        language: String = "en",
        limit: Int = 10
    ) async throws -> [Article] {
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getNewsDataHubAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("NewsDataHubAPIService: Using key identifier \(keyIdentifier) for search", context: "NewsDataHubAPIService")
                #endif
                
                var components = URLComponents(string: "\(baseURL)/search")
                components?.queryItems = [
                    URLQueryItem(name: "apikey", value: apiKey),
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "language", value: language)
                ]
                
                guard let url = components?.url else {
                    throw NetworkError.invalidURL
                }

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "NewsDataHubAPIService")
                #endif
                
                let response: NewsDataHubResponse = try await networkManager.fetch(url: url)
                
                guard response.status == "success" || response.status == "ok" else {
                    throw NewsDataHubAPIError.invalidResponse
                }
                
                return response.articles.prefix(limit).compactMap { convertToArticle($0) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("NewsDataHub key failed during search (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "NewsDataHubAPIService")
                    await APIKeyRotationService.shared.rotateNewsDataHubKey()
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw NetworkError.rateLimitExceeded
    }
    
    // Convert to Article Model
    private func convertToArticle(_ hubArticle: NewsDataHubArticle) -> Article? {
        // Parse date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let _ = dateFormatter.date(from: hubArticle.publishedAt) ?? Date()
        
        return Article(
            source: Source(id: nil, name: hubArticle.source.name),
            author: nil,
            title: hubArticle.title,
            description: hubArticle.description,
            url: hubArticle.url,
            urlToImage: hubArticle.image,
            publishedAt: hubArticle.publishedAt,
            content: hubArticle.content ?? hubArticle.description
        )
    }
}

// NewsDataHubAPIError

enum NewsDataHubAPIError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "NewsDataHub API key is missing. Please add it to AppConfig.swift"
        case .invalidResponse:
            return "Invalid response from NewsDataHub API"
        case .rateLimitExceeded:
            return "NewsDataHub API rate limit exceeded. Try again later."
        }
    }
}

// Category Extension for NewsDataHub
extension NewsCategory {
    var newsDataHubCategory: String? {
        switch self {
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
        case .history:
            return nil  // History is local-only
        case .forYou:
            return nil // 'forYou' is not supported by NewsDataHub API
        }
    }
}
