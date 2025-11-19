//
//  Newss.swift
//  Newss
//
//  Created on 29 October 2025.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import Combine
import os.log

class FirebaseInitializer {
    static let shared = FirebaseInitializer()
    private(set) var isReady = false
    private let lock = NSLock()
    
    private init() {}
    
    func configure() {
        lock.lock()
        defer { lock.unlock() }
        
        if isReady {
            Logger.debug("Firebase already configured", category: .general)
            return
        }
        
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            Logger.debug("Firebase config missing", category: .general)
            return
        }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.debug("Firebase configured", category: .general)
        }
        
        isReady = true
        Logger.debug("Firebase ready", category: .general)
    }
    
    func waitUntilReady(timeout: TimeInterval = 5.0) async -> Bool {
        let start = Date()
        while !isReady {
            if Date().timeIntervalSince(start) > timeout {
                Logger.debug("Firebase init timeout", category: .general)
                return false
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return true
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseInitializer.shared.configure()
        BackgroundRefreshService.shared.registerBackgroundTasks()
        Logger.debug("Background refresh configured", category: .general)
        return true
    }
}

@main
struct Newss: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showSplash = true
    
    init() {
        Task {
            let ready = await FirebaseInitializer.shared.waitUntilReady()
            if ready {
                Logger.debug("Starting auto-refresh", category: .general)
                BackgroundRefreshService.shared.startAutoRefresh()
            } else {
                Logger.debug("Skipping auto-refresh", category: .general)
            }
        }
        
        Task {
            LocationService.shared.startUpdatingLocation()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(localizationManager)
                
                if showSplash {
                    SplashScreenView(isActive: $showSplash)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
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
