//
//  ItalianPoliticsNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN POLITICS NEWS ONLY
//  Sources: Most reliable Italian political news sources
//

import Foundation

class ItalianPoliticsNewsService {
    static let shared = ItalianPoliticsNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian political news from VERIFIED sources
    /// Coverage: National politics, regional politics, parliament, government
    func fetchItalianPolitics() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🏛️ Fetching Italian politics from dedicated sources", category: .network)
        
        // 1️⃣ ANSA - Italy's #1 News Agency (Politics Section)
        // Most reliable, fastest breaking news, covers all Italy
        articles.append(contentsOf: await fetchFromANSAPolitics())
        
        // 2️⃣ La Repubblica - Major Italian newspaper (Politics)
        // Left-leaning, excellent coverage of government and parliament
        articles.append(contentsOf: await fetchFromRepubblicaPolitics())
        
        // 3️⃣ Corriere della Sera - Italy's largest newspaper (Politics)
        // Center-right, comprehensive political coverage
        articles.append(contentsOf: await fetchFromCorrierePolitics())
        
        // 4️⃣ Il Sole 24 Ore - Financial newspaper (Politics & Economy)
        // Business perspective on politics, government economic policies
        articles.append(contentsOf: await fetchFromIlSole24OrePolitics())
        
        // 5️⃣ AGI - Italian news agency (Politics)
        // Second major news agency, excellent political coverage
        articles.append(contentsOf: await fetchFromAGIPolitics())
        
        // 6️⃣ Il Fatto Quotidiano - Investigative (Politics)
        // Anti-corruption, investigative journalism
        articles.append(contentsOf: await fetchFromIlFattoQuotidianoPolitics())
        
        // 7️⃣ La Stampa - Turin newspaper (Politics)
        // Northern Italy perspective, government analysis
        articles.append(contentsOf: await fetchFromLaStampaPolitics())
        
        // 8️⃣ Il Messaggero - Rome newspaper (Politics)
        // Government seat coverage, political insider news
        articles.append(contentsOf: await fetchFromIlMessaggeroPolitics())
        
        // 9️⃣ Tgcom24 - Mediaset news (Politics)
        // TV news perspective, breaking political news
        articles.append(contentsOf: await fetchFromTgcom24Politics())
        
        Logger.debug("🏛️ Total politics articles from 9 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ ANSA Politics
    private func fetchFromANSAPolitics() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/politica/politica_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA")
    }
    
    // MARK: - 2️⃣ La Repubblica Politics
    private func fetchFromRepubblicaPolitics() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/politica/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica")
    }
    
    // MARK: - 3️⃣ Corriere della Sera Politics
    private func fetchFromCorrierePolitics() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/politica.xml"
        return await fetchRSS(url: feedURL, source: "Corriere della Sera")
    }
    
    // MARK: - 4️⃣ Il Sole 24 Ore Politics
    private func fetchFromIlSole24OrePolitics() async -> [Article] {
        let feedURL = "https://www.ilsole24ore.com/rss/politica.xml"
        return await fetchRSS(url: feedURL, source: "Il Sole 24 Ore")
    }
    
    // MARK: - 5️⃣ AGI Politics (Italian News Agency)
    private func fetchFromAGIPolitics() async -> [Article] {
        let feedURL = "https://www.agi.it/politica/rss"
        return await fetchRSS(url: feedURL, source: "AGI")
    }
    
    // MARK: - 6️⃣ Il Fatto Quotidiano Politics
    private func fetchFromIlFattoQuotidianoPolitics() async -> [Article] {
        let feedURL = "https://www.ilfattoquotidiano.it/feed/"
        return await fetchRSS(url: feedURL, source: "Il Fatto Quotidiano")
    }
    
    // MARK: - 7️⃣ La Stampa Politics
    private func fetchFromLaStampaPolitics() async -> [Article] {
        let feedURL = "https://www.lastampa.it/politica/rss"
        return await fetchRSS(url: feedURL, source: "La Stampa")
    }
    
    // MARK: - 8️⃣ Il Messaggero Politics
    private func fetchFromIlMessaggeroPolitics() async -> [Article] {
        let feedURL = "https://www.ilmessaggero.it/rss/politica.xml"
        return await fetchRSS(url: feedURL, source: "Il Messaggero")
    }
    
    // MARK: - 9️⃣ Tgcom24 Politics
    private func fetchFromTgcom24Politics() async -> [Article] {
        let feedURL = "https://www.tgcom24.mediaset.it/rss/politica.xml"
        return await fetchRSS(url: feedURL, source: "Tgcom24")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) politics articles", category: .network)
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
