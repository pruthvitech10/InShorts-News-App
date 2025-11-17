//
//  AppConstants.swift
//  Newssss
//
//  ALL app configuration in ONE place
//

import Foundation
import UIKit

enum AppConstants {
    
    // MARK: - App Info
    static let appName = "InShorts"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    // MARK: - Firebase
    static let firebaseStorageURL = "gs://news-8b080.firebasestorage.app/news/"
    
    // MARK: - News Categories
    static let categories = [
        "politics", "sports", "technology", "entertainment",
        "business", "world", "crime", "automotive", "lifestyle"
    ]
    
    // MARK: - Background Refresh
    static let backgroundRefreshIntervalMinutes: Int = 20
    static let cacheValidityMinutes: Int = 60
    static let refreshTaskIdentifier = "com.newssss.refresh"
    
    // MARK: - Article Settings
    static let maxArticleAge: TimeInterval = 48 * 60 * 60  // 48 hours
    static let minSentenceLength = 20
    
    // MARK: - UI Constants
    static let cardCornerRadius: CGFloat = 24
    static let defaultPadding: CGFloat = 16
    static let animationDuration: TimeInterval = 0.3
}
