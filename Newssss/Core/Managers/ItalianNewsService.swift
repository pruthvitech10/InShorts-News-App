//
//  ItalianNewsService.swift
//  Newssss
//
//  Dedicated service for fetching Italian news from reliable Italian sources
//

import Foundation

class ItalianNewsService {
    static let shared = ItalianNewsService()
    
    private let fetchService = RSSFetchService.shared
    
    private init() {}
    
    /// Fetch Italian news from multiple Italian sources
    /// NO LIMIT - fetch ALL articles available!
    /// Each category has its OWN dedicated sources
    func fetchItalianNews(category: String? = nil, limit: Int = Int.max) async throws -> [Article] {
        var articles: [Article] = []
        
        // Route to category-specific sources
        switch category {
        case "sports":
            // ONLY sports sources for sports category
            articles = await fetchSportsNews()
            
        case "business":
            // ONLY business/financial sources for business category
            articles = await fetchBusinessNews()
            
        case "politics":
            // ONLY politics sources for politics category
            articles = await fetchPoliticsNews()
            
        case "entertainment":
            // ONLY entertainment sources for entertainment category
            articles = await fetchEntertainmentNews()
            
        case "technology":
            // Technology news from tech sections
            articles = await fetchTechnologyNews()
            
        case "world":
            // World/international news
            articles = await fetchWorldNews()
            
        case "crime":
            // Crime & justice news
            articles = await fetchCrimeNews()
            
        case "automotive":
            // Automotive news
            articles = await fetchAutomotiveNews()
            
        case "lifestyle":
            // Food & lifestyle news
            articles = await fetchLifestyleNews()
            
        case "general", nil:
            // General news from all major sources
            articles = await fetchGeneralNews()
            
        default:
            // Fallback to general
            articles = await fetchGeneralNews()
        }
        
        Logger.debug("🇮🇹 Fetched \(articles.count) Italian articles from Italian sources", category: .network)
        
        // Remove duplicates and sort by date - NO LIMIT!
        let uniqueArticles = removeDuplicates(from: articles)
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        // Return ALL articles, no limit
        return sorted
    }
    
    // MARK: - Category-Specific Fetch Methods
    // Each category has VERIFIED RSS feeds from multiple Italian sources
    
