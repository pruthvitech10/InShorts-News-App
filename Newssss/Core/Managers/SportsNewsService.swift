//
//  SportsNewsService.swift
//  Newssss
//
//  Sports news aggregator with location-aware team focus
//  Prioritizes local teams (e.g., SSC Napoli in Naples)
//  Free tier: Multiple sources combined
//  Created on 16 November 2025.
//

import Foundation

// MARK: - Sports News Service

class SportsNewsService {
    static let shared = SportsNewsService()
    
    private let guardianService = GuardianAPIService.shared
    private let locationService = LocationService.shared
    
    private init() {}
    
    // MARK: - Main Fetch Methods
    
    /// Fetch sports news with location-aware team prioritization
    func fetchSportsNews(limit: Int = 20) async throws -> [Article] {
        let userLocation = locationService.detectedCountry
        var articles: [Article] = []
        
        // Fetch from The Guardian Sports section
        let guardianSports = try await fetchGuardianSports()
        articles.append(contentsOf: guardianSports)
        
        // If user is in Italy, prioritize Serie A and Italian teams
        if userLocation.code.uppercased() == "IT" {
            Logger.debug("🇮🇹 User in Italy - prioritizing Italian football", category: .network)
            let italianFootball = try await fetchItalianFootballNews()
            articles.insert(contentsOf: italianFootball, at: 0)
        }
        
        // Remove duplicates
        let uniqueArticles = removeDuplicates(from: articles)
        
        // Sort by date
        let sorted = uniqueArticles.sorted { $0.publishedAt > $1.publishedAt }
        
        return Array(sorted.prefix(limit))
    }
    
    /// Fetch Napoli-specific news (when in Naples/Italy)
    func fetchNapoliNews() async throws -> [Article] {
        var articles: [Article] = []
        
        // Fetch Guardian football section (will include Napoli news)
        let napoliNews = try await guardianService.fetchLatestNews(
            section: "football",
            pageSize: 20
        )
        // Filter for Napoli-related articles
        let napoliFiltered = napoliNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            return title.contains("napoli") || description.contains("napoli")
        }
        articles.append(contentsOf: napoliFiltered)
        
        // Add metadata to mark as Napoli-specific
        return articles.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "team": "SSC Napoli",
                "league": "Serie A",
                "sport": "Football"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch Serie A news
    func fetchSerieANews() async throws -> [Article] {
        let serieANews = try await guardianService.fetchLatestNews(
            section: "football",
            pageSize: 20
        )
        // Filter for Serie A-related articles
        let serieAFiltered = serieANews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            return title.contains("serie a") || title.contains("italian") || 
                   description.contains("serie a") || description.contains("italian")
        }
        
