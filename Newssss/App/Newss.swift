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
    @AppStorage("userSettings") private var settingsData: Data = Data()
    @State private var selectedTab = 0
    
    private var userSettings: UserSettings {
        (try? JSONDecoder().decode(UserSettings.self, from: settingsData)) ?? .default
    }
    
    private var preferredColorScheme: ColorScheme? {
        switch userSettings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
    
    var body: some View {
        authenticatedView
            .preferredColorScheme(preferredColorScheme)
    }
    
    private var authenticatedView: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                FeedView()
            }
            .tabItem {
                CustomTabItem(
                    icon: "doc.text.fill",
                    title: "Feed",
                    isSelected: selectedTab == 0
                )
            }
            .tag(0)
            
            NavigationStack {
                SearchView()
            }
            .tabItem {
                CustomTabItem(
                    icon: "magnifyingglass",
                    title: "Search",
                    isSelected: selectedTab == 1
                )
            }
            .tag(1)
            
            NavigationStack {
                BookmarksView()
            }
            .tabItem {
                CustomTabItem(
                    icon: "bookmark.fill",
                    title: "Saved",
                    isSelected: selectedTab == 2
                )
            }
            .tag(2)
            
            NavigationStack {
                ProfileTabView()
            }
            .tabItem {
                CustomTabItem(
                    icon: "person.circle.fill",
                    title: "Profile",
                    isSelected: selectedTab == 3
                )
            }
            .tag(3)
        }
        .tint(Color(hex: "#FF6B35"))
        .onAppear {
            setupTabBarAppearance()
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
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Background color
        appearance.backgroundColor = UIColor.systemBackground
        
        // Shadow for depth
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        appearance.shadowImage = UIImage()
        
        // Selected item color (orange)
        let selectedColor = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)
        let unselectedColor = UIColor.systemGray
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        
        // Inline appearance (for compact layouts)
        appearance.inlineLayoutAppearance.normal.iconColor = unselectedColor
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: unselectedColor
        ]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor
        ]
        
        // Compact appearance
        appearance.compactInlineLayoutAppearance.normal.iconColor = unselectedColor
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// Custom Tab Item
struct CustomTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                .symbolEffect(.bounce, value: isSelected)
            
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
        }
    }
}

#Preview {
    MainTabView()
}
