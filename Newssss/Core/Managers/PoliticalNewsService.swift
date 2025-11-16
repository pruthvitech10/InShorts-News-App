//
//  PoliticalNewsService.swift
//  Newssss
//
//  Location-aware political news service
//  Prioritizes local politics (e.g., Giorgia Meloni in Italy)
//  Plus global political news for worldwide connections
//  Created on 16 November 2025.
//

import Foundation

// MARK: - Political News Service

class PoliticalNewsService {
    static let shared = PoliticalNewsService()
    
    private let guardianService = GuardianAPIService.shared
    private let nyTimesService = NYTimesAPIService.shared
    private let currentsService = CurrentsAPIService.shared
    private let mediaStackService = MediaStackAPIService.shared
    private let locationService = LocationService.shared
    
    private init() {}
    
    // MARK: - Main Fetch Methods
    
    /// Fetch political news with location-aware prioritization
    /// In Italy: Giorgia Meloni, Italian government, EU politics
    /// Global: US, UK, EU, Asia, Middle East politics
    func fetchPoliticalNews(limit: Int = 30) async throws -> [Article] {
        let userLocation = locationService.detectedCountry
        var articles: [Article] = []
        
        // Priority 1: Local politics based on location
        let localPolitics = try await fetchLocalPolitics()
        articles.append(contentsOf: localPolitics)
        
        // Priority 2: Regional politics (EU for Italy)
        let regionalPolitics = try await fetchRegionalPolitics()
        articles.append(contentsOf: regionalPolitics)
        
        // Priority 3: Global politics (US, UK, China, etc.)
        let globalPolitics = try await fetchGlobalPolitics()
        articles.append(contentsOf: globalPolitics)
        
        // Remove duplicates
        let uniqueArticles = removeDuplicates(from: articles)
        
        // Sort by date
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        Logger.debug("✅ Fetched \(sorted.count) political articles (Location: \(userLocation.displayName))", category: .network)
        
        return Array(sorted.prefix(limit))
    }
    
    // MARK: - Location-Based Politics
    
    /// Fetch local politics based on user's country
    private func fetchLocalPolitics() async throws -> [Article] {
        let country = locationService.detectedCountry
        let countryCode = country.code.uppercased()
        
        Logger.debug("🌍 Fetching local politics for: \(countryCode)", category: .network)
        
        switch countryCode {
        case "IT":
            return try await fetchItalianPolitics()
        case "GB", "UK":
            return try await fetchUKPolitics()
        case "US":
            return try await fetchUSPolitics()
        case "FR":
            return try await fetchFrenchPolitics()
        case "DE":
            return try await fetchGermanPolitics()
        case "ES":
            return try await fetchSpanishPolitics()
        default:
            Logger.debug("⚠️ No specific politics for \(countryCode), using global", category: .network)
            return try await fetchGlobalPolitics()
        }
    }
    
    // MARK: - Italian Politics (Giorgia Meloni Focus)
    
    /// Fetch Italian political news - Giorgia Meloni, Italian government, Parliament
    func fetchItalianPolitics() async throws -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🇮🇹 Fetching Italian politics (Meloni government)", category: .network)
        
        // 1. Fetch from Guardian (English)
        let guardianPolitics = try await guardianService.fetchLatestNews(
            section: "world",
            pageSize: 20
        )
        
