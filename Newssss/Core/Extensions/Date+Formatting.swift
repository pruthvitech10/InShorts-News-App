//
//  Date+Formatting.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation

extension Date {
    // Cached formatters for performance
    
    // Reuse formatter to avoid creating new ones
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter
    }()
    
    /// Cached date formatters for common styles
    private static var dateFormatters: [DateFormatter.Style: DateFormatter] = [:]
    
    private static func dateFormatter(style: DateFormatter.Style) -> DateFormatter {
        if let cached = dateFormatters[style] {
            return cached
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.doesRelativeDateFormatting = false
        dateFormatters[style] = formatter
        return formatter
    }
    
    // Show time like "2 hours ago"
    
    // Returns relative time string
    func timeAgoDisplay() -> String {
        Self.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns a smart relative time string with custom thresholds
    /// - For < 1 minute: "Just now"
    /// - For < 1 hour: "X minutes ago"
    /// - For < 24 hours: "X hours ago"
    /// - For < 7 days: "X days ago"
    /// - Otherwise: Full date
    func smartTimeAgo() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        // Future dates
        if interval < 0 {
            return "Just now"
        }
        
        // Less than 1 minute
        if interval < 60 {
            return "Just now"
        }
        
        // Less than 1 hour
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        }
        
        // Less than 24 hours
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }
        
        // Less than 7 days
        if interval < 604800 {
            let days = Int(interval / 86400)
            return days == 1 ? "1 day ago" : "\(days) days ago"
        }
        
        // More than 7 days - show full date
        return formatted(style: .medium)
    }
    
    /// Returns a compact relative time (e.g., "2h", "3d")
    func compactTimeAgo() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        if interval < 0 {
            return "now"
        }
        
        if interval < 60 {
            return "now"
        }
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        }
        
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        }
        
        if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
        
        if interval < 2592000 {  // ~30 days
            let weeks = Int(interval / 604800)
            return "\(weeks)w"
        }
        
        // More than 30 days
        let months = Int(interval / 2592000)
        return "\(months)mo"
    }
    
    // Standard date formatting
    
    // Format date using cached formatters
    func formatted(style: DateFormatter.Style = .medium) -> String {
        Self.dateFormatter(style: style).string(from: self)
    }
    
    /// Returns a formatted date and time string
    func formattedWithTime(dateStyle: DateFormatter.Style = .medium,
                          timeStyle: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    /// Returns a custom formatted string
    func formatted(format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    // Format dates for news articles
    
    // Show appropriate time format for news
    /// - For yesterday: "Yesterday"
    /// - For this week: Day name (e.g., "Monday")
    /// - For older: Full date
    func newsTimeDisplay(showTimeForToday: Bool = false) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            if showTimeForToday {
                return formatted(format: "h:mm a")
            }
            return smartTimeAgo()
        }
        
        if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        
        // Within the last 7 days
        if let daysAgo = calendar.dateComponents([.day], from: self, to: now).day,
           daysAgo < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"  // Day name
            return formatter.string(from: self)
        }
        
        // Older than 7 days
        return formatted(style: .medium)
    }
    
    // Helper methods
    
    // Check if date is recent
    var isFresh: Bool {
        let age = Date().timeIntervalSince(self)
        return age < Constants.Article.preferredAge
    }
    
    /// Check if the article is still valid (not too old)
    var isValid: Bool {
        let age = Date().timeIntervalSince(self)
        return age < Constants.Article.maxAge
    }
    
    /// Get the age of this date in seconds
    var age: TimeInterval {
        Date().timeIntervalSince(self)
    }
    
    /// Check if date is within a specific time range
    func isWithin(_ interval: TimeInterval) -> Bool {
        Date().timeIntervalSince(self) < interval
    }
}

// Parse date strings

extension Date {
    /// Parse ISO8601 date string (common in news APIs)
    static func from(iso8601String: String) -> Date? {
        let formatters: [ISO8601DateFormatter] = [
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: iso8601String) {
                return date
            }
        }
        
        return nil
    }
    
    /// Parse common date formats used by news APIs
    static func fromNewsAPI(_ string: String) -> Date? {
        // Try ISO8601 first
        if let date = from(iso8601String: string) {
            return date
        }
        
        // Common formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
}
