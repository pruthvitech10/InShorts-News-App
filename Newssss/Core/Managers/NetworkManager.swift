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
        // Optimized URLSession configuration for speed
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15 // Faster timeout
        configuration.timeoutIntervalForResource = 30
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.httpMaximumConnectionsPerHost = 6 // Parallel requests
        configuration.waitsForConnectivity = true
        configuration.urlCache = URLCache(
            memoryCapacity: 100 * 1024 * 1024, // 100 MB - more memory cache
            diskCapacity: 200 * 1024 * 1024,   // 200 MB - more disk cache
            diskPath: "news_api_cache"
        )
        
        self.session = URLSession(configuration: configuration)
        
        // Optimized JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func fetch<T: Decodable>(url: URL) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(NSError(domain: "Invalid response", code: -1))
            }
            
            // Fast path for success
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    throw NetworkError.rateLimitExceeded
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            // Fast decode
            return try decoder.decode(T.self, from: data)
            
        } catch let error as DecodingError {
            Logger.error("Decode error: \(error)", category: .network)
            throw NetworkError.decodingError
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    // Optimized retry with faster backoff
    func fetchWithRetry<T: Decodable>(url: URL, maxRetries: Int = 2) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await fetch(url: url)
            } catch let error as NetworkError {
                lastError = error
                
                // Don't retry client errors or rate limits
                switch error {
                case .serverError(let code) where (400...499).contains(code),
                     .rateLimitExceeded,
                     .decodingError:
                    throw error
                default:
                    break
                }
                
                // Fast exponential backoff: 0.5s, 1s
                if attempt < maxRetries {
                    let delay = UInt64(pow(1.5, Double(attempt)) * 500_000_000)
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "Unknown error", code: -1))
    }
}
