//
//  ProfileViewModel.swift
//  DailyNews
//

import Foundation
import Combine


// Profile screen view model

@MainActor
final class ProfileViewModel: ObservableObject {
    // Use the global AuthenticationManager shim defined in `Shims.swift`.
    private let auth = AuthenticationManager.shared
    private var bag = Set<AnyCancellable>()
    
    @Published var showSignIn = false
    @Published var error: String?
    
    var user: AppUser? { auth.currentUser }
    var isAuthenticated: Bool { auth.isAuthenticated }
    var isLoading: Bool { auth.isLoading }
    var displayName: String { user?.displayName ?? user?.email ?? "User" }
    var userEmail: String { user?.email ?? "No email" }
    var initials: String { user?.initials ?? "U" }
    
    init() {
        auth.$currentUser.sink { [weak self] (_: AppUser?) in
            self?.objectWillChange.send()
        }.store(in: &bag)
        
        auth.$errorMessage.assign(to: &$error)
    }
    
    func signIn(with provider: AuthProvider) {
        Task {
            do {
                switch provider {
                case .google: 
                    try await auth.signInWithGoogle()
                case .anonymous: 
                    try await auth.signInAnonymously()
                }
                showSignIn = false
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        Task {
            try? await auth.signOut()
        }
    }
}

// Authentication providers

enum AuthProvider {
    case google, anonymous
}
