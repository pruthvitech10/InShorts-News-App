//
//  GNewsAPIService.swift
//  Newssss
//
//  GNews.io API integration (Free: 100 requests/day, NO credit card required)
//  Get your free API key: https://gnews.io/
//  Created on 6 November 2025.
//

import Foundation

// GNewsResponse

// : - GNews Response Models
struct GNewsResponse: Codable {
    let totalArticles: Int
    let articles: [GNewsArticle]
}

// GNewsArticle

struct GNewsArticle: Codable {
    let title: String
    let description: String
    let content: String
    let url: String
    let image: String?
    let publishedAt: String
    let source: GNewsSource
    
    struct GNewsSource: Codable {
        let name: String
        let url: String
    }
}

// GNewsAPIService

// : - GNews API Service
class GNewsAPIService {
    static let shared = GNewsAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://gnews.io/api/v4"
    
    private init() {}
    
    // : - Fetch Top Headlines
    func fetchTopHeadlines(
        category: NewsCategory? = nil,
        country: String = "it",
        language: String = "it",
        max: Int = 10
    ) async throws -> [Article] {
        
        let maxRetries = 3 // Allow retries for multiple keys
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getGNewsAPIKey()
                
                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("GNewsAPIService: Using key identifier \(keyIdentifier)", context: "GNewsAPIService")
                #endif

                var components = URLComponents(string: "\(baseURL)/top-headlines")
                var queryItems = [
                    URLQueryItem(name: "apikey", value: apiKey),
                    URLQueryItem(name: "lang", value: language),
                    URLQueryItem(name: "country", value: country),
                    URLQueryItem(name: "max", value: "\(max)")
                ]
                
                if let category = category, let gNewsCategory = category.gNewsCategory {
                    queryItems.append(URLQueryItem(name: "topic", value: gNewsCategory))
                }
                
                components?.queryItems = queryItems
                
                guard let url = components?.url else {
                    throw NetworkError.invalidURL
                }
                

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "GNewsAPIService")
                #endif

                Logger.debug("📡 Fetching from GNews API (Attempt \(attempt + 1))", category: .network)
                
                let response: GNewsResponse = try await networkManager.fetch(url: url)
                Logger.debug("✅ Received \(response.articles.count) articles from GNews", category: .network)
                return response.articles.map { convertToArticle($0) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 403, 429].contains(statusCode):
                    ErrorLogger.logWarning("GNews key failed (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "GNewsAPIService")
                    await APIKeyRotationService.shared.rotateGNewsKey()
                    // Loop will continue to the next attempt
                default:
                    throw error // Re-throw other network errors immediately
                }
            } catch {
                throw error // Re-throw non-network errors
            }
        }
        
        throw NetworkError.rateLimitExceeded // All keys failed
    }
    
    // : - Search Articles
    func searchArticles(
        query: String,
        language: String = "en",
        max: Int = 10
    ) async throws -> [Article] {
        
        guard !query.isEmpty else {
            throw GNewsAPIError.emptyQuery
        }
        
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getGNewsAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("GNewsAPIService: Using key identifier \(keyIdentifier) for search", context: "GNewsAPIService")
                #endif
                
                var components = URLComponents(string: "\(baseURL)/search")
                components?.queryItems = [
                    URLQueryItem(name: "q", value: query),
                    // Use the same parameter name as top-headlines endpoint
                    URLQueryItem(name: "apikey", value: apiKey),
                    URLQueryItem(name: "lang", value: language),
                    URLQueryItem(name: "max", value: "\(max)")
                ]
                
                guard let url = components?.url else {
                    throw NetworkError.invalidURL
                }


                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "GNewsAPIService")
                #endif
                
                let response: GNewsResponse = try await networkManager.fetch(url: url)
                return response.articles.map { convertToArticle($0) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 403, 429].contains(statusCode):
                    ErrorLogger.logWarning("GNews key failed during search (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "GNewsAPIService")
                    await APIKeyRotationService.shared.rotateGNewsKey()
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw NetworkError.rateLimitExceeded
    }
    
    // : - Private Helper Methods
    
    private func convertToArticle(_ gNewsArticle: GNewsArticle) -> Article {
        let source = Source(
            id: nil,
            name: gNewsArticle.source.name
        )
        
        return Article(
            source: source,
            author: gNewsArticle.source.name,
            title: gNewsArticle.title,
            description: gNewsArticle.description,
            url: gNewsArticle.url,
            urlToImage: gNewsArticle.image,
            publishedAt: gNewsArticle.publishedAt,
            content: gNewsArticle.content
        )
    }
}

// GNews Response Models

// : - GNews Error
enum GNewsAPIError: Error, LocalizedError {
    case missingAPIKey
    case emptyQuery
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "GNews API Key is missing. Get your free key at https://gnews.io/"
        case .emptyQuery:
            return "Search query cannot be empty"
        }
    }
}
