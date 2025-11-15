//
//  Shims.swift
//  Newssss
//
//  Temporary shims for missing types
//  Created on 5 November 2025.
//

import Foundation
import SwiftUI


// MARK: - AppUser

// Note: This is now used by FirebaseAuthenticationManager

struct AppUser {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: String?
    let phoneNumber: String?
    let isEmailVerified: Bool
    let createdAt: Date
    let lastSignInAt: Date
    
    // Computed property for user initials
    var initials: String {
        if let name = displayName, !name.isEmpty {
            let components = name.split(separator: " ")
            if components.count >= 2 {
                // First and last name initials
                let first = components.first?.first.map(String.init) ?? ""
                let last = components.last?.first.map(String.init) ?? ""
                return (first + last).uppercased()
            } else if let firstChar = components.first?.first {
                // Just first initial
                return String(firstChar).uppercased()
            }
        }
        
        // Fallback to first letter of email
        if let email = email, let firstChar = email.first {
            return String(firstChar).uppercased()
        }
        
        // Ultimate fallback
        return "U"
    }
    
    init(
        id: String = UUID().uuidString,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: String? = nil,
        phoneNumber: String? = nil,
        isEmailVerified: Bool = false,
        createdAt: Date = Date(),
        lastSignInAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.phoneNumber = phoneNumber
        self.isEmailVerified = isEmailVerified
        self.createdAt = createdAt
        self.lastSignInAt = lastSignInAt
    }
}

// MARK: - LLMProvider
enum LLMProvider: String, CaseIterable, Codable {
    case openai
    case anthropic
    case google
    case local

    var displayName: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google"
        case .local: return "Local"
        }
    }
}

// MARK: - PopularSource
enum PopularSource: String, CaseIterable, Codable, Hashable {
    case bbc
    case cnn
    case theguardian
    case reuters

    var displayName: String {
        switch self {
        case .bbc: return "BBC"
        case .cnn: return "CNN"
        case .theguardian: return "The Guardian"
        case .reuters: return "Reuters"
        }
    }

    var sourceId: String {
        return self.rawValue
    }
}

// MARK: - LLMService

actor LLMService {
    static let shared = LLMService()

    private var provider: LLMProvider = .openai
    private var apiKey: String = ""

    func configure(provider: LLMProvider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }

    // Provide minimal implementations used by the app
    func enhanceArticle(_ article: Article) async throws -> EnhancedArticle {
        // Return a basic EnhancedArticle if type exists
        return EnhancedArticle(article: article)
    }

    func summarizeArticle(_ article: Article) async throws -> String {
        return article.description ?? article.title
    }

    func generateKeyPoints(_ article: Article) async throws -> [String] {
        return []
    }
}


