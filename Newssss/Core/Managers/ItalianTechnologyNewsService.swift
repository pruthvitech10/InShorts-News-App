//
//  ItalianTechnologyNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN TECHNOLOGY NEWS ONLY
//  Sources: Most reliable Italian tech news sources
//

import Foundation

class ItalianTechnologyNewsService {
    static let shared = ItalianTechnologyNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian technology news from VERIFIED sources
    /// Coverage: Tech, startups, innovation, digital, AI, cybersecurity
    func fetchItalianTechnology() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("💻 Fetching Italian technology from dedicated sources", category: .network)
        
        // 1️⃣ ANSA Tecnologia - News agency tech section
        articles.append(contentsOf: await fetchFromANSATech())
        
        // 2️⃣ La Repubblica Tecnologia
        articles.append(contentsOf: await fetchFromRepubblicaTech())
        
        // 3️⃣ Corriere Innovazione - Corriere tech section
        articles.append(contentsOf: await fetchFromCorriereInnovazione())
        
        // 4️⃣ Il Sole 24 Ore Tecnologia
        articles.append(contentsOf: await fetchFromSole24OreTech())
        
        // 5️⃣ AGI Tecnologia
        articles.append(contentsOf: await fetchFromAGITech())
        
        // 6️⃣ Tom's Hardware Italia - Tech hardware news
        articles.append(contentsOf: await fetchFromTomsHardware())
        
        // 7️⃣ HDBlog - Italian tech blog
        articles.append(contentsOf: await fetchFromHDBlog())
        
        // 8️⃣ Wired Italia - Tech and innovation
        articles.append(contentsOf: await fetchFromWiredItalia())
        
        Logger.debug("💻 Total tech articles from 8 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ ANSA Tecnologia
    private func fetchFromANSATech() async -> [Article] {
        let feedURL = "https://www.ansa.it/sito/notizie/tecnologia/tecnologia_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Tecnologia")
    }
    
    // MARK: - 2️⃣ La Repubblica Tecnologia
    private func fetchFromRepubblicaTech() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/tecnologia/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Tech")
    }
    
    // MARK: - 3️⃣ Corriere Innovazione
    private func fetchFromCorriereInnovazione() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/tecnologia.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Innovazione")
    }
    
    // MARK: - 4️⃣ Il Sole 24 Ore Tecnologia
    private func fetchFromSole24OreTech() async -> [Article] {
        let feedURL = "https://www.ilsole24ore.com/rss/tecnologia.xml"
        return await fetchRSS(url: feedURL, source: "Il Sole 24 Ore Tech")
    }
    
    // MARK: - 5️⃣ AGI Tecnologia
    private func fetchFromAGITech() async -> [Article] {
        let feedURL = "https://www.agi.it/innovazione/rss"
        return await fetchRSS(url: feedURL, source: "AGI Tecnologia")
    }
    
    // MARK: - 6️⃣ Tom's Hardware Italia
    private func fetchFromTomsHardware() async -> [Article] {
        let feedURL = "https://www.tomshw.it/feed"
        return await fetchRSS(url: feedURL, source: "Tom's Hardware Italia")
    }
    
    // MARK: - 7️⃣ HDBlog
    private func fetchFromHDBlog() async -> [Article] {
        let feedURL = "https://www.hdblog.it/feed/"
        return await fetchRSS(url: feedURL, source: "HDBlog")
    }
    
    // MARK: - 8️⃣ Wired Italia
    private func fetchFromWiredItalia() async -> [Article] {
        let feedURL = "https://www.wired.it/feed/rss"
        return await fetchRSS(url: feedURL, source: "Wired Italia")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) tech articles", category: .network)
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
