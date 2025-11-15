//
//  PrivacySettingsView.swift
//  dailynews
//
//  Privacy settings with biometric lock
//

import SwiftUI
import LocalAuthentication
import Combine


// PrivacySettingsView

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PrivacySettingsViewModel()
    
    var body: some View {
        List {
            biometricLockSection
            cacheSection
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.checkAuthorizationStatuses() }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .onChange(of: viewModel.biometricLockEnabled) { _ in viewModel.saveSettings() }
        .onChange(of: viewModel.lockBookmarks) { _ in viewModel.saveSettings() }
    }
    
    // Biometric lock settings
    
    private var biometricLockSection: some View {
        Section {
            Toggle(isOn: $viewModel.biometricLockEnabled) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.biometricAuthType)
                        Text("Require authentication to open app")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: viewModel.biometricIcon)
                        .foregroundColor(.blue)
                }
            }
            .onChange(of: viewModel.biometricLockEnabled) { _, newValue in
                if newValue {
                    Task { await viewModel.authenticateBiometric() }
                }
            }
            
            if viewModel.biometricLockEnabled {
                Toggle(isOn: $viewModel.lockBookmarks) {
                    Label {
                        Text("Require authentication for bookmarks")
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.yellow)
                    }
                }
            }
        } header: {
            Text("Security")
        } footer: {
            if !viewModel.biometricAvailable {
                Text("Biometric authentication is not available on this device")
            }
        }
    }
    
    // Cache management
    
    private var cacheSection: some View {
        Section {
            HStack {
                Label("Cached Data", systemImage: "internaldrive.fill")
                Spacer()
                Text(viewModel.cacheSize)
                    .foregroundColor(.secondary)
            }
            
            Button(role: .destructive) {
                viewModel.clearCache()
            } label: {
                Label("Clear Cache & Refresh Feed", systemImage: "arrow.clockwise.circle.fill")
            }
            
            Button(role: .destructive) {
                viewModel.clearReadingHistory()
            } label: {
                Label("Clear Reading History", systemImage: "book.closed.fill")
            }
        } header: {
            Text("Storage")
        } footer: {
            Text("Free up space by removing cached articles and images")
        }
    }
}

// Privacy settings view model

@MainActor
final class PrivacySettingsViewModel: ObservableObject {
    @Published var biometricLockEnabled = false
    @Published var lockBookmarks = false
    @Published var biometricAvailable = false
    @Published var biometricAuthType = "Biometric Lock"
    @Published var biometricIcon = "faceid"
    
    @Published var cacheSize = "Calculating..."
    
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let context = LAContext()
    private let defaults = UserDefaults.standard
    
    init() {
        loadSettings()
        checkBiometricAvailability()
    }
    
    // Setup
    
    func checkAuthorizationStatuses() async {
        await calculateCacheSize()
    }
    
    // Biometric Authentication
    
    private func checkBiometricAvailability() {
        var error: NSError?
        biometricAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        switch context.biometryType {
        case .faceID:
            biometricAuthType = "Face ID Lock"
            biometricIcon = "faceid"
        case .touchID:
            biometricAuthType = "Touch ID Lock"
            biometricIcon = "touchid"
        case .opticID:
            biometricAuthType = "Optic ID Lock"
            biometricIcon = "opticid"
        case .none:
            biometricAuthType = "Biometric Lock"
            biometricIcon = "lock.fill"
        @unknown default:
            biometricAuthType = "Biometric Lock"
            biometricIcon = "lock.fill"
        }
    }
    
    func authenticateBiometric() async {
        guard biometricAvailable else {
            showAlertMessage(title: "Not Available", message: "Biometric authentication is not available on this device")
            biometricLockEnabled = false
            return
        }
        
        let reason = "Authenticate to enable biometric lock"
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            
            if !success {
                biometricLockEnabled = false
            }
        } catch {
            Logger.error("Biometric authentication failed: \(error)", category: .general)
            showAlertMessage(title: "Authentication Failed", message: error.localizedDescription)
            biometricLockEnabled = false
        }
    }
    
    // Cache Management
    
    func calculateCacheSize() async {
        let fileManager = FileManager.default
        
        guard let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            cacheSize = "Unknown"
            return
        }
        
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                do {
                    let attributes = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                    totalSize += Int64(attributes.fileSize ?? 0)
                } catch {
                    continue
                }
            }
        }
        
        cacheSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    func clearCache() {
        // No NewsCache anymore - just clear file cache
        let fileManager = FileManager.default
        
        guard let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        
        do {
            let cacheContents = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil)
            for file in cacheContents {
                try fileManager.removeItem(at: file)
            }
            
            // Post notification to refresh feeds
            NotificationCenter.default.post(name: NSNotification.Name("CacheClearedRefreshFeed"), object: nil)
            
            showAlertMessage(title: "Cache Cleared", message: "All cached data has been removed. Pull down on the feed to refresh with latest news.")
            Task { await calculateCacheSize() }
            
            Logger.debug("🗑️ Cache cleared successfully", category: .general)
        } catch {
            Logger.error("Failed to clear cache: \(error)", category: .general)
            showAlertMessage(title: "Error", message: "Failed to clear cache")
        }
    }
    
    func clearReadingHistory() {
        // Clear reading history from UserDefaults
        defaults.removeObject(forKey: "ReadArticles")
        defaults.synchronize()
        
        showAlertMessage(title: "History Cleared", message: "Your reading history has been removed")
        Logger.debug("📚 Reading history cleared", category: .general)
    }
    
    // Persistence
    
    private func loadSettings() {
        biometricLockEnabled = defaults.bool(forKey: "BiometricLockEnabled")
        lockBookmarks = defaults.bool(forKey: "LockBookmarks")
    }
    
    func saveSettings() {
        defaults.set(biometricLockEnabled, forKey: "BiometricLockEnabled")
        defaults.set(lockBookmarks, forKey: "LockBookmarks")
    }
    
    private func showAlertMessage(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// Preview

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
