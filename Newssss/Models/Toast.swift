//
//  Toast.swift
//  DailyNews
//
//  Created on 13 November 2025.
//

import SwiftUI

public struct Toast: Equatable {
    var style: ToastStyle
    var message: String
    var duration: Double = 3
    var isUserInteractionEnabled: Bool = false
}

public enum ToastStyle {
    case error
    case warning
    case success
    case info
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        case .info: return .blue
        }
    }
    
    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}
