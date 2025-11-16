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
    
    private let italianNewsService = ItalianNewsService.shared
    private let locationService = LocationService.shared
    
    private init() {}
    
    // MARK: - Main Fetch Methods
    
    /// Fetch political news with location-aware prioritization
    /// In Italy: Giorgia Meloni, Italian government, EU politics
    /// Global: US, UK, EU, Asia, Middle East politics
    func fetchPoliticalNews(limit: Int = Int.max) async throws -> [Article] {
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
        
        return sorted  // Return ALL articles, no limit
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
        
        // Fetch from Italian News Service ONLY
        do {
            let italianNews = try await italianNewsService.fetchItalianNews(category: "politics", limit: 50)
            articles.append(contentsOf: italianNews)
            Logger.debug("✅ Fetched \(italianNews.count) Italian political articles", category: .network)
        } catch {
            Logger.error("Failed to fetch Italian politics: \(error)", category: .network)
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
                    "language": "it"  // Italian articles
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
        
        // Guardian removed - return empty array
        return []
    }
    
    // MARK: - Global Politics
    
    /// Fetch global political news from major countries
    func fetchGlobalPolitics() async throws -> [Article] {
        Logger.debug("🌍 Fetching global politics", category: .network)
        
        // Guardian removed - return empty array
        return []
    }
    
    // MARK: - Country-Specific Politics
    
    /// Fetch UK politics - Parliament, PM, Government
    func fetchUKPolitics() async throws -> [Article] {
        Logger.debug("🇬🇧 Fetching UK politics", category: .network)
        
        // Guardian removed - return empty array
        return []
    }
    
    /// Fetch US politics - White House, Congress, Elections
    func fetchUSPolitics() async throws -> [Article] {
        Logger.debug("🇺🇸 Fetching US politics", category: .network)
        
        // Guardian removed - return empty array
        return []
    }
    
    /// Fetch French politics
    func fetchFrenchPolitics() async throws -> [Article] {
        Logger.debug("🇫🇷 Fetching French politics", category: .network)
        
        // Guardian removed - return empty array
        return []
    }
    
    /// Fetch German politics
    func fetchGermanPolitics() async throws -> [Article] {
        Logger.debug("🇩🇪 Fetching German politics", category: .network)
        
        // Guardian removed - return empty array
        return []
    }
    
    /// Fetch Spanish politics
    func fetchSpanishPolitics() async throws -> [Article] {
        Logger.debug("🇪🇸 Fetching Spanish politics", category: .network)
        
        // Guardian removed - return empty array
        return []
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
