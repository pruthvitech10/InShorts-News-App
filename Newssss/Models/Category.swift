//
//  Category.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

// Category - Ordered by importance and content richness
enum NewsCategory: String, CaseIterable, Codable {
    case general      // 1. All categories combined (first)
    case politics     // 2. 9 sources - Most important Italian news
    case sports       // 3. 7 sources - Very popular in Italy (calcio!)
    case business     // 4. 8 sources - Economy & finance
    case technology   // 5. 8 sources - Tech & innovation
    case world        // 6. 8 sources - International news
    case entertainment // 7. 7 sources - Cinema, music, TV
    case crime        // 8. 8 sources - Daily crime & justice
    case lifestyle    // 9. 8 sources - Food, fashion, travel
    case automotive   // 10. 7 sources - Cars & motorsport
    case history      // 11. Personal reading history (last)
    
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
