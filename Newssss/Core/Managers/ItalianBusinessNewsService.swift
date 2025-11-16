//
//  ItalianBusinessNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN BUSINESS & FINANCE NEWS ONLY
//  Sources: Most reliable Italian business news sources
//

import Foundation

class ItalianBusinessNewsService {
    static let shared = ItalianBusinessNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian business & finance news from VERIFIED sources
    /// Coverage: Economy, finance, markets, companies, banking, investments
    func fetchItalianBusiness() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("💼 Fetching Italian business from dedicated sources", category: .network)
        
        // 1️⃣ Il Sole 24 Ore - #1 Italian business newspaper
        articles.append(contentsOf: await fetchFromSole24Ore())
        
        // 2️⃣ Milano Finanza - Financial news
        articles.append(contentsOf: await fetchFromMilanoFinanza())
        
        // 3️⃣ ANSA Economia - News agency economy section
        articles.append(contentsOf: await fetchFromANSAEconomia())
        
        // 4️⃣ La Repubblica Economia
        articles.append(contentsOf: await fetchFromRepubblicaEconomia())
        
        // 5️⃣ Corriere Economia
        articles.append(contentsOf: await fetchFromCorriereEconomia())
        
        // 6️⃣ Il Fatto Quotidiano Economia
        articles.append(contentsOf: await fetchFromFattoEconomia())
        
        // 7️⃣ AGI Economia
        articles.append(contentsOf: await fetchFromAGIEconomia())
        
        // 8️⃣ Borsa Italiana - Stock market news
        articles.append(contentsOf: await fetchFromBorsaItaliana())
        
        Logger.debug("💼 Total business articles from 8 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ Il Sole 24 Ore
    private func fetchFromSole24Ore() async -> [Article] {
        let feedURL = "https://www.ilsole24ore.com/rss/economia.xml"
        return await fetchRSS(url: feedURL, source: "Il Sole 24 Ore")
    }
    
    // MARK: - 2️⃣ Milano Finanza
    private func fetchFromMilanoFinanza() async -> [Article] {
        let feedURL = "https://www.milanofinanza.it/rss"
        return await fetchRSS(url: feedURL, source: "Milano Finanza")
    }
    
    // MARK: - 3️⃣ ANSA Economia
    private func fetchFromANSAEconomia() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/economia/economia_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Economia")
    }
    
    // MARK: - 4️⃣ La Repubblica Economia
    private func fetchFromRepubblicaEconomia() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/economia/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Economia")
    }
    
    // MARK: - 5️⃣ Corriere Economia
    private func fetchFromCorriereEconomia() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/economia.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Economia")
    }
    
    // MARK: - 6️⃣ Il Fatto Quotidiano Economia
    private func fetchFromFattoEconomia() async -> [Article] {
        let feedURL = "https://www.ilfattoquotidiano.it/economia/feed/"
        return await fetchRSS(url: feedURL, source: "Il Fatto Economia")
    }
    
    // MARK: - 7️⃣ AGI Economia
    private func fetchFromAGIEconomia() async -> [Article] {
        let feedURL = "https://www.agi.it/economia/rss"
        return await fetchRSS(url: feedURL, source: "AGI Economia")
    }
    
    // MARK: - 8️⃣ Borsa Italiana
    private func fetchFromBorsaItaliana() async -> [Article] {
        let feedURL = "https://www.borsaitaliana.it/borsa/rss/ultime-notizie.rss"
        return await fetchRSS(url: feedURL, source: "Borsa Italiana")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) business articles", category: .network)
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