    /// 1️⃣ SPORTS - Dedicated service with 7 Italian sports sources
    private func fetchSportsNews() async -> [Article] {
        let articles = await ItalianSportsNewsService.shared.fetchItalianSports()
        Logger.debug("⚽ Sports: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 2️⃣ BUSINESS - Dedicated service with 8 Italian business sources
    private func fetchBusinessNews() async -> [Article] {
        let articles = await ItalianBusinessNewsService.shared.fetchItalianBusiness()
        Logger.debug("💼 Business: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 3️⃣ POLITICS - Dedicated service with 8 Italian political sources
    private func fetchPoliticsNews() async -> [Article] {
        let articles = await ItalianPoliticsNewsService.shared.fetchItalianPolitics()
        Logger.debug("🏛️ Politics: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 4️⃣ ENTERTAINMENT - Dedicated service with 7 Italian entertainment sources
    private func fetchEntertainmentNews() async -> [Article] {
        let articles = await ItalianEntertainmentNewsService.shared.fetchItalianEntertainment()
        Logger.debug("🎬 Entertainment: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 5️⃣ TECHNOLOGY - Dedicated service with 8 Italian tech sources
    private func fetchTechnologyNews() async -> [Article] {
        let articles = await ItalianTechnologyNewsService.shared.fetchItalianTechnology()
        Logger.debug("💻 Technology: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 8️⃣ WORLD - Dedicated service with 8 Italian world news sources
    private func fetchWorldNews() async -> [Article] {
        let articles = await ItalianWorldNewsService.shared.fetchItalianWorld()
        Logger.debug("🌍 World: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 9️⃣ CRIME - Dedicated service with 8 Italian crime news sources
    private func fetchCrimeNews() async -> [Article] {
        let articles = await ItalianCrimeNewsService.shared.fetchItalianCrime()
        Logger.debug("⚖️ Crime: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 🔟 AUTOMOTIVE - Dedicated service with 7 Italian automotive sources
    private func fetchAutomotiveNews() async -> [Article] {
        let articles = await ItalianAutomotiveNewsService.shared.fetchItalianAutomotive()
        Logger.debug("🚗 Automotive: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 1️⃣1️⃣ LIFESTYLE - Dedicated service with 7 Italian lifestyle sources
    private func fetchLifestyleNews() async -> [Article] {
        let articles = await ItalianLifestyleNewsService.shared.fetchItalianLifestyle()
        Logger.debug("🍝 Lifestyle: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    /// 1️⃣2️⃣ GENERAL - Dedicated service with 8 Italian general/everyday sources
    private func fetchGeneralNews() async -> [Article] {
        let articles = await ItalianGeneralNewsService.shared.fetchItalianGeneral()
        Logger.debug("📰 General: \(articles.count) articles from dedicated service", category: .network)
        return articles
    }
    
    // MARK: - ALL NEWS SOURCES DELETED
    // Ready to add sources one by one
    
    // MARK: - RSS Parser
    
    private func parseRSSFeed(url: String, source: String) async throws -> [Article] {
        // Fetch fresh data from network (NO CACHE)
        let data = try await fetchService.fetchRSSData(url: url)
        
        let parser = RSSParser()
        let items = try parser.parse(data: data)
        
        // Convert RSS items to Articles with enhanced image fetching
        var articles: [Article] = []
        
        for item in items {
            // Format date to ISO8601 string
            let dateFormatter = ISO8601DateFormatter()
            let publishedAtString = dateFormatter.string(from: item.pubDate ?? Date())
            
            // Try to get image from multiple sources
            var imageURL = item.imageURL
            
            // If no image in RSS, try to extract from article page
            if imageURL == nil || imageURL?.isEmpty == true {
                imageURL = await fetchImageFromArticlePage(url: item.link)
            }
            
            // Create article with image
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
        
        Logger.debug("✅ Parsed \(articles.count) articles from \(source), \(articles.filter { $0.urlToImage != nil }.count) with images", category: .network)
        
        return articles
    }
    
    /// Fetch image from article page by scraping the HTML
    private func fetchImageFromArticlePage(url: String) async -> String? {
        guard let articleURL = URL(string: url) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: articleURL)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            // Try to find Open Graph image (most reliable)
            if let ogImage = extractMetaTag(from: html, property: "og:image") {
                return ogImage
            }
            
            // Try Twitter card image
            if let twitterImage = extractMetaTag(from: html, property: "twitter:image") {
                return twitterImage
            }
            
            // Try to find first large image in article
            if let firstImage = extractFirstArticleImage(from: html) {
                return firstImage
            }
            
        } catch {
            Logger.debug("⚠️ Failed to fetch image from article page: \(error)", category: .network)
        }
        
        return nil
    }
    
    /// Extract meta tag content from HTML
    private func extractMetaTag(from html: String, property: String) -> String? {
        // Look for <meta property="og:image" content="...">
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
        
        // Also try reversed format: <meta content="..." property="...">
        let pattern2 = "<meta[^>]*content=\"([^\"]+)\"[^>]*property=\"\(property)\""
        guard let regex2 = try? NSRegularExpression(pattern: pattern2, options: .caseInsensitive) else {
            return nil
        }
        
        let results2 = regex2.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        if let match = results2.first, match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            return nsString.substring(with: range)
        }
        
        return nil
    }
    
    /// Extract first article image from HTML
    private func extractFirstArticleImage(from html: String) -> String? {
        // Look for images in article content (usually have specific classes)
        let patterns = [
            "<img[^>]*class=\"[^\"]*article[^\"]*\"[^>]*src=\"([^\"]+)\"",
            "<img[^>]*src=\"([^\"]+)\"[^>]*class=\"[^\"]*article[^\"]*\"",
            "<figure[^>]*><img[^>]*src=\"([^\"]+)\"",
            "<img[^>]*src=\"([^\"]+)\"[^>]*width=\"[5-9][0-9]{2,}\"" // Large images (500px+)
        ]
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }
            
            let nsString = html as NSString
            let results = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
            
            if let match = results.first, match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                let imageURL = nsString.substring(with: range)
                
                // Filter out small images, icons, logos
                if !imageURL.contains("logo") && !imageURL.contains("icon") && !imageURL.contains("avatar") {
                    return imageURL
                }
            }
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

// MARK: - RSS Parser

class RSSParser: NSObject, XMLParserDelegate {
    struct RSSItem {
        var title: String = ""
        var link: String = ""
        var description: String?
        var pubDate: Date?
        var author: String?
        var content: String?
        var imageURL: String?
    }
    
    private var items: [RSSItem] = []
    private var currentItem: RSSItem?
    private var currentElement: String = ""
    private var currentText: String = ""
    
    func parse(data: Data) throws -> [RSSItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            throw NSError(domain: "RSSParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse RSS feed"])
        }
        
        return items
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        
        if elementName == "item" {
            currentItem = RSSItem()
        }
        
        // Handle media:content or enclosure for images
        if elementName == "media:content" || elementName == "enclosure" {
            if let url = attributeDict["url"] {
                currentItem?.imageURL = url
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard var item = currentItem else { return }
        
        switch elementName {
        case "title":
            item.title = currentText
        case "link":
            item.link = currentText
        case "description":
            item.description = currentText
        case "pubDate":
            item.pubDate = parseDate(currentText)
        case "author", "dc:creator":
            item.author = currentText
        case "content:encoded":
            item.content = currentText
        case "item":
            items.append(item)
            currentItem = nil
            return
        default:
            break
        }
        
        currentItem = item
        currentText = ""
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try RFC 822 format (most common in RSS)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try ISO 8601
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
}
