//
//  AppConstants.swift
//  Newssss
//

import Foundation
import UIKit

enum AppConstants {
    static let appName = "InShorts"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    static let firebaseStorageURL = "gs://news-8b080.firebasestorage.app/news/"
    
    static let categories = [
        "politics", "sports", "technology", "entertainment",
        "business", "world", "crime", "automotive", "lifestyle"
    ]
    
    static let backgroundRefreshIntervalMinutes: Int = 20
    static let cacheValidityMinutes: Int = 60
    static let refreshTaskIdentifier = "com.newssss.refresh"
    
    static let maxArticleAge: TimeInterval = 48 * 60 * 60
    static let minSentenceLength = 20
    
    static let cardCornerRadius: CGFloat = 24
    static let defaultPadding: CGFloat = 16
    static let animationDuration: TimeInterval = 0.3
}
