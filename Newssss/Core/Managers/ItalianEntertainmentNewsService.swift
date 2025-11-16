//
//  ItalianEntertainmentNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN ENTERTAINMENT NEWS ONLY
//  Sources: Most reliable Italian entertainment news sources
//

import Foundation

class ItalianEntertainmentNewsService {
    static let shared = ItalianEntertainmentNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian entertainment news from VERIFIED sources
    /// Coverage: Cinema, TV, music, celebrities, culture, spettacolo
    func fetchItalianEntertainment() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🎬 Fetching Italian entertainment from dedicated sources", category: .network)
        
        // 1️⃣ ANSA Spettacolo - News agency entertainment section
        articles.append(contentsOf: await fetchFromANSASpettacolo())
        
        // 2️⃣ La Repubblica Spettacoli
        articles.append(contentsOf: await fetchFromRepubblicaSpettacoli())
        
        // 3️⃣ Corriere Spettacoli
        articles.append(contentsOf: await fetchFromCorriereSpettacoli())
        
        // 4️⃣ Il Fatto Quotidiano Spettacoli
        articles.append(contentsOf: await fetchFromFattoSpettacoli())
        
        // 5️⃣ Sky TG24 Spettacolo
        articles.append(contentsOf: await fetchFromSkySpettacolo())
        
        // 6️⃣ Fanpage Spettacolo - Popular entertainment news
        articles.append(contentsOf: await fetchFromFanpage())
        
        // 7️⃣ Movieplayer - Cinema and TV news
        articles.append(contentsOf: await fetchFromMovieplayer())
        
        Logger.debug("🎬 Total entertainment articles from 7 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ ANSA Spettacolo
    private func fetchFromANSASpettacolo() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/cultura/cultura_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Spettacolo")
    }
    
    // MARK: - 2️⃣ La Repubblica Spettacoli
    private func fetchFromRepubblicaSpettacoli() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/spettacoli/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Spettacoli")
    }
    
    // MARK: - 3️⃣ Corriere Spettacoli
    private func fetchFromCorriereSpettacoli() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/spettacoli.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Spettacoli")
    }
    
    // MARK: - 4️⃣ Il Fatto Quotidiano Spettacoli
    private func fetchFromFattoSpettacoli() async -> [Article] {
        let feedURL = "https://www.ilfattoquotidiano.it/feed/"
        return await fetchRSS(url: feedURL, source: "Il Fatto Spettacoli")
    }
    
    // MARK: - 5️⃣ Sky TG24 Spettacolo
    private func fetchFromSkySpettacolo() async -> [Article] {
        let feedURL = "https://tg24.sky.it/spettacolo/rss"
        return await fetchRSS(url: feedURL, source: "Sky Spettacolo")
    }
    
    // MARK: - 6️⃣ Fanpage Spettacolo
    private func fetchFromFanpage() async -> [Article] {
        let feedURL = "https://www.fanpage.it/feed/"
        return await fetchRSS(url: feedURL, source: "Fanpage")
    }
    
    // MARK: - 7️⃣ Movieplayer
    private func fetchFromMovieplayer() async -> [Article] {
        let feedURL = "https://www.movieplayer.it/feed/"
        return await fetchRSS(url: feedURL, source: "Movieplayer")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) entertainment articles", category: .network)
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
