//
//  ErrorLogger.swift
//  Newssss
//
//  Centralized error logging service for production and debug environments
//  Created on 6 November 2025.
//

import Foundation
import os.log

// Centralized error logging
class ErrorLogger {
    static let shared = ErrorLogger()
    
    private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.newsshorts", category: "app")
    
    private init() {}
    
    // Log errors with context
    /// - Parameters:
    ///   - error: The error to log
    ///   - context: Context string describing where the error occurred
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    static func log(_ error: Error,
                    context: String,
                    file: String = #file,
                    function: String = #function,
                    line: Int = #line) {
        shared.logError(error, context: context, file: file, function: function, line: line)
    }
    
    /// Log a critical error that may cause app malfunction
    static func logCritical(_ error: Error,
                            context: String,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line) {
        shared.logCriticalError(error, context: context, file: file, function: function, line: line)
    }
    
    /// Log a warning (non-fatal issue)
    static func logWarning(_ message: String,
                           context: String = "",
                           file: String = #file,
                           function: String = #function,
                           line: Int = #line) {
        shared.logWarningMessage(message, context: context, file: file, function: function, line: line)
    }
    
    /// Log informational message (DEBUG only)
    static func logInfo(_ message: String,
                        context: String = "") {
        #if DEBUG
        shared.logInfoMessage(message, context: context)
        #endif
    }
    
    // Internal logging logic
    
    private func logError(_ error: Error,
                         context: String,
                         file: String,
                         function: String,
                         line: Int) {
        let filename = (file as NSString).lastPathComponent
        let errorMessage = "\(context): \(error.localizedDescription)"
        
        #if DEBUG
        // Debug: Print to console with full details
        print("❌ ERROR [\(filename):\(line) \(function)]")
        print("   Context: \(context)")
        print("   Error: \(error.localizedDescription)")
        if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error {
            print("   Underlying: \(underlyingError.localizedDescription)")
        }
        #else
        // Production: Log using os.log (viewable in Console.app)
        logger.error("\(errorMessage, privacy: .public)")
        
        // Note: Integrate crash reporting service when ready (Firebase Crashlytics, Sentry)
        #endif
    }
    
    private func logCriticalError(_ error: Error,
                                 context: String,
                                 file: String,
                                 function: String,
                                 line: Int) {
        let filename = (file as NSString).lastPathComponent
        let errorMessage = "\(context): \(error.localizedDescription)"
        
        #if DEBUG
        print("🔴 CRITICAL ERROR [\(filename):\(line) \(function)]")
        print("   Context: \(context)")
        print("   Error: \(error.localizedDescription)")
        #else
        logger.critical("\(errorMessage, privacy: .public)")
        
        // Note: Critical errors should trigger immediate notification in production
        #endif
    }
    
    private func logWarningMessage(_ message: String,
                                  context: String,
                                  file: String,
                                  function: String,
                                  line: Int) {
        let filename = (file as NSString).lastPathComponent
        
        #if DEBUG
        print("⚠️ WARNING [\(filename):\(line) \(function)]")
        if !context.isEmpty {
            print("   Context: \(context)")
        }
        print("   Message: \(message)")
        #else
        logger.warning("\(context): \(message, privacy: .public)")
        #endif
    }
    
    private func logInfoMessage(_ message: String, context: String) {
        if !context.isEmpty {
            print("ℹ️ [\(context)] \(message)")
        } else {
            print("ℹ️ \(message)")
        }
    }
}

// Helper methods

extension ErrorLogger {
    /// Log network errors with specific context
    static func logNetworkError(_ error: Error, url: String) {
        log(error, context: "Network request failed for: \(url)")
    }
    
    /// Log API errors with response code
    static func logAPIError(_ error: Error, statusCode: Int, endpoint: String) {
        log(error, context: "API Error [\(statusCode)] at \(endpoint)")
    }
    
    /// Log database errors
    static func logDatabaseError(_ error: Error, operation: String) {
        log(error, context: "Database operation failed: \(operation)")
    }
    
    /// Log authentication errors
    static func logAuthError(_ error: Error, context: String = "Authentication") {
        log(error, context: context)
    }
}

// Usage examples
/*
 
 // Example 1: Log general error
 do {
     try someOperation()
 } catch {
     ErrorLogger.log(error, context: "Failed to perform operation")
 }
 
 // Example 2: Log network error
 ErrorLogger.logNetworkError(error, url: "https://api.example.com")
 
 // Example 3: Log critical error
 ErrorLogger.logCritical(error, context: "App initialization failed")
 
 // Example 4: Log warning
 ErrorLogger.logWarning("API key not found", context: "Configuration")
 
 // Example 5: Log info (DEBUG only)
 ErrorLogger.logInfo("Fetching articles...", context: "FeedViewModel")
 
 */
