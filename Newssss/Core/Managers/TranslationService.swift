//
//  TranslationService.swift
//  DailyNews
//
//  Created on 5 November 2025.
//

import Foundation
import Combine
import Translation

// Translates articles to user's language

@MainActor
final class TranslationService: ObservableObject {
    static let shared = TranslationService()

    @Published var isTranslationAvailable: Bool = false

    private init() {
        checkTranslationAvailability()
    }

    /// Check if translation is available on this device
    private func checkTranslationAvailability() {
        if #available(iOS 17.4, *) {
            isTranslationAvailable = true
        } else {
            isTranslationAvailable = false
        }
    }

    /// Translate text to a target language (async, using Apple's Translate framework)
    @MainActor
    func translate(text: String, to targetLanguage: String) async throws -> String {
        guard !text.isEmpty else { return text }
        
        // If device language matches target, return original text
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
        if deviceLang == targetLanguage {
            return text
        }
        
        // Use iOS 17.4+ Translation framework
        if #available(iOS 17.4, *) {
            do {
                // Detect source language from text
                let sourceLanguage = Locale.Language(identifier: "it") // Italian (most common in your feed)
                let targetLang = Locale.Language(identifier: targetLanguage)
                
                let session = try TranslationSession(installedSource: sourceLanguage, target: targetLang)
                let response = try await session.translate(text)
                return response.targetText
            } catch {
                Logger.error("Translation failed: \(error.localizedDescription)", category: .general)
                return text // Return original on error
            }
        } else {
            // Translation not available on iOS < 17.4
            return text
        }
    }

    /// Get user's preferred language for translation
    func getUserPreferredLanguage() -> String {
        // Get device language
        let preferredLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        return preferredLanguage
    }

    /// Get display name for language code
    func getLanguageDisplayName(for code: String) -> String {
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }

    static let supportedLanguages: [String: String] = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "ru": "Russian",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "ar": "Arabic",
        "hi": "Hindi",
        "nl": "Dutch",
        "pl": "Polish",
        "tr": "Turkish",
    ]
}
