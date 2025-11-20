import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import GoogleSignIn
import Combine
import SwiftUI
import AuthenticationServices
import CryptoKit

@MainActor
final class FirebaseAuthenticationManager: ObservableObject {
    static let shared = FirebaseAuthenticationManager()
    
    @Published var currentUser: AppUser?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    // Apple Sign In - Store the nonce for verification
    private var currentNonce: String?
    
    private init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.updateCurrentUser(user)
            }
        }
    }
    
    private func updateCurrentUser(_ firebaseUser: User?) {
        if let user = firebaseUser {
            currentUser = AppUser(
                id: user.uid,
                email: user.email,
                displayName: user.displayName,
                photoURL: user.photoURL?.absoluteString,
                phoneNumber: user.phoneNumber,
                isEmailVerified: user.isEmailVerified,
                createdAt: user.metadata.creationDate ?? Date(),
                lastSignInAt: user.metadata.lastSignInDate ?? Date()
            )
            isAuthenticated = true
            Logger.debug("✅ User authenticated: \(user.displayName ?? user.email ?? "Unknown")", category: .general)
        } else {
            currentUser = nil
            isAuthenticated = false
            Logger.debug("🚪 User signed out", category: .general)
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Missing Firebase Client ID"
            ])
            errorMessage = error.localizedDescription
            throw error
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No root view controller"
            ])
            errorMessage = error.localizedDescription
            throw error
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to get ID token"
                ])
                errorMessage = error.localizedDescription
                throw error
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            updateCurrentUser(authResult.user)
            
            Logger.debug("✅ Google Sign-In successful: \(authResult.user.displayName ?? "User")", category: .general)
            
        } catch {
            Logger.error("❌ Google Sign-In failed: \(error.localizedDescription)", category: .general)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid Apple ID credentials"
            ])
            errorMessage = error.localizedDescription
            throw error
        }
        
        guard let nonce = currentNonce else {
            let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."
            ])
            errorMessage = error.localizedDescription
            throw error
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to fetch identity token"
            ])
            errorMessage = error.localizedDescription
            throw error
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let error = NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to serialize token string from data"
            ])
            errorMessage = error.localizedDescription
            throw error
        }
        
        // Initialize an OAuth credential with the Apple ID token
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        
        do {
            // Sign in with Firebase
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Update display name if this is a new user and we have a name
            if let fullName = appleIDCredential.fullName,
               let givenName = fullName.givenName,
               authResult.user.displayName == nil {
                let changeRequest = authResult.user.createProfileChangeRequest()
                
                var displayName = givenName
                if let familyName = fullName.familyName {
                    displayName += " \(familyName)"
                }
                changeRequest.displayName = displayName
                
                try? await changeRequest.commitChanges()
            }
            
            updateCurrentUser(authResult.user)
            Logger.debug("✅ Apple Sign-In successful: \(authResult.user.displayName ?? authResult.user.uid)", category: .general)
            
        } catch {
            Logger.error("❌ Apple Sign-In failed: \(error.localizedDescription)", category: .general)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // Generate a random nonce for Apple Sign In security
    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
    
    // Helper to generate random nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    // SHA256 hash for the nonce
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Anonymous Sign In
    
    func signInAnonymously() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            updateCurrentUser(result.user)
            Logger.debug("✅ Anonymous sign-in successful", category: .general)
        } catch {
            Logger.error("❌ Anonymous sign-in failed: \(error.localizedDescription)", category: .general)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            updateCurrentUser(nil)
            Logger.debug("✅ User signed out", category: .general)
        } catch {
            Logger.error("❌ Sign out failed: \(error.localizedDescription)", category: .general)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No user signed in"
            ])
        }
        
        do {
            try await user.delete()
            GIDSignIn.sharedInstance.signOut()
            updateCurrentUser(nil)
            Logger.debug("✅ Account deleted", category: .general)
        } catch {
            Logger.error("❌ Delete account failed: \(error.localizedDescription)", category: .general)
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Profile Photo Upload
    
    func uploadProfilePhoto(_ imageData: Data) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseAuth", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No user signed in"
            ])
        }
        
        // Create a unique filename
        let filename = "\(user.uid)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = Storage.storage().reference().child("profile_photos").child(filename)
        
        // Upload image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        
        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        
        // Update user profile
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.photoURL = downloadURL
        try await changeRequest.commitChanges()
        
        // Reload user to get updated profile
        try await user.reload()
        
        // Update local user with fresh data
        if let refreshedUser = Auth.auth().currentUser {
            updateCurrentUser(refreshedUser)
            Logger.debug("✅ Profile photo updated in local cache", category: .general)
        }
        
        return downloadURL.absoluteString
    }
}
