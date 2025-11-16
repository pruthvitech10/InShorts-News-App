//
//  ItalianSportsNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN SPORTS NEWS ONLY
//  Sources: Most reliable Italian sports news sources
//

import Foundation

class ItalianSportsNewsService {
    static let shared = ItalianSportsNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian sports news from VERIFIED sources
    /// Coverage: Serie A, Champions League, Italian teams, calcio
    func fetchItalianSports() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("⚽ Fetching Italian sports from dedicated sources", category: .network)
        
        // 1️⃣ Gazzetta dello Sport - #1 Italian sports newspaper
        articles.append(contentsOf: await fetchFromGazzetta())
        
        // 2️⃣ Corriere dello Sport - Major sports newspaper
        articles.append(contentsOf: await fetchFromCorrieredelloSport())
        
        // 3️⃣ TuttoSport - Turin-based sports newspaper
        articles.append(contentsOf: await fetchFromTuttoSport())
        
        // 4️⃣ Sky Sport - Sky Italia sports
        articles.append(contentsOf: await fetchFromSkySport())
        
        // 5️⃣ ANSA Sport - News agency sports section
        articles.append(contentsOf: await fetchFromANSASport())
        
        // 6️⃣ La Repubblica Sport
        articles.append(contentsOf: await fetchFromRepubblicaSport())
        
        // 7️⃣ Corriere della Sera Sport
        articles.append(contentsOf: await fetchFromCorriereSport())
        
        Logger.debug("⚽ Total sports articles from 7 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ Gazzetta dello Sport
    private func fetchFromGazzetta() async -> [Article] {
        let feedURL = "https://www.gazzetta.it/rss/calcio.xml"
        return await fetchRSS(url: feedURL, source: "Gazzetta dello Sport")
    }
    
    // MARK: - 2️⃣ Corriere dello Sport
    private func fetchFromCorrieredelloSport() async -> [Article] {
        let feedURL = "https://www.corrieredellosport.it/feed"
        return await fetchRSS(url: feedURL, source: "Corriere dello Sport")
    }
    
    // MARK: - 3️⃣ TuttoSport
    private func fetchFromTuttoSport() async -> [Article] {
        let feedURL = "https://www.tuttosport.com/feed"
        return await fetchRSS(url: feedURL, source: "TuttoSport")
    }
    
    // MARK: - 4️⃣ Sky Sport
    private func fetchFromSkySport() async -> [Article] {
        let feedURL = "https://sport.sky.it/rss/calcio_rss.xml"
        return await fetchRSS(url: feedURL, source: "Sky Sport")
    }
    
    // MARK: - 5️⃣ ANSA Sport
    private func fetchFromANSASport() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/sport/calcio/calcio_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Sport")
    }
    
    // MARK: - 6️⃣ La Repubblica Sport
    private func fetchFromRepubblicaSport() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/sport/calcio/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Sport")
    }
    
    // MARK: - 7️⃣ Corriere della Sera Sport
    private func fetchFromCorriereSport() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/homepage_sport.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Sport")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) sports articles", category: .network)
            return articles
        } catch {
            Logger.error("❌ \(source) failed: \(error)", category: .network)
            return []
        }
    }
    
    // MARK: - RSS Parser
    private func parseRSSFeed(url: String, source: String) async throws -> [Article] {
        let data = try await fetchService.fetchRSSData(url: url)
        
        let parser = RSSParser()
        let items = try parser.parse(data: data)
        
        var articles: [Article] = []
        
        for item in items {
            let dateFormatter = ISO8601DateFormatter()
            let publishedAtString = dateFormatter.string(from: item.pubDate ?? Date())
            
            var imageURL = item.imageURL
            
            if imageURL == nil || imageURL?.isEmpty == true {
                imageURL = await fetchImageFromArticlePage(url: item.link)
            }
            
            let article = Article(
                source: Source(id: source.lowercased().replacingOccurrences(of: " ", with: ""), name: source),
                author: item.author,
                title: item.title,
                description: item.description,
                url: item.link,
                urlToImage: imageURL,
                publishedAt: publishedAtString,
                content: item.content
            )
            
            articles.append(article)
        }
        
        return articles
    }
    
    private func fetchImageFromArticlePage(url: String) async -> String? {
        guard let articleURL = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: articleURL)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            if let ogImage = extractMetaTag(from: html, property: "og:image") {
                return ogImage
            }
            
            if let twitterImage = extractMetaTag(from: html, property: "twitter:image") {
                return twitterImage
            }
            
        } catch {
            Logger.debug("⚠️ Failed to fetch image: \(error)", category: .network)
        }
        
        return nil
    }
    
    private func extractMetaTag(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]*property=\"\(property)\"[^>]*content=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let nsString = html as NSString
        let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first, match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }
        
        return nil
    }
    
    private func removeDuplicates(from articles: [Article]) -> [Article] {
        var seen = Set<String>()
        return articles.filter { article in
            seen.insert(article.url).inserted
        }
    }
}
