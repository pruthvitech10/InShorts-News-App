//
//  Category.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

// Category
enum NewsCategory: String, CaseIterable, Codable {
    case general
    case politics
    case business
    case technology
    case entertainment
    case sports
    case world
    case crime
    case automotive
    case lifestyle
    case history
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .general:
            return "newspaper"
        case .politics:
            return "building.columns"
        case .business:
            return "briefcase"
        case .technology:
            return "laptopcomputer"
        case .entertainment:
            return "theatermasks"
        case .sports:
            return "sportscourt"
        case .world:
            return "globe.europe.africa"
        case .crime:
            return "exclamationmark.shield"
        case .automotive:
            return "car"
        case .lifestyle:
            return "fork.knife"
        case .history:
            return "clock.arrow.circlepath"
        }
    }
    
    /// NewsData.io uses different category names than NewsAPI.org
    /// This property maps our categories to NewsData.io's categories
    var newsDataIOCategory: String? {
        switch self {
        case .general:
            return "top"  // NewsData.io uses "top" instead of "general"
        case .politics:
            return "politics"
        case .business:
            return "business"
        case .technology:
            return "technology"
        case .entertainment:
            return "entertainment"
        case .sports:
            return "sports"
        case .world:
            return "world"
        case .crime:
            return "crime"
        case .automotive:
            return "auto"
        case .lifestyle:
            return "lifestyle"
        case .history:
            return nil  // History is local-only, not fetched from API
        }
    }
    
    /// GNews.io category mapping
    /// GNews uses "topic" parameter with specific values
    var gNewsCategory: String? {
        switch self {
        case .general:
            return "breaking-news"
        case .politics:
            return "nation"
        case .business:
            return "business"
        case .technology:
            return "technology"
        case .entertainment:
            return "entertainment"
        case .sports:
            return "sports"
        case .world:
            return "world"
        case .crime:
            return "nation"
        case .automotive:
            return "business"
        case .lifestyle:
            return "entertainment"
        case .history:
            return nil
        }
    }
    
    /// RapidAPI category mapping for search queries
    var rapidAPIQuery: String {
        switch self {
        case .general:
            return "breaking news"
        case .politics:
            return "politics"
        case .business:
            return "business"
        case .technology:
            return "technology"
        case .entertainment:
            return "entertainment"
        case .sports:
            return "sports"
        case .world:
            return "world news"
        case .crime:
            return "crime"
        case .automotive:
            return "automotive"
        case .lifestyle:
            return "lifestyle"
        case .history:
            return "history"
        }
    }
}
