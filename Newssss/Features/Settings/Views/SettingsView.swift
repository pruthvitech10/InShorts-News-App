//
//  SettingsView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            locationSection
            preferencesSection
            notificationsSection
            updatesSection
            aiSection
            resetSection
            aboutSection
        }
        .navigationTitle("Settings")
    }
    
    private var locationSection: some View {
        Section(header: Text("Location & Language")) {
            NavigationLink(destination: LocationSettingsView()) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("News Location")
                        Text(LocationService.shared.detectedCountry.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        Section(header: Text("Preferences")) {
            Picker("Default Category", selection: $viewModel.userSettings.preferredCategory) {
                ForEach(NewsCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category)
                }
            }
            .onChange(of: viewModel.userSettings.preferredCategory) { _ in
                viewModel.updateSettings()
            }
            
            Picker("Font Size", selection: $viewModel.userSettings.fontSize) {
                ForEach(UserSettings.FontSize.allCases, id: \.self) { size in
                    Text(size.rawValue.capitalized).tag(size)
                }
            }
            .onChange(of: viewModel.userSettings.fontSize) { _ in
                viewModel.updateSettings()
            }
        }
    }
    
    private var notificationsSection: some View {
        Section(header: Text("Notifications")) {
            Toggle("Enable Notifications", isOn: $viewModel.userSettings.notificationsEnabled)
                .onChange(of: viewModel.userSettings.notificationsEnabled) { _ in
                    viewModel.updateSettings()
                }
        }
    }
    
    private var updatesSection: some View {
        Section(header: Text("Updates")) {
            Toggle("Auto Refresh", isOn: $viewModel.userSettings.autoRefreshEnabled)
                .onChange(of: viewModel.userSettings.autoRefreshEnabled) { _ in
                    viewModel.updateSettings()
                }
        }
    }
    
    private var aiSection: some View {
        Section(header: Text("Smart Feed & AI")) {
            Toggle(isOn: Binding(
                get: { UserDefaults.standard.bool(forKey: "use_ai_summaries") },
                set: { newValue in
                    UserDefaults.standard.set(newValue, forKey: "use_ai_summaries")
                    NotificationCenter.default.post(
                        name: Notification.Name("UseAISummariesChanged"),
                        object: newValue
                    )
                }
            )) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    Text("AI Summaries")
                }
            }
            
            Text("Enable or disable AI-generated summaries in the Smart Feed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var resetSection: some View {
        Section {
            Button("Reset to Defaults") {
                viewModel.resetToDefaults()
            }
            .foregroundColor(.red)
        }
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
