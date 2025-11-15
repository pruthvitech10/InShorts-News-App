//
//  Location.swift
//  DailyNews
//

import Foundation
import Combine


// MARK: - SupportedCountry

enum SupportedCountry: String, CaseIterable, Codable {
    case italy = "it"
    case unitedStates = "us"
    case unitedKingdom = "gb"
    case france = "fr"
    case germany = "de"
    case spain = "es"
    case india = "in"
    case canada = "ca"
    case australia = "au"
    case japan = "jp"
    case brazil = "br"
    case mexico = "mx"
    case argentina = "ar"
    case netherlands = "nl"
    case belgium = "be"
    case switzerland = "ch"
    case austria = "at"
    case portugal = "pt"
    case greece = "gr"
    case poland = "pl"
    
    var displayName: String {
        switch self {
        case .italy: return "🇮🇹 Italy"
        case .unitedStates: return "🇺🇸 United States"
        case .unitedKingdom: return "🇬🇧 United Kingdom"
        case .france: return "🇫🇷 France"
        case .germany: return "🇩🇪 Germany"
        case .spain: return "🇪🇸 Spain"
        case .india: return "🇮🇳 India"
        case .canada: return "🇨🇦 Canada"
        case .australia: return "🇦🇺 Australia"
        case .japan: return "🇯🇵 Japan"
        case .brazil: return "🇧🇷 Brazil"
        case .mexico: return "🇲🇽 Mexico"
        case .argentina: return "🇦🇷 Argentina"
        case .netherlands: return "🇳🇱 Netherlands"
        case .belgium: return "🇧🇪 Belgium"
        case .switzerland: return "🇨🇭 Switzerland"
        case .austria: return "🇦🇹 Austria"
        case .portugal: return "🇵🇹 Portugal"
        case .greece: return "🇬🇷 Greece"
        case .poland: return "🇵🇱 Poland"
        }
    }
    
    var localName: String {
        switch self {
        case .italy: return "Italia"
        case .unitedStates: return "United States"
        case .unitedKingdom: return "United Kingdom"
        case .france: return "France"
        case .germany: return "Deutschland"
        case .spain: return "España"
        case .india: return "India"
        case .canada: return "Canada"
        case .australia: return "Australia"
        case .japan: return "日本"
        case .brazil: return "Brasil"
        case .mexico: return "México"
        case .argentina: return "Argentina"
        case .netherlands: return "Nederland"
        case .belgium: return "Belgique"
        case .switzerland: return "Schweiz"
        case .austria: return "Österreich"
        case .portugal: return "Portugal"
        case .greece: return "Ελλάδα"
        case .poland: return "Polska"
        }
    }
    
    var primaryLanguage: String {
        switch self {
        case .italy: return "it"
        case .unitedStates, .unitedKingdom, .canada, .australia, .india: return "en"
        case .france, .belgium: return "fr"
        case .germany, .austria, .switzerland: return "de"
        case .spain, .mexico, .argentina: return "es"
        case .japan: return "ja"
        case .brazil: return "pt"
        case .netherlands: return "nl"
        case .portugal: return "pt"
        case .greece: return "el"
        case .poland: return "pl"
        }
    }
    
    // Major cities for location detection
    var majorCities: [String] {
        switch self {
        case .italy:
            return ["Rome", "Milan", "Naples", "Turin", "Florence", "Venice", "Bologna", "Palermo"]
        case .unitedStates:
            return ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia"]
        case .unitedKingdom:
            return ["London", "Manchester", "Birmingham", "Liverpool", "Leeds", "Glasgow"]
        case .france:
            return ["Paris", "Marseille", "Lyon", "Toulouse", "Nice", "Nantes"]
        case .germany:
            return ["Berlin", "Munich", "Hamburg", "Frankfurt", "Cologne", "Stuttgart"]
        case .spain:
            return ["Madrid", "Barcelona", "Valencia", "Seville", "Zaragoza", "Málaga"]
        default:
            return []
        }
    }
}

// MARK: - LocationService
// LocationService is defined in Core/Services/LocationService.swift
