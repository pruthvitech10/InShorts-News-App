//
//  SignInOptionsView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI


// Sign in options screen

struct SignInOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                // App logo
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.red)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "newspaper.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.white)
                    )

                Spacer().frame(height: 40)

                VStack(spacing: 16) {
                    SignInButton(
                        title: "Sign in with Google",
                        background: Color.white,
                        foreground: .primary,
                        border: Color.gray.opacity(0.4),
                        icon: "g.circle.fill"
                    ) {
                        performGoogleSignIn()
                    }
                    .disabled(isSigningIn)

                    SignInButton(
                        title: "Continue as Guest",
                        background: Color(red: 67/255, green: 197/255, blue: 164/255),
                        foreground: .white,
                        icon: "person.fill"
                    ) {
                        performAnonymousSignIn()
                    }
                    .disabled(isSigningIn)
                }
                .padding(.horizontal, 28)
                
                if isSigningIn {
                    ProgressView()
                        .padding()
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .navigationBarTitle("Welcome", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
        }
    }

    private func performGoogleSignIn() {
        isSigningIn = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.signInWithGoogle()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
                    isSigningIn = false
                }
            }
        }
    }
    
    private func performAnonymousSignIn() {
        isSigningIn = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.signInAnonymously()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
                    isSigningIn = false
                }
            }
        }
    }
}

// Sign in button

private struct SignInButton: View {
    var title: String
    var background: Color
    var foreground: Color = .white
    var border: Color? = nil
    var icon: String = "chevron.right"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(foreground)
                    .frame(width: 36, height: 36)

                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(foreground)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(background)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(border ?? Color.clear, lineWidth: border == nil ? 0 : 1)
            )
        }
        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    SignInOptionsView()
        .environmentObject(AuthenticationManager.shared)
}
