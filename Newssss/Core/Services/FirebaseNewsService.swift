import Foundation

struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total_articles: Int
    let total_pages: Int
    let has_next: Bool
    let has_prev: Bool
}

struct FirebaseNewsResponse: Codable {
    let category: String
    let updated_at: String
    let articles: [FirebaseArticle]
    let shuffled: Bool?
    let timestamp: String?
    let total: Int?
    let pagination: PaginationInfo?
}

struct FirebaseArticle: Codable {
    let title: String
    let url: String
    let summary: String
    let image: String?
    let published_at: String
    let source: String?
}

class NewsCache {
    private let fileManager = FileManager.default
    private let cacheDir: URL
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDir = paths[0].appendingPathComponent("NewsCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
    
    func get(category: String) -> FirebaseNewsResponse? {
        let fileURL = cacheDir.appendingPathComponent("\(category).json")
        
        guard let data = try? Data(contentsOf: fileURL),
              let response = try? JSONDecoder().decode(FirebaseNewsResponse.self, from: data) else {
            return nil
        }
        
        return response
    }
    
    func save(category: String, response: FirebaseNewsResponse) {
        let fileURL = cacheDir.appendingPathComponent("\(category).json")
        
        if let data = try? JSONEncoder().encode(response) {
            try? data.write(to: fileURL)
        }
    }
    
    func clearAll() {
        try? fileManager.removeItem(at: cacheDir)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}

class FirebaseNewsService {
    static let shared = FirebaseNewsService()
    
    private let cache = NewsCache()
    private let baseURL = "https://us-central1-news-8b080.cloudfunctions.net/getShuffledNewsPaginated?category="
    
    private init() {
        guard FirebaseInitializer.shared.isReady else {
            Logger.debug("Firebase News Service init - Firebase not ready yet", category: .general)
            return
        }
        Logger.debug("Firebase News Service initialized", category: .general)
    }
    
    func fetchCategory(_ category: String) async throws -> [Article] {
        Logger.debug("Fetching \(category)...", category: .network)
        
        if !NetworkMonitor.shared.isConnected {
            Logger.debug("No internet connection", category: .network)
            throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])
        }

        do {
            let response = try await downloadFromFirebase(category)
            
            if let cached = cache.get(category: category),
               cached.updated_at == response.updated_at {
                Logger.debug("Cache is up-to-date", category: .network)
                return convertToArticles(cached.articles)
            }
            
            cache.save(category: category, response: response)
            Logger.debug("Downloaded \(response.articles.count) articles", category: .network)
            
            return convertToArticles(response.articles)
        } catch {
            Logger.debug("Fetch failed", category: .network)
            throw error
        }
    }
    
    func fetchAllCategories() async throws -> [String: [Article]] {
        Logger.debug("Fetching all categories...", category: .network)
        
        let categories = AppConstants.categories
        
        return try await withThrowingTaskGroup(of: (String, [Article]).self) { group in
            for category in categories {
                group.addTask {
                    let articles = try await self.fetchCategory(category)
                    return (category, articles)
                }
            }
            
            var results: [String: [Article]] = [:]
            for try await (category, articles) in group {
                results[category] = articles
            }
            
            let allArticles = results.values.flatMap { $0 }
            results["general"] = removeDuplicates(allArticles)
            
            Logger.debug("Fetched \(results.count) categories", category: .network)
            
            return results
        }
    }
    
    private func downloadFromFirebase(_ category: String) async throws -> FirebaseNewsResponse {
        let urlString = "\(baseURL)\(category)&page=1&limit=800"
        
        Logger.debug("Storage URL: \(urlString)", category: .network)
        
        guard let url = URL(string: urlString) else {
            Logger.debug("Invalid URL for category: \(category)", category: .network)
            throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.debug("No HTTP response for \(category)", category: .network)
                throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
            }
            
            Logger.debug("HTTP Status: \(httpResponse.statusCode) for \(category)", category: .network)
            
            guard httpResponse.statusCode == 200 else {
                Logger.debug("HTTP \(httpResponse.statusCode) for \(category)", category: .network)
                throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
            
            Logger.debug("Downloaded \(data.count) bytes for \(category)", category: .network)
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(FirebaseNewsResponse.self, from: data)
            let shuffleStatus = result.shuffled == true ? "SHUFFLED" : ""
            Logger.debug("Decoded \(result.articles.count) articles for \(category) \(shuffleStatus)", category: .network)
            return result
            
        } catch let error as DecodingError {
            Logger.debug("JSON decode error for \(category): \(error)", category: .network)
            throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON decode error"])
        } catch {
            Logger.debug("Network error for \(category): \(error.localizedDescription)", category: .network)
            throw error
        }
    }
    
    private func convertToArticles(_ firebaseArticles: [FirebaseArticle]) -> [Article] {
        return firebaseArticles.compactMap { fbArticle in
            let validSummary = fbArticle.summary.isEmpty ? fbArticle.title : fbArticle.summary
            
            guard !fbArticle.title.isEmpty, !fbArticle.url.isEmpty else {
                return nil
            }
            
            return Article(
                source: Source(id: nil, name: fbArticle.source ?? "News"),
                author: nil,
                title: fbArticle.title,
                description: validSummary,
                url: fbArticle.url,
                urlToImage: fbArticle.image,
                publishedAt: fbArticle.published_at,
                content: nil,
                metadata: ["summary": validSummary]
            )
        }
    }
    
    private func removeDuplicates(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        return articles.filter { article in
            guard !seen.contains(article.url) else { return false }
            seen.insert(article.url)
            return true
        }
    }
    
    func clearCache() {
        cache.clearAll()
        Logger.debug("Cache cleared", category: .general)
    }
}
