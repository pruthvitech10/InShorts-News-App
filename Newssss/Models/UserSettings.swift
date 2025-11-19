//
//  UserSettings.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation

struct UserSettings: Codable {
    var preferredCategory: NewsCategory
    var fontSize: FontSize
    var notificationsEnabled: Bool
    var autoRefreshEnabled: Bool
    var theme: AppTheme
    var preferredCountry: String
    var preferredLanguage: String
    var localNewsPercentage: Int
    
    static let `default` = UserSettings(
        preferredCategory: NewsCategory.general,
        fontSize: .medium,
        notificationsEnabled: true,
        autoRefreshEnabled: true,
        theme: .system,
        preferredCountry: "it",
        preferredLanguage: "it",
        localNewsPercentage: 70
    )
    
    enum FontSize: String, CaseIterable, Codable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case extraLarge = "Extra Large"
        
        var scale: CGFloat {
            switch self {
            case .small:
                return 0.9
            case .medium:
                return 1.0
            case .large:
                return 1.1
            case .extraLarge:
                return 1.2
            }
        }
    }
    
    enum AppTheme: String, CaseIterable, Codable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var displayName: String {
            rawValue
        }
    }
}
