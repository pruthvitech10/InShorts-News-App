//
//  NewsAPIService.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation


// NewsAPIService

class NewsAPIService {
    static let shared = NewsAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = AppConfig.newsAPIBaseURL
    
    private init() {}
    
    // Fetch Top Headlines
    func fetchTopHeadlines(category: NewsCategory?, page: Int, pageSize: Int) async throws -> [Article] {
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getNewsAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("NewsAPIService: Using key identifier \(keyIdentifier)", context: "NewsAPIService")
                #endif
                
                var components = URLComponents(string: "\(baseURL)/top-headlines")
                var queryItems = [
                    URLQueryItem(name: "apiKey", value: apiKey),
                    URLQueryItem(name: "country", value: "it"),
                    URLQueryItem(name: "pageSize", value: "\(pageSize)")
                ]
                
                if let category = category {
                    queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
                }
                
                if page > 1 {
                    queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
                }
                
                components?.queryItems = queryItems
                
                guard let url = components?.url else {
                    throw NetworkError.invalidURL
                }

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "NewsAPIService")
                #endif
                
                let response: NewsResponse = try await networkManager.fetch(url: url)
                return response.articles
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("NewsAPI key failed (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "NewsAPIService")
                    await APIKeyRotationService.shared.rotateNewsAPIKey()
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw NetworkError.rateLimitExceeded
    }
    
    // Search Articles
    func searchArticles(query: String, page: Int, pageSize: Int) async throws -> [Article] {
        guard !query.isEmpty else {
            throw NewsAPIError.emptyQuery
        }
        
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getNewsAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("NewsAPIService: Using key identifier \(keyIdentifier) for search", context: "NewsAPIService")
                #endif
                
                var components = URLComponents(string: "\(baseURL)/everything")
                components?.queryItems = [
                    URLQueryItem(name: "apiKey", value: apiKey),
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "language", value: "it"),
                    URLQueryItem(name: "sortBy", value: "publishedAt"),
                    URLQueryItem(name: "pageSize", value: "\(pageSize)"),
                    URLQueryItem(name: "page", value: "\(page)")
                ]
                
                guard let url = components?.url else {
                    throw NetworkError.invalidURL
                }

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "NewsAPIService")
                #endif
                
                let response: NewsResponse = try await networkManager.fetch(url: url)
                return response.articles
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("NewsAPI key failed (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "NewsAPIService")
                    await APIKeyRotationService.shared.rotateNewsAPIKey()
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw NetworkError.rateLimitExceeded
    }
    
    // Fetch Sources
    func fetchSources(category: NewsCategory? = nil) async throws -> [Source] {
        let apiKey = try await AppConfig.getNewsAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/sources")
        var queryItems = [URLQueryItem(name: "apiKey", value: apiKey)]
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category.rawValue))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        let response: SourcesResponse = try await networkManager.fetch(url: url)
        return response.sources
    }
}

extension NewsAPIService: NewsAPIServiceProtocol {}

// SourcesResponse

public struct SourcesResponse: Codable {
    let status: String
    let sources: [Source]
}

// NewsAPIError

enum NewsAPIError: Error, LocalizedError {
    case missingAPIKey
    case emptyQuery
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key is missing. Please add your News API key in AppConfig.swift"
        case .emptyQuery:
            return "Search query cannot be empty"
        }
    }
}
