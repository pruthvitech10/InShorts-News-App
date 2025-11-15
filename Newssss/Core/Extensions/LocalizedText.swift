//
//  LocalizedText.swift
//  Newssss
//
//  Helper for using localized strings in SwiftUI
//  Created on 6 November 2025.
//

import SwiftUI

// MARK: - LocalizedText View

/// A SwiftUI view that displays localized text
/// Automatically updates when the app language changes
struct LocalizedText: View {
    let key: String
    let arguments: [CVarArg]
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    init(_ key: String, _ arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }
    
    var body: some View {
        Text(localizedString)
    }
    
    private var localizedString: String {
        let format = localizationManager.localized(key)
        guard !arguments.isEmpty else { return format }
        return String(format: format, arguments: arguments)
    }
}

// MARK: - String Extension

extension String {
    /// Returns a localized version of this string key
    /// - Parameter manager: The LocalizationManager to use (optional, uses shared instance by default)
    func localized(using manager: LocalizationManager? = nil) -> String {
        (manager ?? LocalizationManager.shared).localized(self)
    }
    
    /// Returns a localized version with format arguments
    func localized(_ arguments: CVarArg..., using manager: LocalizationManager? = nil) -> String {
        let format = (manager ?? LocalizationManager.shared).localized(self)
        guard !arguments.isEmpty else { return format }
        return String(format: format, arguments: arguments)
    }
}

// MARK: - View Extensions

extension View {
    /// Creates a Text view with localized content
    /// - Parameters:
    ///   - key: The localization key
    ///   - arguments: Optional format arguments
    /// - Returns: A Text view with localized string
    func localizedText(_ key: String, _ arguments: CVarArg...) -> some View {
        modifier(LocalizedTextModifier(key: key, arguments: arguments))
    }
}

// MARK: - Text Extensions

extension Text {
    /// Creates a Text view with a localized string
    /// - Parameters:
    ///   - key: The localization key
    ///   - arguments: Optional format arguments
    init(localized key: String, _ arguments: CVarArg...) {
        let manager = LocalizationManager.shared
        let format = manager.localized(key)
        if arguments.isEmpty {
            self.init(format)
        } else {
            self.init(String(format: format, arguments: arguments))
        }
    }
    
    /// Creates a Text view with a localized string using a specific manager
    init(localized key: String, using manager: LocalizationManager, _ arguments: CVarArg...) {
        let format = manager.localized(key)
        if arguments.isEmpty {
            self.init(format)
        } else {
            self.init(String(format: format, arguments: arguments))
        }
    }
}

// MARK: - Private Helpers

private struct LocalizedTextModifier: ViewModifier {
    let key: String
    let arguments: [CVarArg]
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    func body(content: Content) -> some View {
        Text(localizedString)
    }
    
    private var localizedString: String {
        let format = localizationManager.localized(key)
        guard !arguments.isEmpty else { return format }
        return String(format: format, arguments: arguments)
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// Sets localized placeholder text for TextField
    func localizedPlaceholder(_ key: String) -> some View {
        self.modifier(LocalizedPlaceholderModifier(key: key))
    }
}

private struct LocalizedPlaceholderModifier: ViewModifier {
    let key: String
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    func body(content: Content) -> some View {
        content.overlay(
            Text(localizationManager.localized(key))
                .foregroundColor(.gray.opacity(0.5))
                .allowsHitTesting(false),
            alignment: .leading
        )
    }
}

// MARK: - LocalizedStringKey Extension

extension LocalizedStringKey {
    /// Creates a LocalizedStringKey from a custom localization key
    static func custom(_ key: String) -> LocalizedStringKey {
        let localized = LocalizationManager.shared.localized(key)
        return LocalizedStringKey(localized)
    }
}

// MARK: - Common UI Components with Localization

extension LocalizedText {
    // Commonly used localized texts as static constructors
    
    static var loading: LocalizedText {
        LocalizedText("common.loading")
    }
    
    static var error: LocalizedText {
        LocalizedText("common.error")
    }
    
    static var retry: LocalizedText {
        LocalizedText("common.retry")
    }
    
    static var cancel: LocalizedText {
        LocalizedText("common.cancel")
    }
    
    static var save: LocalizedText {
        LocalizedText("common.save")
    }
    
    static var delete: LocalizedText {
        LocalizedText("common.delete")
    }
    
    static var share: LocalizedText {
        LocalizedText("common.share")
    }
    
    static var close: LocalizedText {
        LocalizedText("common.close")
    }
}

// MARK: - Preview Helper

#if DEBUG
extension LocalizationManager {
    /// Creates a preview instance with mock data
    static var preview: LocalizationManager {
        // Use the shared instance for previews
        return LocalizationManager.shared
    }
}
#endif
