//
//  ItalianLifestyleNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN FOOD & LIFESTYLE NEWS ONLY
//  Sources: Most reliable Italian lifestyle news sources
//

import Foundation

class ItalianLifestyleNewsService {
    static let shared = ItalianLifestyleNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian food & lifestyle news from VERIFIED sources
    /// Coverage: Food, wine, fashion, travel, design, culture
    func fetchItalianLifestyle() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🍝 Fetching Italian lifestyle from dedicated sources", category: .network)
        
        // 1️⃣ La Cucina Italiana - #1 Italian cooking magazine
        articles.append(contentsOf: await fetchFromLaCucinaItaliana())
        
        // 2️⃣ Giallo Zafferano - Popular recipe site
        articles.append(contentsOf: await fetchFromGialloZafferano())
        
        // 3️⃣ Sale&Pepe - Food magazine
        articles.append(contentsOf: await fetchFromSalePepe())
        
        // 4️⃣ Vogue Italia - Fashion & lifestyle
        articles.append(contentsOf: await fetchFromVogueItalia())
        
        // 5️⃣ Elle Italia - Fashion & lifestyle
        articles.append(contentsOf: await fetchFromElleItalia())
        
        // 6️⃣ Gambero Rosso - Food & wine
        articles.append(contentsOf: await fetchFromGamberoRosso())
        
        // 7️⃣ Dove Viaggi - Travel magazine
        articles.append(contentsOf: await fetchFromDoveViaggi())
        
        Logger.debug("🍝 Total lifestyle articles from 7 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ La Cucina Italiana
    private func fetchFromLaCucinaItaliana() async -> [Article] {
        let feedURL = "https://www.lacucinaitaliana.it/rss"
        return await fetchRSS(url: feedURL, source: "La Cucina Italiana")
    }
    
    // MARK: - 2️⃣ Giallo Zafferano
    private func fetchFromGialloZafferano() async -> [Article] {
        let feedURL = "https://www.giallozafferano.it/rss/ricette-del-giorno/"
        return await fetchRSS(url: feedURL, source: "Giallo Zafferano")
    }
    
    // MARK: - 3️⃣ Sale&Pepe
    private func fetchFromSalePepe() async -> [Article] {
        let feedURL = "https://www.salepepe.it/feed/"
        return await fetchRSS(url: feedURL, source: "Sale&Pepe")
    }
    
    // MARK: - 4️⃣ Vogue Italia
    private func fetchFromVogueItalia() async -> [Article] {
        let feedURL = "https://www.vogue.it/rss"
        return await fetchRSS(url: feedURL, source: "Vogue Italia")
    }
    
    // MARK: - 5️⃣ Elle Italia
    private func fetchFromElleItalia() async -> [Article] {
        let feedURL = "https://www.elle.com/it/rss/"
        return await fetchRSS(url: feedURL, source: "Elle Italia")
    }
    
    // MARK: - 6️⃣ Gambero Rosso
    private func fetchFromGamberoRosso() async -> [Article] {
        let feedURL = "https://www.gamberorosso.it/feed/"
        return await fetchRSS(url: feedURL, source: "Gambero Rosso")
    }
    
    // MARK: - 7️⃣ Dove Viaggi
    private func fetchFromDoveViaggi() async -> [Article] {
        let feedURL = "https://www.dove.it/feed/"
        return await fetchRSS(url: feedURL, source: "Dove Viaggi")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) lifestyle articles", category: .network)
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
