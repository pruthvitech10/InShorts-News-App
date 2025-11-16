//
//  AppConfig.swift
//  Newssss
//
//  Main app configuration
//

import Foundation
import UIKit

struct AppConfig {
    
    // MARK: - App Info
    
    static let appName = "InShorts"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - News Settings
    
    static let defaultCategory = "general"
    static let articlesPerPage = 100
    static let maxArticlesInMemory = 1000
    
    // MARK: - Network Settings
    
    static let requestTimeout: TimeInterval = 30
    static let resourceTimeout: TimeInterval = 60
    static let maxConcurrentRequests = 10
    static let retryAttempts = 2
    static let retryDelay: TimeInterval = 1.0
    
    // MARK: - UI Settings
    
    static let animationDuration: Double = 0.3
    static let cardCornerRadius: CGFloat = 24
    static let defaultPadding: CGFloat = 16
    
    // MARK: - Feature Flags
    
    static let enableBackgroundRefresh = true
    static let enableInfiniteScrolling = true
    static let enableSearch = true
    static let enableBreakingNews = true
    
    // MARK: - Debug
    
    #if DEBUG
    static let isDebug = true
    static let verboseLogging = true
    #else
    static let isDebug = false
    static let verboseLogging = false
    #endif
}
