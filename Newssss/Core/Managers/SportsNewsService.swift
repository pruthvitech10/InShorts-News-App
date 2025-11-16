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
    
    private let italianNewsService = ItalianNewsService.shared
    private let locationService = LocationService.shared
    
    private init() {}
    
    // MARK: - Main Fetch Methods
    
    /// Fetch sports news with location-aware team prioritization
    func fetchSportsNews(limit: Int = 20) async throws -> [Article] {
        Logger.debug("⚽ Fetching Italian sports news", category: .network)
        
        // Fetch from Italian sports sources ONLY
        let italianSports = try await italianNewsService.fetchItalianNews(category: "sports", limit: 100)
        
        // Sort by date
        let sorted = italianSports.sorted { $0.publishedAt > $1.publishedAt }
        
        return Array(sorted.prefix(limit))
    }
    
    /// All sports methods now use Italian sources only
    func fetchNapoliNews() async throws -> [Article] {
        return try await italianNewsService.fetchItalianNews(category: "sports", limit: 50)
    }
    
    func fetchSerieANews() async throws -> [Article] {
        return try await italianNewsService.fetchItalianNews(category: "sports", limit: 50)
    }
    
    func fetchChampionsLeagueNews() async throws -> [Article] {
        return try await italianNewsService.fetchItalianNews(category: "sports", limit: 50)
    }
    
    func fetchFootballNews() async throws -> [Article] {
        return try await italianNewsService.fetchItalianNews(category: "sports", limit: 50)
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchGuardianSports() async throws -> [Article] {
        // Guardian removed - return empty array
        return []
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
        
        // Priority 3: Italian teams in Europe (Guardian removed - using Italian sources only)
        
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
