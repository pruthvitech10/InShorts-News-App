//
//  ItalianWorldNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN WORLD NEWS ONLY
//  Sources: Most reliable Italian international news sources
//

import Foundation

class ItalianWorldNewsService {
    static let shared = ItalianWorldNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian world/international news from VERIFIED sources
    /// Coverage: EU, US, Middle East, Asia, Africa, international politics
    func fetchItalianWorld() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🌍 Fetching Italian world news from dedicated sources", category: .network)
        
        // 1️⃣ ANSA Esteri - News agency international section
        articles.append(contentsOf: await fetchFromANSAEsteri())
        
        // 2️⃣ La Repubblica Esteri
        articles.append(contentsOf: await fetchFromRepubblicaEsteri())
        
        // 3️⃣ Corriere Esteri
        articles.append(contentsOf: await fetchFromCorriereEsteri())
        
        // 4️⃣ Il Sole 24 Ore Mondo
        articles.append(contentsOf: await fetchFromSole24OreMondo())
        
        // 5️⃣ AGI Esteri
        articles.append(contentsOf: await fetchFromAGIEsteri())
        
        // 6️⃣ Il Fatto Quotidiano Esteri
        articles.append(contentsOf: await fetchFromFattoEsteri())
        
        // 7️⃣ La Stampa Esteri
        articles.append(contentsOf: await fetchFromStampaEsteri())
        
        // 8️⃣ Sky TG24 Mondo
        articles.append(contentsOf: await fetchFromSkyMondo())
        
        Logger.debug("🌍 Total world news articles from 8 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ ANSA Esteri
    private func fetchFromANSAEsteri() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/mondo/mondo_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Esteri")
    }
    
    // MARK: - 2️⃣ La Repubblica Esteri
    private func fetchFromRepubblicaEsteri() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/esteri/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Esteri")
    }
    
    // MARK: - 3️⃣ Corriere Esteri
    private func fetchFromCorriereEsteri() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/esteri.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Esteri")
    }
    
    // MARK: - 4️⃣ Il Sole 24 Ore Mondo
    private func fetchFromSole24OreMondo() async -> [Article] {
        let feedURL = "https://www.ilsole24ore.com/rss/mondo.xml"
        return await fetchRSS(url: feedURL, source: "Il Sole 24 Ore Mondo")
    }
    
    // MARK: - 5️⃣ AGI Esteri
    private func fetchFromAGIEsteri() async -> [Article] {
        let feedURL = "https://www.agi.it/estero/rss"
        return await fetchRSS(url: feedURL, source: "AGI Esteri")
    }
    
    // MARK: - 6️⃣ Il Fatto Quotidiano Esteri
    private func fetchFromFattoEsteri() async -> [Article] {
        let feedURL = "https://www.ilfattoquotidiano.it/esteri/feed/"
        return await fetchRSS(url: feedURL, source: "Il Fatto Esteri")
    }
    
    // MARK: - 7️⃣ La Stampa Esteri
    private func fetchFromStampaEsteri() async -> [Article] {
        let feedURL = "https://www.lastampa.it/esteri/rss"
        return await fetchRSS(url: feedURL, source: "La Stampa Esteri")
    }
    
    // MARK: - 8️⃣ Sky TG24 Mondo
    private func fetchFromSkyMondo() async -> [Article] {
        let feedURL = "https://tg24.sky.it/mondo/rss"
        return await fetchRSS(url: feedURL, source: "Sky Mondo")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) world news articles", category: .network)
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
