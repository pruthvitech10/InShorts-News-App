//
//  ItalianGeneralNewsService.swift
//  Newssss
//
//  DEDICATED SERVICE FOR ITALIAN GENERAL/EVERYDAY NEWS ONLY
//  Sources: Everyday life topics - gold, prices, fashion, real estate, consumer news
//

import Foundation

class ItalianGeneralNewsService {
    static let shared = ItalianGeneralNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian general/everyday news from VERIFIED sources
    /// Coverage: Gold rates, grocery prices, fashion, real estate, consumer news, daily life
    func fetchItalianGeneral() async -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("📰 Fetching Italian general news from dedicated sources", category: .network)
        
        // 1️⃣ Il Sole 24 Ore Finanza Personale - Personal finance, gold, investments
        articles.append(contentsOf: await fetchFromSole24OreFinanzaPersonale())
        
        // 2️⃣ Altroconsumo - Consumer news, prices, product tests
        articles.append(contentsOf: await fetchFromAltroconsumo())
        
        // 3️⃣ Idealista - Real estate news, house prices
        articles.append(contentsOf: await fetchFromIdealista())
        
        // 4️⃣ Immobiliare.it - Real estate market
        articles.append(contentsOf: await fetchFromImmobiliare())
        
        // 5️⃣ Codacons - Consumer protection, prices
        articles.append(contentsOf: await fetchFromCodacons())
        
        // 6️⃣ Adnkronos Soldi - Money, gold, markets
        articles.append(contentsOf: await fetchFromAdnkronosSoldi())
        
        // 7️⃣ Vanity Fair Italia - Fashion, trends, lifestyle
        articles.append(contentsOf: await fetchFromVanityFair())
        
        // 8️⃣ ANSA Lifestyle - General lifestyle news
        articles.append(contentsOf: await fetchFromANSALifestyle())
        
        Logger.debug("📰 Total general news articles from 8 sources: \(articles.count)", category: .network)
        
        // Remove duplicates and sort by date
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return sorted
    }
    
    // MARK: - 1️⃣ Il Sole 24 Ore Finanza Personale
    private func fetchFromSole24OreFinanzaPersonale() async -> [Article] {
        let feedURL = "https://www.ilsole24ore.com/rss/finanza-personale.xml"
        return await fetchRSS(url: feedURL, source: "Il Sole 24 Ore Finanza")
    }
    
    // MARK: - 2️⃣ Altroconsumo
    private func fetchFromAltroconsumo() async -> [Article] {
        let feedURL = "https://www.altroconsumo.it/rss/news.xml"
        return await fetchRSS(url: feedURL, source: "Altroconsumo")
    }
    
    // MARK: - 3️⃣ Idealista
    private func fetchFromIdealista() async -> [Article] {
        let feedURL = "https://www.idealista.it/news/rss"
        return await fetchRSS(url: feedURL, source: "Idealista")
    }
    
    // MARK: - 4️⃣ Immobiliare.it
    private func fetchFromImmobiliare() async -> [Article] {
        let feedURL = "https://www.immobiliare.it/news/rss/"
        return await fetchRSS(url: feedURL, source: "Immobiliare.it")
    }
    
    // MARK: - 5️⃣ Codacons
    private func fetchFromCodacons() async -> [Article] {
        let feedURL = "https://www.codacons.it/feed/"
        return await fetchRSS(url: feedURL, source: "Codacons")
    }
    
    // MARK: - 6️⃣ Adnkronos Soldi
    private func fetchFromAdnkronosSoldi() async -> [Article] {
        let feedURL = "https://www.adnkronos.com/rss/economia.xml"
        return await fetchRSS(url: feedURL, source: "Adnkronos Economia")
    }
    
    // MARK: - 7️⃣ Vanity Fair Italia  
    private func fetchFromVanityFair() async -> [Article] {
        let feedURL = "https://www.vanityfair.it/feed"
        return await fetchRSS(url: feedURL, source: "Vanity Fair Italia")
    }
    
    // MARK: - 8️⃣ ANSA Lifestyle
    private func fetchFromANSALifestyle() async -> [Article] {
        let feedURL = "https://www.ansa.it/canale_lifestyle/notizie/lifestyle_rss.xml"
        return await fetchRSS(url: feedURL, source: "ANSA Lifestyle")
    }
    
    // MARK: - RSS Fetcher
    private func fetchRSS(url: String, source: String) async -> [Article] {
        do {
            let articles = try await parseRSSFeed(url: url, source: source)
            Logger.debug("✅ \(source): \(articles.count) general articles", category: .network)
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
