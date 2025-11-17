//
//  Newss.swift
//  Newss
//
//  Created on 29 October 2025.
//  Updated on 15 November 2025 - Fixed Firebase initialization.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import Combine
import os.log

// CRITICAL: Global Firebase initialization barrier
class FirebaseInitializer {
    static let shared = FirebaseInitializer()
    private(set) var isReady = false
    private let lock = NSLock()
    
    private init() {}
    
    func configure() {
        lock.lock()
        defer { lock.unlock() }
        
        // Check if already configured
        if isReady {
            Logger.debug("✅ Firebase already configured", category: .general)
            return
        }
        
        // Check if Firebase config file exists
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            Logger.debug("⚠️ Firebase config missing (development mode)", category: .general)
            return
        }
        
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.debug("🔥 Firebase configured successfully", category: .general)
        }
        
        // CRITICAL: Set ready flag AFTER configuration completes
        isReady = true
        Logger.debug("✅ Firebase initialization complete - ready for fetching", category: .general)
    }
    
    func waitUntilReady(timeout: TimeInterval = 5.0) async -> Bool {
        let start = Date()
        while !isReady {
            if Date().timeIntervalSince(start) > timeout {
                Logger.debug("⚠️ Firebase initialization timeout", category: .general)
                return false
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        }
        return true
    }
}

// App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // CRITICAL: Configure Firebase FIRST, IMMEDIATELY
        FirebaseInitializer.shared.configure()
        
        // Register background tasks
        BackgroundRefreshService.shared.registerBackgroundTasks()
        
        Logger.debug("🔄 Background refresh configured", category: .general)
        return true
    }
}

// Main App

@main
struct Newss: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var localizationManager = LocalizationManager.shared
    
    init() {
        // CRITICAL: Start auto-refresh AFTER Firebase is ready
        Task {
            // Wait for Firebase to be ready
            let ready = await FirebaseInitializer.shared.waitUntilReady()
            if ready {
                Logger.debug("🚀 Firebase ready - starting auto-refresh", category: .general)
                BackgroundRefreshService.shared.startAutoRefresh()
            } else {
                Logger.debug("❌ Firebase not ready - skipping auto-refresh", category: .general)
            }
        }
        
        // Request location in background (doesn't need Firebase)
        Task {
            LocationService.shared.startUpdatingLocation()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(localizationManager)
        }
    }
}

// Main Tab View

struct MainTabView: View {
    @State private var authManager: AuthenticationManager? = nil
    
    var body: some View {
        authenticatedView
    }
    
    private var authenticatedView: some View {
        TabView {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                Label("Feed", systemImage: "newspaper")
            }
            
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            NavigationStack {
                BookmarksView()
            }
            .tabItem {
                Label("Saved", systemImage: "bookmark")
            }
            
            NavigationStack {
                ProfileTabView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
        }
    }
    
    private var unauthenticatedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "newspaper.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to News")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please sign in to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    if let authManager = authManager {
                        try? await authManager.signInAnonymously()
                    }
                }
            }) {
                Text("Continue as Guest")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

#Preview {
    MainTabView()
}
