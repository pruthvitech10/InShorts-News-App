//
//  Constants.swift
//  Newssss
//
//  App-wide constants and configuration
//

import Foundation
import UIKit

struct Constants {
    
    // MARK: - Background Refresh
    
    struct Refresh {
        static let interval: TimeInterval = 20 * 60  // 20 minutes
        static let taskIdentifier = "com.newssss.refresh"
    }
    
    // MARK: - Memory Store
    
    struct Memory {
        static let maxArticlesPerCategory = 1000
        static let staleDataThreshold: TimeInterval = 30 * 60  // 30 minutes
    }
    
    // MARK: - Article Settings
    
    struct Article {
        static let maxAge: TimeInterval = 48 * 60 * 60  // 48 hours
        static let preferredAge: TimeInterval = 24 * 60 * 60  // 24 hours
        static let minSummaryLength = 100
        static let minSentenceLength = 20
    }
    
    // MARK: - UI Configuration
    
    struct UI {
        static let animationDuration: TimeInterval = 0.3
        static let cardCornerRadius: CGFloat = 24
        static let defaultPadding: CGFloat = 16
        static let swipeThreshold: CGFloat = 120
        
        // Bookmark Cards
        static let bookmarkCardImageWidth: CGFloat = 80
        static let bookmarkCardImageHeight: CGFloat = 80
    }
    
    // MARK: - Search Configuration
    
    struct Search {
        static let minQueryLength = 2
        static let maxQueryLength = 200
        static let resultsLimit = 50
    }
    
    // MARK: - Summarization
    
    struct Summarization {
        static let keywordCount = 10
        static let sentenceCount = 3
        static let positionWeight = 0.3
        static let lengthWeight = 0.2
        static let keywordWeight = 0.5
    }
    
    // MARK: - Categories
    
    struct Categories {
        static let all = ["general", "politics", "business", "technology", "entertainment", "sports", "world", "crime", "automotive", "lifestyle"]
        static let important = ["politics", "world", "business", "general"]  // For breaking news
    }
}
