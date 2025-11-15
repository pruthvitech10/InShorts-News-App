//
//  ProfileTabView.swift
//  Newssss
//
//  Profile tab with sign-in options
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

struct ProfileTabView: View {
    @State private var isSignedIn = false
    @State private var isGuest = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    var body: some View {
        Group {
            if isSignedIn || isGuest {
                // Show existing ProfileView with all its features
                ProfileView()
                    .environmentObject(AuthenticationManager.shared)
                    .environmentObject(localizationManager)
            } else {
                // Show sign-in options
                signInView
            }
        }
    }
    
    private var signInView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon
            Image(systemName: "newspaper.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            // Title
            Text("Welcome to InShorts")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Sign in to sync your preferences across devices")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Sign-in buttons
            VStack(spacing: 16) {
                // Google Sign-In Button
                Button(action: {
                    signInWithGoogle()
                }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .disabled(isLoading)
                
                // Guest Button
                Button(action: {
                    continueAsGuest()
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.title2)
                        Text("Continue as Guest")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                if isLoading {
                    ProgressView()
                        .padding(.top, 10)
                }
                
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 40)
            
            // Features
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "bookmark.fill", text: "Save your favorite articles")
                FeatureRow(icon: "clock.fill", text: "Track your reading history")
                FeatureRow(icon: "sparkles", text: "Get personalized recommendations")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func signInWithGoogle() {
        isLoading = true
        showError = false
        
        // Check if Firebase is configured
        guard FirebaseApp.app() != nil else {
            errorMessage = "Google Sign-In is not available"
            showError = true
            isLoading = false
            return
        }
        
        Task {
            do {
                // Try to sign in with Google
                try await AuthenticationManager.shared.signInWithGoogle()
                await MainActor.run {
                    isSignedIn = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Sign-in failed. Please try again."
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func continueAsGuest() {
        // No authentication needed - just mark as guest
        withAnimation {
            isGuest = true
        }
        HapticFeedback.success()
        Logger.debug("✅ User continued as guest", category: .general)
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(text)
        }
    }
}

#Preview {
    ProfileTabView()
}
