//
//  ItalianCrimeNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN CRIME & JUSTICE NEWS ONLY
//  Sources: Most reliable Italian crime news sources
//

import Foundation

class ItalianCrimeNewsService {
    static let shared = ItalianCrimeNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian crime & justice news from VERIFIED sources
    /// Coverage: Crime, investigations, trials, justice, police
    func fetchItalianCrime() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("⚖️ Fetching Italian crime news from dedicated sources", category: .network)
        
        // 1️⃣ ANSA Cronaca - News agency crime section
        articles.append(contentsOf: await fetchFromANSACronaca())
        
        // 2️⃣ La Repubblica Cronaca
        articles.append(contentsOf: await fetchFromRepubblicaCronaca())
        
        // 3️⃣ Corriere Cronache
        articles.append(contentsOf: await fetchFromCorriereCronache())
        
        // 4️⃣ Il Fatto Quotidiano Cronaca
        articles.append(contentsOf: await fetchFromFattoCronaca())
        
        // 5️⃣ AGI Cronaca
        articles.append(contentsOf: await fetchFromAGICronaca())
        
        // 6️⃣ La Stampa Cronaca
        articles.append(contentsOf: await fetchFromStampaCronaca())
        
        // 7️⃣ Il Messaggero Cronaca
        articles.append(contentsOf: await fetchFromMessaggeroCronaca())
        
        // 8️⃣ Sky TG24 Cronaca
        articles.append(contentsOf: await fetchFromSkyCronaca())
        
        Logger.debug("⚖️ Total crime news articles from 8 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ ANSA Cronaca
    private func fetchFromANSACronaca() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/cronaca/cronaca_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Cronaca")
    }
    
    // MARK: - 2️⃣ La Repubblica Cronaca
    private func fetchFromRepubblicaCronaca() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/cronaca/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Cronaca")
    }
    
    // MARK: - 3️⃣ Corriere Cronache
    private func fetchFromCorriereCronache() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/cronache.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Cronache")
    }
    
    // MARK: - 4️⃣ Il Fatto Quotidiano Cronaca
    private func fetchFromFattoCronaca() async -> [Article] {
        let feedURL = "https://www.ilfattoquotidiano.it/cronaca/feed/"
        return await fetchRSS(url: feedURL, source: "Il Fatto Cronaca")
    }
    
    // MARK: - 5️⃣ AGI Cronaca
    private func fetchFromAGICronaca() async -> [Article] {
        let feedURL = "https://www.agi.it/cronaca/rss"
        return await fetchRSS(url: feedURL, source: "AGI Cronaca")
    }
    
    // MARK: - 6️⃣ La Stampa Cronaca
    private func fetchFromStampaCronaca() async -> [Article] {
        let feedURL = "https://www.lastampa.it/cronaca/rss"
        return await fetchRSS(url: feedURL, source: "La Stampa Cronaca")
    }
    
    // MARK: - 7️⃣ Il Messaggero Cronaca
    private func fetchFromMessaggeroCronaca() async -> [Article] {
        let feedURL = "https://www.ilmessaggero.it/rss/cronaca.xml"
        return await fetchRSS(url: feedURL, source: "Il Messaggero Cronaca")
    }
    
    // MARK: - 8️⃣ Sky TG24 Cronaca
    private func fetchFromSkyCronaca() async -> [Article] {
        let feedURL = "https://tg24.sky.it/cronaca/rss"
        return await fetchRSS(url: feedURL, source: "Sky Cronaca")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) crime articles", category: .network)
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
