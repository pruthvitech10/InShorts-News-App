//
//  FirebaseAuthenticationManager.swift
//  Newssss
//
//  Firebase Authentication Manager with Google Sign-In support
//  Created on 6 November 2025.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import SwiftUI


// MARK: - AuthenticationManager

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: AppUser? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    var isAuthenticated: Bool { currentUser != nil }
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Listen for auth state changes
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user?.toAppUser()
            }
        }
        
        // Set initial user
        if let user = Auth.auth().currentUser {
            currentUser = user.toAppUser()
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Get the client ID from Firebase configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }

        // Configure Google Sign-In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Get the presenting view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        do {
            // Start Google Sign-In flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user

            guard let idToken = user.idToken?.tokenString else {
                throw AuthError.missingIDToken
            }

            let accessToken = user.accessToken.tokenString

            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            // Sign in to Firebase
            let authResult = try await Auth.auth().signIn(with: credential)

            // Update current user
            currentUser = authResult.user.toAppUser()

            Logger.debug("Successfully signed in with Google: \(authResult.user.email ?? "no email")", category: .auth)

        } catch {
            errorMessage = error.localizedDescription
            Logger.error("Google Sign-In failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }
    
    // : - Anonymous Sign-In
    
    func signInAnonymously() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let authResult = try await Auth.auth().signInAnonymously()
            currentUser = authResult.user.toAppUser()
            Logger.debug("Successfully signed in anonymously", category: .auth)
        } catch {
            errorMessage = error.localizedDescription
            Logger.error("Anonymous sign-in failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }
    
    // : - Sign Out
    
    func signOut() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Sign out from Google
            GIDSignIn.sharedInstance.signOut()

            // Sign out from Firebase
            try Auth.auth().signOut()

            currentUser = nil
            Logger.debug("Successfully signed out", category: .auth)
        } catch {
            errorMessage = error.localizedDescription
            Logger.error("Sign-out failed: \(error.localizedDescription)", category: .auth)
            throw error
        }
    }
}

// MARK: - AuthError

// : - Auth Errors

enum AuthError: LocalizedError {
    case missingClientID
    case noRootViewController
    case missingIDToken
    
    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing Google Client ID. Please check your Firebase configuration."
        case .noRootViewController:
            return "Unable to present sign-in screen. Please try again."
        case .missingIDToken:
            return "Failed to get authentication token from Google."
        }
    }
}

// : - Firebase User Extension

extension FirebaseAuth.User {
    func toAppUser() -> AppUser {
        AppUser(
            id: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL?.absoluteString,
            phoneNumber: phoneNumber,
            isEmailVerified: isEmailVerified,
            createdAt: metadata.creationDate ?? Date(),
            lastSignInAt: metadata.lastSignInDate ?? Date()
        )
    }
}
