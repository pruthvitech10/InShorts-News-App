//
//  NetworkManager.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation


// MARK: - NetworkError

public enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int)
    case rateLimitExceeded
    case apiKeyMissing(apiName: String)
    case timeout // <-- Added timeout case
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .rateLimitExceeded:
            return "API rate limit reached. Please try again later or add fresh API keys in AppConfig.swift"
        case .apiKeyMissing(let apiName):
            return "API key for \(apiName) is missing. Please add it to Config.xcconfig."
        case .timeout:
            return "The request timed out. Please try again."
        case .unknown(let error):
            return error.localizedDescription
        @unknown default:
            return "An unknown network error occurred."
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .invalidURL:
            return "Something went wrong with the request"
        case .noData:
            return "Unable to fetch news. Please check your internet connection"
        case .decodingError:
            return "Unable to process news data"
        case .serverError(let statusCode) where statusCode == 429:
            return "Too many requests. The app will use cached news until rate limits reset"
        case .serverError:
            return "News service is temporarily unavailable"
        case .rateLimitExceeded:
            return "Daily API limit reached. Showing cached news until tomorrow"
        case .apiKeyMissing(let apiName):
            return "Configuration error: API key for \(apiName) is missing."
        case .timeout:
            return "The request timed out. Please try again."
        case .unknown:
            return "Unable to load news. Please try again"
        @unknown default:
            return "An unknown network error occurred."
        }
    }
}

// MARK: - NetworkManager

class NetworkManager {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        // Configure URLSession with timeout and caching
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB
            diskCapacity: 100 * 1024 * 1024,  // 100 MB
            diskPath: "news_api_cache"
        )
        
        self.session = URLSession(configuration: configuration)
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func fetch<T: Decodable>(url: URL) async throws -> T {
        Logger.debug("Fetching: \(url.absoluteString)", category: .network)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }
            
            Logger.debug("HTTP \(httpResponse.statusCode)", category: .network)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                #if DEBUG
                if let errorBody = String(data: data, encoding: .utf8) {
                    ErrorLogger.logWarning("Server error: \(errorBody)", context: "NetworkManager")
                }
                #endif
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
            
        } catch let error as DecodingError {
            ErrorLogger.log(error, context: "NetworkManager Decoding")
            #if DEBUG
            // Only log raw data in debug builds
            if let rawString = String(data: try await session.data(from: url).0, encoding: .utf8) {
                ErrorLogger.logWarning("Raw response: \(rawString.prefix(500))", context: "NetworkManager")
            }
            #endif
            throw NetworkError.decodingError
            
        } catch {
            ErrorLogger.log(error, context: "NetworkManager Request")
            throw NetworkError.unknown(error)
        }
    }
    
    // Note: Add retry logic for transient failures
    func fetchWithRetry<T: Decodable>(url: URL, maxRetries: Int = 2) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await fetch(url: url)
            } catch let error as NetworkError {
                lastError = error
                
                // Don't retry client errors (4xx)
                if case .serverError(let code) = error, (400...499).contains(code) {
                    throw error
                }
                
                // Exponential backoff
                if attempt < maxRetries {
                    let delay = UInt64(pow(2.0, Double(attempt)) * 1_000_000_000) // 1s, 2s, 4s
                    try await Task.sleep(nanoseconds: delay)
                    ErrorLogger.logWarning("Retry \(attempt + 1)/\(maxRetries)", context: "NetworkManager")
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "Unknown error", code: -1))
    }
}
