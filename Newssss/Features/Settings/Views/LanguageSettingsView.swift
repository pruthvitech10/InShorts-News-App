//
//  LanguageSettingsView.swift
//  dailynews
//
//  Language and localization settings using Locale framework
//

import SwiftUI
import Combine


// MARK: - LanguageSettingsView

struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LanguageSettingsViewModel()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        List {
            currentLanguageSection
            availableLanguagesSection
        }
        .navigationTitle(localizationManager.localized("language.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Current Language Section
    
    private var currentLanguageSection: some View {
        Section {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localized("language.current"))
                            .font(.body)
                        Text(localizationManager.currentLanguage.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(localizationManager.currentLanguage.flag)
                    .font(.title)
            }
        } footer: {
            Text(localizationManager.localized("language.interfaceDescription"))
        }
    }
    
    // MARK: - Available Languages Section
    
    private var availableLanguagesSection: some View {
        Section {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    localizationManager.changeLanguage(language)
                    viewModel.currentLanguage = language
                } label: {
                    HStack(spacing: 16) {
                        Text(language.flag)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(language.displayName)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(language.nativeName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if language == localizationManager.currentLanguage {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text(localizationManager.localized("language.available"))
        } footer: {
            Text(localizationManager.localized("language.selectPreferred"))
        }
    }
}

// MARK: - LanguageSettingsViewModel

@MainActor
final class LanguageSettingsViewModel: ObservableObject {
    @Published var currentLanguage: AppLanguage
    
    private let defaults = UserDefaults.standard
    
    init() {
        // Load current language
        if let langCode = defaults.string(forKey: "AppLanguage"),
           let language = AppLanguage(rawValue: langCode) {
            currentLanguage = language
        } else {
            // Detect from system locale
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = AppLanguage(rawValue: systemLang) ?? .english
        }
    }
}

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case italian = "it"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case portuguese = "pt"
    case chinese = "zh"
    case japanese = "ja"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italian"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .portuguese: return "Portuguese"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        }
    }
    
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .portuguese: return "Português"
        case .chinese: return "中文"
        case .japanese: return "日本語"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .italian: return "🇮🇹"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .portuguese: return "🇵🇹"
        case .chinese: return "🇨🇳"
        case .japanese: return "🇯🇵"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
