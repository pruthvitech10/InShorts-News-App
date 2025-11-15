//
//  NewsDataIOService.swift
//  DailyNews
//
//  Created on 4 November 2025.
//

import Foundation


// NewsDataIOResponse

struct NewsDataIOResponse: Codable {
    let status: String
    let totalResults: Int?
    let results: [NewsDataIOArticle]?
    let nextPage: String?
}

// NewsDataIOErrorResponse

struct NewsDataIOErrorResponse: Codable {
    let status: String
    let results: NewsDataIOErrorDetail?
    
    struct NewsDataIOErrorDetail: Codable {
        let message: String?
        let code: String?
    }
}

// NewsDataIOArticle

struct NewsDataIOArticle: Codable {
    let articleId: String?
    let title: String
    let link: String
    let keywords: [String]?
    let creator: [String]?
    let videoUrl: String?
    let description: String?
    let content: String?
    let pubDate: String
    let imageUrl: String?
    let sourceId: String?
    let sourcePriority: Int?
    let sourceName: String?
    let sourceUrl: String?
    let sourceIcon: String?
    let language: String?
    let country: [String]?
    let category: [String]?
    let aiTag: String?
    let sentiment: String?
    let sentimentStats: String?
    let aiRegion: String?
    let aiOrg: String?
    
    enum CodingKeys: String, CodingKey {
        case articleId = "article_id"
        case title
        case link
        case keywords
        case creator
        case videoUrl = "video_url"
        case description
        case content
        case pubDate = "pubDate"
        case imageUrl = "image_url"
        case sourceId = "source_id"
        case sourcePriority = "source_priority"
        case sourceName = "source_name"
        case sourceUrl = "source_url"
        case sourceIcon = "source_icon"
        case language
        case country
        case category
        case aiTag = "ai_tag"
        case sentiment
        case sentimentStats = "sentiment_stats"
        case aiRegion = "ai_region"
        case aiOrg = "ai_org"
    }
}

// NewsDataIOService

class NewsDataIOService {
    static let shared = NewsDataIOService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://newsdata.io/api/1"
    
    private init() {}
    
