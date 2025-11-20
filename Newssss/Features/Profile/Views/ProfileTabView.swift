//
//  ProfileTabView.swift
//  Newssss
//
//  Profile tab with sign-in options
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import AuthenticationServices

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
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign Out") {
                                // Reset to login screen
                                withAnimation {
                                    isSignedIn = false
                                    isGuest = false
                                }
                                HapticFeedback.success()
                            }
                            .foregroundColor(.red)
                        }
                    }
            } else {
                // Show sign-in options
                signInView
            }
        }
    }
    
    private var signInView: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "#FF6B35").opacity(0.05), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App Icon and Name
                VStack(spacing: 20) {
                    Image("AppIconDisplay")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: Color(hex: "#FF6B35").opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Text("InShorts")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Stay informed in 60 words")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 60)
                
                // Sign-in buttons
                VStack(spacing: 14) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = AuthenticationManager.shared.generateNonce()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = AuthenticationManager.shared.sha256(nonce)
                        },
                        onCompletion: { result in
                            signInWithApple(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .disabled(isLoading)
                    
                    // Google Sign-In Button
                    Button(action: {
                        signInWithGoogle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            Text("Sign in with Google")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading)
                    
                    // Guest Button
                    Button(action: {
                        continueAsGuest()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text("Continue as Guest")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FF6B35"), Color(hex: "#FF8C61")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "#FF6B35").opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isLoading)
                    
                    if isLoading {
                        ProgressView()
                            .tint(Color(hex: "#FF6B35"))
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
    }
    
    // Sign in actions
    
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
    
    private func signInWithApple(result: Result<ASAuthorization, Error>) {
        isLoading = true
        showError = false
        
        Task {
            do {
                switch result {
                case .success(let authorization):
                    try await AuthenticationManager.shared.signInWithApple(authorization: authorization)
                    await MainActor.run {
                        isSignedIn = true
                        isLoading = false
                    }
                case .failure(let error):
                    throw error
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Apple Sign-in failed. Please try again."
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

// Helper views

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
