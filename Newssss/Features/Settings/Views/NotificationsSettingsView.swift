//
//  NotificationsSettingsView.swift
//  Newssss
//
//  Created on 10 November 2025.
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var breakingNewsEnabled = true
    @State private var dailyDigestEnabled = false
    @State private var digestTime = Date()
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { newValue in
                        if newValue {
                            requestNotificationPermission()
                        }
                    }
                
                if !notificationsEnabled {
                    Text("Enable notifications to stay updated with breaking news")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Notifications")
            }
            
            if notificationsEnabled {
                Section {
                    Toggle("Breaking News", isOn: $breakingNewsEnabled)
                    
                    Text("Get notified about important breaking news")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("News Alerts")
                }
                
                Section {
                    Toggle("Daily Digest", isOn: $dailyDigestEnabled)
                    
                    if dailyDigestEnabled {
                        DatePicker("Delivery Time", selection: $digestTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Text("Receive a daily summary of top news")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Daily Updates")
                }
            }
            
            Section {
                Button("Open System Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } footer: {
                Text("Manage notification settings in the iOS Settings app")
                    .font(.caption)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkNotificationStatus()
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                notificationsEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive news alerts")
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationsEnabled = true
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        NotificationsSettingsView()
    }
}
