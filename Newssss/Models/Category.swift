//
//  Category.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

// MARK: - Category
enum NewsCategory: String, CaseIterable, Codable {
    case forYou
    case general
    case politics
    case business
    case technology
    case entertainment
    case sports
    case science
    case health
    case history
    
    var displayName: String {
        switch self {
        case .forYou:
            return "For You"
        default:
            return rawValue.capitalized
        }
    }
    
    var icon: String {
        switch self {
        case .forYou:
            return "person.crop.circle"
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
        case .science:
            return "flask"
        case .health:
            return "cross.case"
        case .history:
            return "clock.arrow.circlepath"
        }
    }
    
    /// NewsData.io uses different category names than NewsAPI.org
    /// This property maps our categories to NewsData.io's categories
    var newsDataIOCategory: String? {
        switch self {
        case .forYou:
            return nil // "For You" is a personalized feed, not a direct API category
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
        case .science:
            return "science"
        case .health:
            return "health"
        case .history:
            return nil  // History is local-only, not fetched from API
        }
    }
}
