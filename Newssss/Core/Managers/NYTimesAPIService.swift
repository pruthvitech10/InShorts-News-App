//
//  NYTimesAPIService.swift
//  Newssss
//
//  New York Times API integration - World-class journalism
//  Free tier: 4,000 requests/day (500 per day per API)
//  Get your free API key: https://developer.nytimes.com/get-started
//  Created on 16 November 2025.
//

import Foundation

// MARK: - NYTimes Response Models

struct NYTimesResponse: Codable {
    let status: String
    let copyright: String
    let numResults: Int
    let results: [NYTimesArticle]
    
    enum CodingKeys: String, CodingKey {
        case status, copyright
        case numResults = "num_results"
        case results
    }
}

struct NYTimesArticle: Codable {
    let uri: String
    let url: String
    let title: String
    let abstract: String
    let byline: String?
    let publishedDate: String
    let section: String
    let subsection: String?
    let multimedia: [NYTimesMultimedia]?
    
    enum CodingKeys: String, CodingKey {
        case uri, url, title, abstract, byline, section, subsection, multimedia
        case publishedDate = "published_date"
    }
}

struct NYTimesMultimedia: Codable {
    let url: String
    let format: String
    let height: Int
    let width: Int
    let type: String
    let caption: String?
}

// MARK: - NYTimes Top Stories Response

struct NYTimesTopStoriesResponse: Codable {
    let status: String
    let copyright: String
    let numResults: Int
    let results: [NYTimesTopStory]
    
    enum CodingKeys: String, CodingKey {
        case status, copyright
        case numResults = "num_results"
        case results
    }
}

struct NYTimesTopStory: Codable {
    let section: String
    let subsection: String?
    let title: String
    let abstract: String
    let url: String
    let byline: String?
    let publishedDate: String
    let multimedia: [NYTimesMultimedia]?
    
    enum CodingKeys: String, CodingKey {
        case section, subsection, title, abstract, url, byline, multimedia
        case publishedDate = "published_date"
    }
}

// MARK: - NYTimes API Service

class NYTimesAPIService {
    static let shared = NYTimesAPIService()
    
    private let networkManager = NetworkManager.shared
    private let baseURL = "https://api.nytimes.com/svc"
    
    private init() {}
    
    // MARK: - Fetch Top Stories
    
    /// Fetch top stories from NYTimes
    func fetchTopStories(
        section: String = "home",
        limit: Int = 20
    ) async throws -> [Article] {
        
        let apiKey = try await AppConfig.getNYTimesAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/topstories/v2/\(section).json")
        components?.queryItems = [
            URLQueryItem(name: "api-key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        #if DEBUG
        let maskedURL = SecurityUtil.maskURL(url)
        ErrorLogger.logInfo("Fetching from NYTimes: \(maskedURL)", context: "NYTimesAPIService")
        #endif
        
        let response: NYTimesTopStoriesResponse = try await networkManager.fetch(url: url)
        
        Logger.debug("✅ Received \(response.results.count) articles from NYTimes", category: .network)
        
        let articles = response.results.prefix(limit).compactMap { convertTopStoryToArticle($0) }
        return articles
    }
    
    // MARK: - Fetch by Category
    
    /// Fetch news by category
    func fetchByCategory(
        _ category: NewsCategory,
        limit: Int = 20
    ) async throws -> [Article] {
        
        let section = mapCategoryToSection(category)
        return try await fetchTopStories(section: section, limit: limit)
    }
    
    // MARK: - Search Articles
    
    /// Search articles on NYTimes
    func searchArticles(
        query: String,
        page: Int = 0,
        limit: Int = 20
    ) async throws -> [Article] {
        
        guard !query.isEmpty else {
            throw NetworkError.invalidRequest
        }
        
        let apiKey = try await AppConfig.getNYTimesAPIKey()
        
        var components = URLComponents(string: "\(baseURL)/search/v2/articlesearch.json")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "api-key", value: apiKey),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "sort", value: "newest")
        ]
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        struct SearchResponse: Codable {
            let response: SearchResponseData
        }
        
        struct SearchResponseData: Codable {
            let docs: [SearchDoc]
        }
        
        struct SearchDoc: Codable {
            let webUrl: String
            let headline: Headline
            let abstract: String?
            let byline: Byline?
            let pubDate: String
            let multimedia: [SearchMultimedia]?
            
            struct Headline: Codable {
                let main: String
            }
            
            struct Byline: Codable {
                let original: String?
            }
            
            struct SearchMultimedia: Codable {
                let url: String
            }
            
            enum CodingKeys: String, CodingKey {
                case webUrl = "web_url"
                case headline, abstract, byline, multimedia
                case pubDate = "pub_date"
            }
        }
        
        let searchResponse: SearchResponse = try await networkManager.fetch(url: url)
        
        return searchResponse.response.docs.prefix(limit).compactMap { doc in
            let source = Source(id: "nytimes", name: "The New York Times")
            
            let imageUrl = doc.multimedia?.first.map { "https://www.nytimes.com/\($0.url)" }
            
            return Article(
                source: source,
                author: doc.byline?.original,
                title: doc.headline.main,
                description: doc.abstract,
                url: doc.webUrl,
                urlToImage: imageUrl,
                publishedAt: doc.pubDate,
                content: doc.abstract
            )
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func convertTopStoryToArticle(_ story: NYTimesTopStory) -> Article? {
        let source = Source(
            id: "nytimes",
            name: "The New York Times"
        )
        
        // Get best quality image
        let imageUrl = story.multimedia?.first(where: { $0.format == "superJumbo" })?.url
            ?? story.multimedia?.first?.url
        
        // Clean byline
        let author = story.byline?.replacingOccurrences(of: "By ", with: "")
        
        return Article(
            source: source,
            author: author,
            title: story.title,
            description: story.abstract,
            url: story.url,
            urlToImage: imageUrl,
            publishedAt: story.publishedDate,
            content: story.abstract
        )
    }
    
    private func mapCategoryToSection(_ category: NewsCategory) -> String {
        switch category {
        case .general:
            return "home"
        case .politics:
            return "politics"
        case .business:
            return "business"
        case .technology:
            return "technology"
        case .entertainment:
            return "arts"
        case .sports:
            return "sports"
        case .science:
            return "science"
        case .health:
            return "health"
        default:
            return "home"
        }
    }
}

// MARK: - NYTimes Sections

extension NYTimesAPIService {
    /// Available NYTimes sections
    enum Section: String, CaseIterable {
        case home
        case arts
        case automobiles
        case books
        case business
        case fashion
        case food
        case health
        case insider
        case magazine
        case movies
        case nyregion
        case obituaries
        case opinion
        case politics
        case realestate
        case science
        case sports
        case sundayreview
        case technology
        case theater
        case tmagazine
        case travel
        case upshot
        case us
        case world
        
        var displayName: String {
            rawValue.capitalized
        }
    }
}
