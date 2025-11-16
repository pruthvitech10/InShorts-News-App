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

// App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureFirebase()
        return true
    }
    
    /// Configures Firebase with proper error handling
    private func configureFirebase() {
        // Check if Firebase config file exists
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            Logger.debug("Firebase config missing (development mode - continuing without Firebase)", category: .general)
            return
        }
        
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            Logger.debug("Firebase configured successfully", category: .general)
        }
    }
}

// Main App

@main
struct Newss: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var localizationManager = LocalizationManager.shared
    
    init() {
        // Early Firebase configuration (before any Firebase-dependent code runs)
        if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
        }
        
        // Request location permission to show local news
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
        // Skip authentication completely - go straight to app
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
