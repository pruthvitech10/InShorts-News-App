//
//  Category.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

enum NewsCategory: String, CaseIterable, Codable {
    case general
    case politics
    case sports
    case business
    case technology
    case world
    case entertainment
    case crime
    case lifestyle
    case automotive
    case recentlySeen
    
    var displayName: String {
        switch self {
        case .recentlySeen:
            return "Recently Seen"
        default:
            return rawValue.capitalized
        }
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
        case .recentlySeen:
            return "clock.arrow.circlepath"
        }
    }
}
