//
//  PrivacySettingsView.swift
//  dailynews
//
//  Privacy settings with cache management
//

import SwiftUI
import Combine


// PrivacySettingsView

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PrivacySettingsViewModel()
    
    var body: some View {
        List {
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
    @Published var cacheSize = "Calculating..."
    
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    private let defaults = UserDefaults.standard
    
    init() {
        // Initialize
    }
    
    // Setup
    
    func checkAuthorizationStatuses() async {
        await calculateCacheSize()
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
    
    // Helpers
    
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
