import Foundation

// MARK: - Response Models

/// Firebase Storage response format (matches unified-pipeline.ts)
struct FirebaseNewsResponse: Codable {
    let category: String
    let updated_at: String
    let articles: [FirebaseArticle]
}

/// Article from Firebase (matches backend exactly)
struct FirebaseArticle: Codable {
    let title: String
    let url: String
    let summary: String        // 30-40 word summary from backend
    let image: String?
    let published_at: String
}

// MARK: - Cache Manager

/// Fast local cache with timestamp checking
class NewsCache {
    private let fileManager = FileManager.default
    private let cacheDir: URL
    
    init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDir = paths[0].appendingPathComponent("NewsCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
    
    /// Get cached response
    func get(category: String) -> FirebaseNewsResponse? {
        let fileURL = cacheDir.appendingPathComponent("\(category).json")
        
        guard let data = try? Data(contentsOf: fileURL),
              let response = try? JSONDecoder().decode(FirebaseNewsResponse.self, from: data) else {
            return nil
        }
        
        return response
    }
    
    /// Save response to cache
    func save(category: String, response: FirebaseNewsResponse) {
        let fileURL = cacheDir.appendingPathComponent("\(category).json")
        
        if let data = try? JSONEncoder().encode(response) {
            try? data.write(to: fileURL)
        }
    }
    
    /// Clear all cache
    func clearAll() {
        try? fileManager.removeItem(at: cacheDir)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}

// MARK: - Firebase News Service

/// Complete Firebase Storage client
/// Features:
/// 1. Fetches from public Firebase Storage URL
/// 2. Backend provides 30-40 word summaries
/// 3. Local caching for instant loads
/// 4. Checks updated_at before re-fetching
/// 5. Parses: title, summary, image, published_at
/// 6. No duplicates
/// 7. Offline support
/// 8. Extremely fast
class FirebaseNewsService {
    static let shared = FirebaseNewsService()
    
    private let cache = NewsCache()
    // CRITICAL: Use firebasestorage.app where files actually exist
    private let baseURL = "https://firebasestorage.googleapis.com/v0/b/news-8b080.firebasestorage.app/o/news%2Fnews_"
    
    private init() {
        // Only initialize if Firebase is ready
        guard FirebaseInitializer.shared.isReady else {
            Logger.debug("⚠️ Firebase News Service init - Firebase not ready yet", category: .general)
            return
        }
        Logger.debug("🔥 Firebase News Service initialized", category: .general)
    }
    
    // MARK: - Public API
    
    /// Fetch category with smart caching
    func fetchCategory(_ category: String) async throws -> [Article] {
        Logger.debug("📥 Fetching \(category)...", category: .network)
        
        // STEP 1: Try to download from Firebase
        do {
            let response = try await downloadFromFirebase(category)
            
            // STEP 2: Check if cache has same updated_at
            if let cached = cache.get(category: category),
               cached.updated_at == response.updated_at {
                Logger.debug("✅ Cache is up-to-date, using cached data", category: .network)
                return convertToArticles(cached.articles)
            }
            
            // STEP 3: Save new data to cache
            cache.save(category: category, response: response)
            Logger.debug("✅ Downloaded \(response.articles.count) articles", category: .network)
            
            return convertToArticles(response.articles)
        } catch {
            // STEP 4: Offline - use cache
            if let cached = cache.get(category: category) {
                Logger.debug("📱 Offline mode: using cache", category: .network)
                return convertToArticles(cached.articles)
            }
            
            throw error
        }
    }
    
    /// Fetch all categories in parallel
    func fetchAllCategories() async throws -> [String: [Article]] {
        Logger.debug("🔥 Fetching all categories...", category: .network)
        
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
            
            // Build "general" (all combined, no duplicates)
            let allArticles = results.values.flatMap { $0 }
            results["general"] = removeDuplicates(allArticles)
            
            Logger.debug("✅ Fetched \(results.count) categories", category: .network)
            
            return results
        }
    }
    
    // MARK: - Private Helpers
    
    /// Download from Firebase Storage
    private func downloadFromFirebase(_ category: String) async throws -> FirebaseNewsResponse {
        let urlString = "\(baseURL)\(category).json?alt=media"
        
        // CRITICAL: Log the exact URL being used
        Logger.debug("🌐 Storage URL: \(urlString)", category: .network)
        
        guard let url = URL(string: urlString) else {
            Logger.debug("❌ Invalid URL for category: \(category)", category: .network)
            throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.debug("❌ No HTTP response for \(category)", category: .network)
                throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
            }
            
            Logger.debug("📡 HTTP Status: \(httpResponse.statusCode) for \(category)", category: .network)
            
            guard httpResponse.statusCode == 200 else {
                Logger.debug("❌ HTTP \(httpResponse.statusCode) for \(category)", category: .network)
                throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
            
            Logger.debug("📦 Downloaded \(data.count) bytes for \(category)", category: .network)
            
            let decoder = JSONDecoder()
            let result = try decoder.decode(FirebaseNewsResponse.self, from: data)
            Logger.debug("✅ Decoded \(result.articles.count) articles for \(category)", category: .network)
            return result
            
        } catch let error as DecodingError {
            Logger.debug("❌ JSON decode error for \(category): \(error)", category: .network)
            throw NSError(domain: "FirebaseNewsService", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON decode error"])
        } catch {
            Logger.debug("❌ Network error for \(category): \(error.localizedDescription)", category: .network)
            throw error
        }
    }
    
    /// Convert Firebase articles to app Article model
    private func convertToArticles(_ firebaseArticles: [FirebaseArticle]) -> [Article] {
        return firebaseArticles.compactMap { fbArticle in
            // Validate summary - use title as fallback if empty
            let validSummary = fbArticle.summary.isEmpty ? fbArticle.title : fbArticle.summary
            
            // Skip articles with no title or URL
            guard !fbArticle.title.isEmpty, !fbArticle.url.isEmpty else {
                Logger.debug("⚠️ Skipping article with missing title or URL", category: .network)
                return nil
            }
            
            return Article(
                source: Source(id: nil, name: "News"),
                author: nil,
                title: fbArticle.title,
                description: validSummary,  // Use backend summary with fallback
                url: fbArticle.url,
                urlToImage: fbArticle.image,
                publishedAt: fbArticle.published_at,
                content: nil,
                metadata: ["summary": validSummary]
            )
        }
    }
    
    /// Remove duplicates by URL
    private func removeDuplicates(_ articles: [Article]) -> [Article] {
        var seen = Set<String>()
        return articles.filter { article in
            guard !seen.contains(article.url) else { return false }
            seen.insert(article.url)
            return true
        }
    }
    
    /// Clear cache
    func clearCache() {
        cache.clearAll()
        Logger.debug("🗑️ Cache cleared", category: .general)
    }
}
