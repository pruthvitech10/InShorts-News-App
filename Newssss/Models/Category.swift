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
}