        // Filter for Italian politics
        let italianFiltered = guardianPolitics.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            let italianKeywords = [
                "meloni", "giorgia meloni", "italy", "italian",
                "rome", "parliament", "italian government",
                "fratelli d'italia", "italian politics",
                "mattarella", "salvini", "berlusconi"
            ]
            return italianKeywords.contains(where: { keyword in
                title.contains(keyword) || description.contains(keyword)
            })
        }
        
        articles.append(contentsOf: italianFiltered)
        
        // 2. Fetch from Currents API - Italian news IN ITALIAN LANGUAGE
        do {
            let currentsNews = try await currentsService.fetchLatestNews(
                language: "it",  // Italian language
                country: "IT",   // Italy
                category: "politics"
            )
            // Mark Italian language articles
            let italianArticles = currentsNews.map { article in
                var modified = article
                modified.metadata = (article.metadata ?? [:]).merging([
                    "language": "it",
                    "languageName": "Italian",
                    "needsTranslation": "true",
                    "source": "Currents API",
                    "country": "Italy"
                ]) { _, new in new }
                return modified
            }
            articles.append(contentsOf: italianArticles.prefix(5))
            Logger.debug("✅ Fetched \(italianArticles.count) Italian language articles from Currents", category: .network)
        } catch {
            Logger.error("Failed to fetch from Currents: \(error)", category: .network)
        }
        
        // 3. Fetch from MediaStack - Italian news IN ITALIAN LANGUAGE
        do {
            let mediaStackNews = try await mediaStackService.fetchLatestNews(
                countries: "it",    // Italy
                categories: "general,politics",
                languages: "it"     // Italian language
            )
            // Mark Italian language articles
            let italianArticles = mediaStackNews.map { article in
                var modified = article
                modified.metadata = (article.metadata ?? [:]).merging([
                    "language": "it",
                    "languageName": "Italian",
                    "needsTranslation": "true",
                    "source": "MediaStack",
                    "country": "Italy"
                ]) { _, new in new }
                return modified
            }
            articles.append(contentsOf: italianArticles.prefix(5))
            Logger.debug("✅ Fetched \(italianArticles.count) Italian language articles from MediaStack", category: .network)
        } catch {
            Logger.error("Failed to fetch from MediaStack: \(error)", category: .network)
        }
        
        // Add metadata to all articles
        return articles.map { article in
            var modified = article
            // Keep existing metadata if already set
            if modified.metadata?["language"] == nil {
                modified.metadata = (article.metadata ?? [:]).merging([
                    "country": "Italy",
                    "region": "Europe",
                    "category": "Politics",
                    "local": "true",
                    "language": "en"  // Guardian articles are in English
                ]) { _, new in new }
            }
            return modified
        }
    }
    
    // MARK: - Regional Politics (EU for Italy)
    
    /// Fetch regional politics (EU, neighboring countries)
    private func fetchRegionalPolitics() async throws -> [Article] {
        let country = locationService.detectedCountry
        
        switch country.code {
        case "IT", "FR", "DE", "ES", "NL", "BE", "AT", "PT", "GR":
            // European countries - fetch EU politics
            return try await fetchEUPolitics()
        default:
            return []
        }
    }
    
    /// Fetch EU politics - European Parliament, Commission, Council
    func fetchEUPolitics() async throws -> [Article] {
        Logger.debug("🇪🇺 Fetching EU politics", category: .network)
        
        let euNews = try await guardianService.fetchLatestNews(
            section: "world",
            pageSize: 20
        )
        
        // Filter for EU politics
        let euFiltered = euNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            let euKeywords = [
                "european union", "eu", "brussels",
                "european parliament", "european commission",
                "ursula von der leyen", "eu council",
                "eurozone", "schengen", "brexit"
            ]
            return euKeywords.contains(where: { keyword in
                title.contains(keyword) || description.contains(keyword)
            })
        }
        
        return euFiltered.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "region": "Europe",
                "organization": "EU",
                "category": "Politics"
            ]) { _, new in new }
            return modified
        }
    }
    
    // MARK: - Global Politics
    
    /// Fetch global political news from major countries
    func fetchGlobalPolitics() async throws -> [Article] {
        var articles: [Article] = []
        
        Logger.debug("🌍 Fetching global politics", category: .network)
        
        // Fetch from Guardian Politics section
        let guardianPolitics = try await guardianService.fetchLatestNews(
            section: "politics",
            pageSize: 15
        )
        articles.append(contentsOf: guardianPolitics)
        
        // Fetch from NYTimes Politics (if available)
        do {
            let nytPolitics = try await nyTimesService.fetchTopStories(section: "politics")
            articles.append(contentsOf: nytPolitics.prefix(10))
        } catch {
            Logger.error("NYTimes not available: \(error)", category: .network)
        }
        
        // Add metadata
        return articles.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "category": "Politics",
                "scope": "Global"
            ]) { _, new in new }
            return modified
        }
    }
    
    // MARK: - Country-Specific Politics
    
    /// Fetch UK politics - Parliament, PM, Government
    func fetchUKPolitics() async throws -> [Article] {
        Logger.debug("🇬🇧 Fetching UK politics", category: .network)
        
        let ukNews = try await guardianService.fetchLatestNews(
            section: "politics",
            pageSize: 20
        )
        
        let ukFiltered = ukNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            let ukKeywords = [
                "uk", "britain", "british", "westminster",
                "downing street", "parliament", "labour",
                "conservative", "sunak", "starmer"
            ]
            return ukKeywords.contains(where: { keyword in
                title.contains(keyword) || description.contains(keyword)
            })
        }
        
        return ukFiltered.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "country": "United Kingdom",
                "category": "Politics",
                "local": "true"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch US politics - White House, Congress, Elections
    func fetchUSPolitics() async throws -> [Article] {
        Logger.debug("🇺🇸 Fetching US politics", category: .network)
        
        var articles: [Article] = []
        
        // NYTimes Politics
        do {
            let nytPolitics = try await nyTimesService.fetchTopStories(section: "politics")
            articles.append(contentsOf: nytPolitics)
        } catch {
            Logger.error("NYTimes not available: \(error)", category: .network)
        }
        
        // Guardian US Politics
        let guardianUS = try await guardianService.fetchLatestNews(
            section: "us-news",
            pageSize: 15
        )
        articles.append(contentsOf: guardianUS)
        
        return articles.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "country": "United States",
                "category": "Politics",
                "local": "true"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch French politics
    func fetchFrenchPolitics() async throws -> [Article] {
        Logger.debug("🇫🇷 Fetching French politics", category: .network)
        
        let frenchNews = try await guardianService.fetchLatestNews(
            section: "world",
            pageSize: 20
        )
        
        let frenchFiltered = frenchNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            let frenchKeywords = [
                "france", "french", "paris", "macron",
                "élysée", "assemblée", "le pen"
            ]
            return frenchKeywords.contains(where: { keyword in
                title.contains(keyword) || description.contains(keyword)
            })
        }
        
        return frenchFiltered.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "country": "France",
                "category": "Politics",
                "local": "true"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch German politics
    func fetchGermanPolitics() async throws -> [Article] {
        Logger.debug("🇩🇪 Fetching German politics", category: .network)
        
        let germanNews = try await guardianService.fetchLatestNews(
            section: "world",
            pageSize: 20
        )
        
        let germanFiltered = germanNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            let germanKeywords = [
                "germany", "german", "berlin", "scholz",
                "bundestag", "merkel", "afd"
            ]
            return germanKeywords.contains(where: { keyword in
                title.contains(keyword) || description.contains(keyword)
            })
        }
        
        return germanFiltered.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "country": "Germany",
                "category": "Politics",
                "local": "true"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch Spanish politics
    func fetchSpanishPolitics() async throws -> [Article] {
        Logger.debug("🇪🇸 Fetching Spanish politics", category: .network)
        
        let spanishNews = try await guardianService.fetchLatestNews(
            section: "world",
            pageSize: 20
        )
        
        let spanishFiltered = spanishNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            let spanishKeywords = [
                "spain", "spanish", "madrid", "sánchez",
                "catalonia", "barcelona", "vox"
            ]
            return spanishKeywords.contains(where: { keyword in
                title.contains(keyword) || description.contains(keyword)
            })
        }
        
        return spanishFiltered.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "country": "Spain",
                "category": "Politics",
                "local": "true"
            ]) { _, new in new }
            return modified
        }
    }
    
    // MARK: - Helper Methods
    
    private func removeDuplicates(from articles: [Article]) -> [Article] {
        var seen = Set<String>()
        return articles.filter { article in
            let url = article.url
            return seen.insert(url).inserted
        }
    }
}

// MARK: - Political Topics

extension PoliticalNewsService {
    /// Get political topics based on location
    func getLocalPoliticalTopics() -> [String] {
        let country = locationService.detectedCountry
        
        switch country.code {
        case "IT":
            return [
                "Giorgia Meloni",
                "Italian Government",
                "Italian Parliament",
                "Fratelli d'Italia",
                "EU-Italy Relations",
                "Italian Politics"
            ]
        case "GB":
            return [
                "UK Parliament",
                "Prime Minister",
                "Labour Party",
                "Conservative Party",
                "Westminster"
            ]
        case "US":
            return [
                "White House",
                "US Congress",
                "Presidential Elections",
                "Democrats",
                "Republicans"
            ]
        case "FR":
            return [
                "Emmanuel Macron",
                "French Parliament",
                "Élysée Palace",
                "French Politics"
            ]
        case "DE":
            return [
                "Olaf Scholz",
                "Bundestag",
                "German Government",
                "German Politics"
            ]
        default:
            return [
                "Global Politics",
                "International Relations",
                "World Leaders"
            ]
        }
    }
}
