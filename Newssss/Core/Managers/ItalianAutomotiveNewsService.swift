//
//  ItalianAutomotiveNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN AUTOMOTIVE NEWS ONLY
//  Sources: Most reliable Italian automotive news sources
//

import Foundation

class ItalianAutomotiveNewsService {
    static let shared = ItalianAutomotiveNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian automotive news from VERIFIED sources
    /// Coverage: Cars, motorcycles, F1, Ferrari, Lamborghini, Fiat, electric vehicles
    func fetchItalianAutomotive() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🚗 Fetching Italian automotive from dedicated sources", category: .network)
        
        // 1️⃣ Quattroruote - #1 Italian automotive magazine
        articles.append(contentsOf: await fetchFromQuattroruote())
        
        // 2️⃣ Autoblog Italia - Automotive blog
        articles.append(contentsOf: await fetchFromAutoblogItalia())
        
        // 3️⃣ Corriere Motori
        articles.append(contentsOf: await fetchFromCorriereMotori())
        
        // 4️⃣ La Repubblica Motori
        articles.append(contentsOf: await fetchFromRepubblicaMotori())
        
        // 5️⃣ ANSA Motori
        articles.append(contentsOf: await fetchFromANSAMotori())
        
        // 6️⃣ Automoto.it - Automotive news
        articles.append(contentsOf: await fetchFromAutomoto())
        
        // 7️⃣ Motor1 Italia - International automotive
        articles.append(contentsOf: await fetchFromMotor1())
        
        Logger.debug("🚗 Total automotive articles from 7 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ Quattroruote
    private func fetchFromQuattroruote() async -> [Article] {
        let feedURL = "https://www.quattroruote.it/rss/news.xml"
        return await fetchRSS(url: feedURL, source: "Quattroruote")
    }
    
    // MARK: - 2️⃣ Autoblog Italia
    private func fetchFromAutoblogItalia() async -> [Article] {
        let feedURL = "https://it.autoblog.com/rss.xml"
        return await fetchRSS(url: feedURL, source: "Autoblog Italia")
    }
    
    // MARK: - 3️⃣ Corriere Motori
    private func fetchFromCorriereMotori() async -> [Article] {
        let feedURL = "https://xml2.corriereobjects.it/rss/motori.xml"
        return await fetchRSS(url: feedURL, source: "Corriere Motori")
    }
    
    // MARK: - 4️⃣ La Repubblica Motori
    private func fetchFromRepubblicaMotori() async -> [Article] {
        let feedURL = "https://www.repubblica.it/rss/motori/rss2.0.xml"
        return await fetchRSS(url: feedURL, source: "La Repubblica Motori")
    }
    
    // MARK: - 5️⃣ ANSA Motori
    private func fetchFromANSAMotori() async -> [Article] {
        let feedURL = "https://www.ansa.it/canale_motori/notizie/motori_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Motori")
    }
    
    // MARK: - 6️⃣ Automoto.it
    private func fetchFromAutomoto() async -> [Article] {
        let feedURL = "https://www.automoto.it/feed"
        return await fetchRSS(url: feedURL, source: "Automoto")
    }
    
    // MARK: - 7️⃣ Motor1 Italia
    private func fetchFromMotor1() async -> [Article] {
        let feedURL = "https://it.motor1.com/rss/all/"
        return await fetchRSS(url: feedURL, source: "Motor1 Italia")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) automotive articles", category: .network)
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
