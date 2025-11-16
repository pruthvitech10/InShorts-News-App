//
//  RSSFetchService.swift
//  Newssss
//
//  NO CACHE - Direct network fetching only
//  Always fetches fresh data from RSS feeds
//

import Foundation

class RSSFetchService {
    static let shared = RSSFetchService()
    
    private init() {
        Logger.debug("🌐 RSS Fetch Service initialized (NO CACHE)", category: .general)
    }
    
    /// Fetch RSS data - ALWAYS FRESH FROM NETWORK
    func fetchRSSData(url: String) async throws -> Data {
        Logger.debug("⬇️ Fetching FRESH from network: \(url)", category: .network)
        
        guard let feedURL = URL(string: url) else {
            throw NSError(domain: "RSSFetch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: feedURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 30
        
        // Add headers to appear as a normal browser
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "RSSFetch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "RSSFetch", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }
        
        return data
    }
}
