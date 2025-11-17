//
//  ProfileView.swift
//  DailyNews
//

import SwiftUI


// User profile screen

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var vm = ProfileViewModel()
    @State private var showSignIn = false
    
    var body: some View {
        NavigationView {
            // Always show profile content (as guest if not signed in)
            AuthenticatedView(
                user: authManager.currentUser ?? AppUser(id: "guest", email: "guest@local", displayName: "Guest User"),
                localizationManager: localizationManager,
                onSignOut: {
                    Task {
                        try? await authManager.signOut()
                    }
                }
            )
            .navigationTitle(localizationManager.localized("profile.title"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// Logged in user view

private struct AuthenticatedView: View {
    let user: AppUser
    let localizationManager: LocalizationManager
    let onSignOut: () -> Void
    
    @State private var showAvatarEditor = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Location Debug Card
                LocationDebugCard()
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
            // Profile card
                // Profile header card
                VStack(spacing: 20) {
                    // Avatar with edit button
                    ZStack(alignment: .bottomTrailing) {
                        Avatar(url: user.photoURL, initials: user.initials)
                        
                        // Edit button
                        Button(action: {
                            showAvatarEditor = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemBackground))
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                            }
                        }
                        .offset(x: 5, y: 5)
                    }
                    
                    VStack(spacing: 8) {
                        if let name = user.displayName {
                            Text(name)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        if let email = user.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                
                Spacer()
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // Settings section
            VStack(alignment: .leading, spacing: 0) {
                Text(localizationManager.localized("profile.settings"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 12)
                
                    VStack(spacing: 0) {
                        NavigationLink(destination: BookmarksView()) {
                            SettingsRowContent(icon: "bookmark.fill", title: "Bookmarks", iconColor: .yellow)
                        }
                        
                        NavigationLink(destination: NotificationsSettingsView()) {
                            SettingsRowContent(icon: "bell.fill", title: localizationManager.localized("profile.notifications"), iconColor: .orange)
                        }
                        
                        NavigationLink(destination: LanguageSettingsView().environmentObject(localizationManager)) {
                            SettingsRowContent(icon: "character.textbox", title: localizationManager.localized("profile.language"), iconColor: .blue)
                        }
                        
                        NavigationLink(destination: PrivacySettingsView()) {
                            SettingsRowContent(icon: "lock.fill", title: localizationManager.localized("profile.privacy"), iconColor: .green)
                        }
                    
                        NavigationLink(destination: AboutView()) {
                            SettingsRowContent(icon: "info.circle.fill", title: localizationManager.localized("profile.about"), iconColor: .purple, showDivider: false)
                        }
                    }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Clear History button
            Button(action: {
                SeenArticlesService.shared.clearSeenArticles()
                Logger.debug("🗑️ Cleared all seen articles history", category: .general)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                    Text("Clear History (\(SeenArticlesService.shared.getSeenCount()) seen)")
                        .font(.headline)
                }
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // Sign out button
            Button(action: onSignOut) {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Text(localizationManager.localized("profile.signOut"))
                        .font(.headline)
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())

    }
}

// Stat display

private struct StatView: View {
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Settings row

private struct SettingsRowContent: View {
    let icon: String
    let title: String
    let iconColor: Color
    var showDivider: Bool = true
    var showBadge: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if showBadge {
                    Text("AI")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            if showDivider {
                Divider()
                    .padding(.leading, 60)
            }
        }
    }
}



// User avatar

private struct Avatar: View {
    let url: String?
    let initials: String
    
    var body: some View {
        Group {
            if let url = url, let imgUrl = URL(string: url) {
                AsyncImage(url: imgUrl) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    InitialsView(initials: initials)
                }
            } else {
                InitialsView(initials: initials)
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 2))
    }
}

// User initials

private struct InitialsView: View {
    let initials: String
    
    var body: some View {
        ZStack {
            Circle().fill(Color.accentColor.gradient)
            Text(initials)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// User interest model

struct UserInterest: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Double // 0.0 to 1.0 (AI confidence score)
    let icon: String
    let color: Color
}

// Topic data model

private struct TopicData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let percentage: Int
    let color: Color
    let icon: String
}

// Source data model

private struct SourceData: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let logo: String
    let color: Color
}

// Reading statistics

private struct ReadingStats {
    var avgReadingTimeMinutes: Double = 0
    var mostActiveDay: String = ""
    var totalArticles: Int = 0
    var weeklyGrowth: Int = 0
    var categoryBreakdown: [(String, Int)] = []
}

// Location Debug Card

struct LocationDebugCard: View {
    @State private var detectedCountry = LocationService.shared.detectedCountry
    @State private var showCountryPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                Text("Detected Location")
                    .font(.headline)
                Spacer()
                Button("Change") {
                    showCountryPicker = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack {
                Text("Country:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(detectedCountry.displayName)
                    .fontWeight(.semibold)
            }
            
            Text("News will be personalized for this location")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerView(selectedCountry: $detectedCountry)
        }
        .onReceive(NotificationCenter.default.publisher(for: .locationDidUpdate)) { _ in
            detectedCountry = LocationService.shared.detectedCountry
        }
    }
}

// Country Picker

struct CountryPickerView: View {
    @Binding var selectedCountry: LocationService.CountryInfo
    @Environment(\.dismiss) var dismiss
    
    let countries = [
        ("IT", "Italy"),
        ("US", "United States"),
        ("GB", "United Kingdom"),
        ("FR", "France"),
        ("DE", "Germany"),
        ("ES", "Spain"),
        ("IN", "India"),
        ("JP", "Japan"),
        ("AU", "Australia"),
        ("CA", "Canada")
    ]
    
    var body: some View {
        NavigationView {
            List(countries, id: \.0) { code, name in
                Button(action: {
                    LocationService.shared.updateCountryCode(code)
                    selectedCountry = LocationService.shared.detectedCountry
                    dismiss()
                }) {
                    HStack {
                        Text(name)
                        Spacer()
                        if code.lowercased() == selectedCountry.code {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Helper extensions

private extension Binding where Value == String? {
    func isNotNil() -> Binding<Bool> {
        Binding<Bool>(
            get: { self.wrappedValue != nil },
            set: { if !$0 { self.wrappedValue = nil } }
        )
    }
}

