//
//  UserSettings.swift
//  DailyNews
//
//  Created on 3 November 2025.
//

import Foundation


// User Settings
struct UserSettings: Codable {
    var preferredCategory: NewsCategory
    var fontSize: FontSize
    var notificationsEnabled: Bool
    var autoRefreshEnabled: Bool
    var theme: AppTheme
    var preferredCountry: String
    var preferredLanguage: String
    var localNewsPercentage: Int // 0-100, how much local vs global news
    
    // Default Settings
    static let `default` = UserSettings(
        preferredCategory: NewsCategory.general,
        fontSize: .medium,
        notificationsEnabled: true,
        autoRefreshEnabled: true,
        theme: .system,
        preferredCountry: "it", // Italy
        preferredLanguage: "it", // Italian
        localNewsPercentage: 70 // 70% local, 30% global
    )
    
    // Font Size
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
    
    // App Theme
    enum AppTheme: String, CaseIterable, Codable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var displayName: String {
            rawValue
        }
    }
}
