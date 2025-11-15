//
//  Logger.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation
import os.log

public struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.shortsnews"
    
    public enum LoggerCategory: String {
        case network = "Network"
        case persistence = "Persistence"
        case viewModel = "ViewModel"
        case view = "View"
        case auth = "Authentication"
        case general = "General"
    }
    
    nonisolated static func log(_ message: String, category: LoggerCategory = .general, type: OSLogType = .default) {
        let log = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("%{public}@", log: log, type: type, message)
    }
    
    nonisolated static func error(_ message: String, category: LoggerCategory = .general) {
        log(message, category: category, type: .error)
    }
    
    nonisolated static func debug(_ message: String, category: LoggerCategory = .general) {
        #if DEBUG
        log(message, category: category, type: .debug)
        #endif
    }
}