    // Fetch Latest News
    /// Fetches latest news from NewsData.io
    /// - Parameters:
    ///   - category: News category (e.g., business, technology, sports)
    ///   - country: Country code (e.g., us, gb, in) - optional
    ///   - language: Language code (e.g., en, es, fr) - optional
    ///   - query: Search query - optional
    ///   - page: Next page token from previous response - optional
    /// - Returns: Array of Article objects
    func fetchLatestNews(
        category: NewsCategory? = nil,
        country: String? = "it",
        language: String? = "it",
        query: String? = nil,
        page: String? = nil
    ) async throws -> [Article] {
        let maxRetries = 3
        
        for attempt in 0..<maxRetries {
            do {
                let apiKey = try await AppConfig.getNewsDataIOKey()

                #if DEBUG
                let keyIdentifier = "\(apiKey.prefix(4))...\(apiKey.suffix(4))"
                ErrorLogger.logInfo("NewsDataIOService: Using key \(keyIdentifier)", context: "NewsDataIOService")
                #endif
                
                var components = URLComponents(string: "\(baseURL)/news")
                var queryItems = [URLQueryItem(name: "apikey", value: apiKey)]
                
                if let category = category, let newsDataCategory = category.newsDataIOCategory {
                    queryItems.append(URLQueryItem(name: "category", value: newsDataCategory))
                }
                if let country = country { queryItems.append(URLQueryItem(name: "country", value: country)) }
                if let language = language { queryItems.append(URLQueryItem(name: "language", value: language)) }
                if let query = query { queryItems.append(URLQueryItem(name: "q", value: query)) }
                if let page = page { queryItems.append(URLQueryItem(name: "page", value: page)) }
                
                components?.queryItems = queryItems
                
                guard let url = components?.url else { throw NetworkError.invalidURL }

                #if DEBUG
                ErrorLogger.logInfo("NewsDataIOService: Fetching URL: \(url.absoluteString.replacingOccurrences(of: apiKey, with: "***"))", context: "NewsDataIOService")
                #endif
                
                let response: NewsDataIOResponse = try await networkManager.fetch(url: url)
                
                if response.status != "success" {
                    throw NewsDataIOError.invalidResponse
                }
                
                guard let results = response.results else { return [] }
                
                return results.compactMap { convertToArticle($0) }
                
            } catch let error as NetworkError {
                switch error {
                case .serverError(let statusCode) where [401, 429].contains(statusCode):
                    ErrorLogger.logWarning("NewsData.io key failed (status: \(statusCode)). Rotating. Attempt \(attempt + 1)/\(maxRetries)", context: "NewsDataIOService")
                    await APIKeyRotationService.shared.rotateNewsDataIOKey()
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
    /// Search for specific news articles
    func searchNews(query: String, language: String? = "en", page: String? = nil) async throws -> [Article] {
        guard !query.isEmpty else {
            throw NewsDataIOError.emptyQuery
        }
        
        return try await fetchLatestNews(
            category: nil,
            country: nil,
            language: language,
            query: query,
            page: page
        )
    }
    
    // Fetch by Multiple Categories
    /// Fetch news from multiple categories
    func fetchMultipleCategories(categories: [NewsCategory], country: String? = "it") async throws -> [Article] {
        var allArticles: [Article] = []
        
        for category in categories {
            do {
                let articles = try await fetchLatestNews(category: category, country: country)
                allArticles.append(contentsOf: articles)
            } catch {
                Logger.error("❌ Failed to fetch \(category.displayName): \(error.localizedDescription)", category: .network)
                // Continue with other categories even if one fails
            }
        }
        
        // Remove duplicates based on URL
        let uniqueArticles = Array(Set(allArticles))
        
        Logger.debug("✅ Fetched total of \(uniqueArticles.count) unique articles from \(categories.count) categories", category: .network)
        
        return uniqueArticles
    }
    
    // Private Helper Methods
    
    /// Converts a NewsData.io article to our internal Article model
    private func convertToArticle(_ newsDataArticle: NewsDataIOArticle) -> Article? {
        // Create Source object
        let source = Source(
            id: newsDataArticle.sourceId,
            name: newsDataArticle.sourceName ?? "Unknown Source"
        )
        
        // Get author from creators array
        let author = newsDataArticle.creator?.first
        
        // Convert pubDate to ISO8601 format (NewsData.io uses a different format)
        let publishedAt = convertDateToISO8601(newsDataArticle.pubDate)
        
        // Create Article
        return Article(
            source: source,
            author: author,
            title: newsDataArticle.title,
            description: newsDataArticle.description,
            url: newsDataArticle.link,
            urlToImage: newsDataArticle.imageUrl,
            publishedAt: publishedAt,
            content: newsDataArticle.content
        )
    }
    
    /// Converts NewsData.io date format to ISO8601
    /// NewsData.io format: "2025-11-04 12:30:45"
    private func convertDateToISO8601(_ dateString: String) -> String {
        // NewsData.io typically returns dates in format: "YYYY-MM-DD HH:MM:SS"
        // We need to convert to ISO8601: "YYYY-MM-DDTHH:MM:SSZ"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        if let _ = formatter.date(from: dateString) {
            let isoFormatter = ISO8601DateFormatter()
            return isoFormatter.string(from: formatter.date(from: dateString)!)
        }
        
        // If parsing fails, try ISO8601 format (in case API already returns it)
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            return dateString
        }
        
        // Fallback: return current date in ISO8601 format
        Logger.error("❌ Failed to parse date: \(dateString)", category: .network)
        return ISO8601DateFormatter().string(from: Date())
    }
}

// NewsDataIOError

enum NewsDataIOError: Error, LocalizedError {
    case missingAPIKey
    case emptyQuery
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "NewsData.io API Key is missing. Please add your API key in AppConfig.swift"
        case .emptyQuery:
            return "Search query cannot be empty"
        case .invalidResponse:
            return "Invalid response from NewsData.io"
        }
    }
}