        return serieANews.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "league": "Serie A",
                "sport": "Football"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch Champions League news
    func fetchChampionsLeagueNews() async throws -> [Article] {
        let clNews = try await guardianService.fetchLatestNews(
            section: "football",
            pageSize: 20
        )
        // Filter for Champions League articles
        let clFiltered = clNews.filter { article in
            let title = article.title.lowercased()
            let description = (article.description ?? "").lowercased()
            return title.contains("champions league") || description.contains("champions league")
        }
        
        return clNews.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "tournament": "Champions League",
                "sport": "Football"
            ]) { _, new in new }
            return modified
        }
    }
    
    /// Fetch general football news
    func fetchFootballNews() async throws -> [Article] {
        let footballNews = try await guardianService.fetchLatestNews(
            section: "football",
            pageSize: 20
        )
        
        return footballNews.map { article in
            var modified = article
            modified.metadata = (article.metadata ?? [:]).merging([
                "sport": "Football"
            ]) { _, new in new }
            return modified
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchGuardianSports() async throws -> [Article] {
        // Fetch from Guardian's sport section
        let sports = try await guardianService.fetchLatestNews(
            section: "sport",
            pageSize: 20
        )
        return sports
    }
    
    private func fetchItalianFootballNews() async throws -> [Article] {
        var italianNews: [Article] = []
        
        // Priority 1: Napoli (if in Naples area)
        if isInNaplesArea() {
            do {
                let napoliNews = try await fetchNapoliNews()
                italianNews.append(contentsOf: napoliNews.prefix(5))
            } catch {
                Logger.error("Failed to fetch Napoli news: \(error)", category: .network)
            }
        }
        
        // Priority 2: Serie A
        do {
            let serieA = try await fetchSerieANews()
            italianNews.append(contentsOf: serieA.prefix(5))
        } catch {
            Logger.error("Failed to fetch Serie A news: \(error)", category: .network)
        }
        
        // Priority 3: Italian teams in Europe
        do {
            let europeanNews = try await guardianService.fetchLatestNews(
                section: "football",
                pageSize: 20
            )
            // Filter for Italian teams
            let italianTeamsNews = europeanNews.filter { article in
                let title = article.title.lowercased()
                let description = (article.description ?? "").lowercased()
                let italianTeams = ["napoli", "inter", "milan", "juventus", "roma", "atalanta", "lazio"]
                return italianTeams.contains(where: { team in
                    title.contains(team) || description.contains(team)
                })
            }
            italianNews.append(contentsOf: italianTeamsNews.prefix(3))
        } catch {
            Logger.error("Failed to fetch Italian teams news: \(error)", category: .network)
        }
        
        return italianNews
    }
    
    private func isInNaplesArea() -> Bool {
        let location = locationService.detectedCountry
        // TODO: Add more precise location detection for Naples/Campania region
        // For now, return true if in Italy
        return location.code.uppercased() == "IT"
    }
    
    private func removeDuplicates(from articles: [Article]) -> [Article] {
        var seen = Set<String>()
        return articles.filter { article in
            let url = article.url
            return seen.insert(url).inserted
        }
    }
}

// MARK: - Sports-Specific Models

struct SportsTeam {
    let name: String
    let league: String
    let country: String
    let logoURL: String?
}

struct Match {
    let homeTeam: String
    let awayTeam: String
    let date: Date
    let competition: String
    let score: String?
    let status: MatchStatus
}

enum MatchStatus: String {
    case scheduled = "Scheduled"
    case live = "Live"
    case finished = "Finished"
    case postponed = "Postponed"
}

// MARK: - Popular Teams by Region

extension SportsNewsService {
    /// Get popular teams based on user location
    func getLocalTeams() -> [SportsTeam] {
        let country = locationService.detectedCountry
        let countryCode = country.code.uppercased()
        
        switch countryCode {
        case "IT":
            return [
                SportsTeam(name: "SSC Napoli", league: "Serie A", country: "Italy", logoURL: nil),
                SportsTeam(name: "Inter Milan", league: "Serie A", country: "Italy", logoURL: nil),
                SportsTeam(name: "AC Milan", league: "Serie A", country: "Italy", logoURL: nil),
                SportsTeam(name: "Juventus", league: "Serie A", country: "Italy", logoURL: nil),
                SportsTeam(name: "AS Roma", league: "Serie A", country: "Italy", logoURL: nil)
            ]
        case "GB":
            return [
                SportsTeam(name: "Manchester United", league: "Premier League", country: "England", logoURL: nil),
                SportsTeam(name: "Liverpool", league: "Premier League", country: "England", logoURL: nil),
                SportsTeam(name: "Arsenal", league: "Premier League", country: "England", logoURL: nil),
                SportsTeam(name: "Chelsea", league: "Premier League", country: "England", logoURL: nil)
            ]
        case "ES":
            return [
                SportsTeam(name: "Real Madrid", league: "La Liga", country: "Spain", logoURL: nil),
                SportsTeam(name: "Barcelona", league: "La Liga", country: "Spain", logoURL: nil),
                SportsTeam(name: "Atletico Madrid", league: "La Liga", country: "Spain", logoURL: nil)
            ]
        case "DE":
            return [
                SportsTeam(name: "Bayern Munich", league: "Bundesliga", country: "Germany", logoURL: nil),
                SportsTeam(name: "Borussia Dortmund", league: "Bundesliga", country: "Germany", logoURL: nil)
            ]
        case "FR":
            return [
                SportsTeam(name: "Paris Saint-Germain", league: "Ligue 1", country: "France", logoURL: nil),
                SportsTeam(name: "Marseille", league: "Ligue 1", country: "France", logoURL: nil)
            ]
        default:
            // Global popular teams
            return [
                SportsTeam(name: "Real Madrid", league: "La Liga", country: "Spain", logoURL: nil),
                SportsTeam(name: "Barcelona", league: "La Liga", country: "Spain", logoURL: nil),
                SportsTeam(name: "Manchester United", league: "Premier League", country: "England", logoURL: nil)
            ]
        }
    }
    
    /// Get search queries for local teams
    func getLocalTeamQueries() -> [String] {
        return getLocalTeams().map { $0.name }
    }
}
