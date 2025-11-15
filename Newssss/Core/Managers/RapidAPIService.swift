//
//  RapidAPIService.swift
//  Newssss
//
//  RapidAPI integration for accessing real-time news data
//  Using Real-Time News Data API from RapidAPI
//

import Foundation


// RapidAPINewsResponse

struct RapidAPINewsResponse: Codable {
    let status: String?
    let news: [RapidAPIArticle]?
}

// RapidAPIArticle

struct RapidAPIArticle: Codable {
    let title: String
    let description: String?
    let link: String?
    let url: String?
    let source: String?
    let image: String?
    let pubDate: String?
    let published_date: String?
    let author: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case link
        case url
        case source
        case image
        case pubDate = "pubDate"
        case published_date
        case author
    }
    
    // Helper to get the actual URL
    var articleURL: String {
        return url ?? link ?? ""
    }
    
    // Helper to get the actual date
    var articleDate: String {
        return pubDate ?? published_date ?? ISO8601DateFormatter().string(from: Date())
    }
}

// RapidAPIService

class RapidAPIService {
    static let shared = RapidAPIService()
    
    private let baseURL = "https://real-time-news-data.p.rapidapi.com"
    private let rapidAPIHost = "real-time-news-data.p.rapidapi.com"
    
    private init() {}
    
    // Fetch Latest News
    /// Fetch latest news from RapidAPI Real-Time News Data
    func fetchLatestNews(
        category: NewsCategory? = nil,
        country: String = "IT",
        language: String = "it",
        limit: Int = 10
    ) async throws -> [Article] {
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getRapidAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("RapidAPIService: Using key \(keyIdentifier)", context: "RapidAPIService")
                #endif
                
                var query = "news"
                if let category = category {
                    query = category.rapidAPIQuery
                }
                
                let normalizedCountry = country.uppercased()
                let normalizedLanguage = language.lowercased()

                var components = URLComponents(string: "\(baseURL)/search")!
                components.queryItems = [
                    URLQueryItem(name: "query", value: query),
                    URLQueryItem(name: "limit", value: String(limit)),
                    URLQueryItem(name: "time_published", value: "anytime"),
                    URLQueryItem(name: "country", value: normalizedCountry),
                    URLQueryItem(name: "lang", value: normalizedLanguage)
                ]
                
                guard let url = components.url else {
                    throw NetworkError.invalidURL
                }

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "RapidAPIService")
                #endif
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
                request.addValue(rapidAPIHost, forHTTPHeaderField: "X-RapidAPI-Host")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, ![200, 201, 204].contains(httpResponse.statusCode) {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                let decodedResponse = try JSONDecoder().decode(RapidAPINewsResponse.self, from: data)
                
                guard let newsArticles = decodedResponse.news else {
                    return []
                }
                
                return newsArticles.compactMap { convertToArticle($0, category: category) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("RapidAPI key failed (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "RapidAPIService")
                    await APIKeyRotationService.shared.rotateRapidAPIKey()
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
    /// Search news on RapidAPI
    func searchNews(
        query: String,
        country: String = "IT",
        language: String = "it",
        limit: Int = 20
    ) async throws -> [Article] {
        guard !query.isEmpty else {
            throw RapidAPIError.emptyQuery
        }
        
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getRapidAPIKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("RapidAPIService: Using key \(keyIdentifier) for search", context: "RapidAPIService")
                #endif
                
                let normalizedCountry = country.uppercased()
                let normalizedLanguage = language.lowercased()

                var components = URLComponents(string: "\(baseURL)/search")!
                components.queryItems = [
                    URLQueryItem(name: "query", value: query),
                    URLQueryItem(name: "limit", value: String(limit)),
                    URLQueryItem(name: "time_published", value: "anytime"),
                    URLQueryItem(name: "country", value: normalizedCountry),
                    URLQueryItem(name: "lang", value: normalizedLanguage)
                ]
                
                guard let url = components.url else {
                    throw NetworkError.invalidURL
                }

                #if DEBUG
                let maskedURL = SecurityUtil.maskURL(url)
                ErrorLogger.logInfo("Fetching: \(maskedURL)", context: "RapidAPIService")
                #endif
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.addValue(apiKey, forHTTPHeaderField: "X-RapidAPI-Key")
                request.addValue(rapidAPIHost, forHTTPHeaderField: "X-RapidAPI-Host")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse, ![200, 201, 204].contains(httpResponse.statusCode) {
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode)
                }
                
                let decodedResponse = try JSONDecoder().decode(RapidAPINewsResponse.self, from: data)
                
                guard let newsArticles = decodedResponse.news else {
                    return []
                }
                
                return newsArticles.compactMap { convertToArticle($0, category: nil) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("RapidAPI key failed during search (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "RapidAPIService")
                    await APIKeyRotationService.shared.rotateRapidAPIKey()
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw NetworkError.rateLimitExceeded
    }
    
    // Convert to Article
    private func convertToArticle(_ rapidArticle: RapidAPIArticle, category: NewsCategory?) -> Article? {
        // Validate required fields
        guard !rapidArticle.title.isEmpty else { return nil }
        guard !rapidArticle.articleURL.isEmpty else { return nil }
        
        // Parse date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var publishedAt = dateFormatter.date(from: rapidArticle.articleDate)
        
        // Try alternative format if first fails
        if publishedAt == nil {
            dateFormatter.formatOptions = [.withInternetDateTime]
            publishedAt = dateFormatter.date(from: rapidArticle.articleDate)
        }
        
        // Use current date as fallback
        let date = publishedAt ?? Date()
        
        // Create source
        let sourceName = rapidArticle.source ?? "RapidAPI News"
        let source = Source(id: nil, name: sourceName)
        
        // Create article
        return Article(
            source: source,
            author: rapidArticle.author,
            title: rapidArticle.title,
            description: rapidArticle.description,
            url: rapidArticle.articleURL,
            urlToImage: rapidArticle.image,
            publishedAt: ISO8601DateFormatter().string(from: date),
            content: rapidArticle.description
        )
    }
}

// RapidAPIError

enum RapidAPIError: Error, LocalizedError {
    case missingAPIKey
    case emptyQuery
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "RapidAPI Key is missing. Get your key from https://rapidapi.com/"
        case .emptyQuery:
            return "Search query cannot be empty"
        case .invalidResponse:
            return "Invalid response from RapidAPI"
        }
    }
}

// Category Extension
extension NewsCategory {
    var rapidAPIQuery: String {
        switch self {
        case .general: return "news"
        case .business: return "business"
        case .entertainment: return "entertainment"
        case .health: return "health"
        case .science: return "science"
        case .sports: return "sports"
        case .technology: return "technology"
        case .politics: return "politics"
        case .history: return "history"
        default: return "news"
        }
    }
}
