//
//  Shims.swift
//  Newssss
//
//  Temporary shims for missing types
//  Created on 5 November 2025.
//

import Foundation
import SwiftUI
import Combine


// AppUser

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

// Authentication manager alias - points to Firebase implementation
typealias AuthenticationManager = FirebaseAuthenticationManager

// LLMProvider
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

// LLMService - Uses Apple's Natural Language framework for summarization

actor LLMService {
    static let shared = LLMService()
    
    private var provider: LLMProvider = .local
    private var apiKey: String = ""
    
    func configure(provider: LLMProvider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }
    
    /// Summarize article using Apple's Natural Language framework
    func summarizeArticle(_ article: Article) async throws -> String {
        // Get full text (content + description)
        let fullText = [article.content, article.description, article.title]
            .compactMap { $0 }
            .joined(separator: " ")
        
        guard !fullText.isEmpty else {
            return article.title
        }
        
        // Use Apple's Natural Language to create summary
        return await extractSummary(from: fullText, maxSentences: 4)
    }
    
    /// Generate key points from article
    func generateKeyPoints(_ article: Article) async throws -> [String] {
        let fullText = [article.content, article.description]
            .compactMap { $0 }
            .joined(separator: " ")
        
        guard !fullText.isEmpty else {
            return []
        }
        
        return await extractKeyPoints(from: fullText, maxPoints: 5)
    }
    
    // MARK: - Private Helpers
    
    private func extractSummary(from text: String, maxSentences: Int) async -> String {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 20 }
        
        guard !sentences.isEmpty else {
            return text.prefix(200).description
        }
        
        // Score sentences based on position and length
        let scoredSentences = sentences.enumerated().map { (index, sentence) -> (String, Double) in
            var score = 0.0
            
            // Position weight (early sentences are more important)
            let positionWeight = 1.0 - (Double(index) / Double(sentences.count))
            score += positionWeight * 0.4
            
            // Length weight (prefer medium-length sentences)
            let idealLength = 100.0
            let lengthDiff = abs(Double(sentence.count) - idealLength)
            let lengthWeight = max(0, 1.0 - (lengthDiff / idealLength))
            score += lengthWeight * 0.3
            
            // Check for important keywords (Italian & English)
            let importantKeywords = [
                "importante", "significativo", "principale", "critico",
                "important", "significant", "main", "critical",
                "nuovo", "new", "primo", "first", "ultimo", "last"
            ]
            let lowercased = sentence.lowercased()
            let keywordMatches = importantKeywords.filter { lowercased.contains($0) }.count
            score += Double(keywordMatches) * 0.3
            
            return (sentence, score)
        }
        
        // Get top sentences
        let topSentences = scoredSentences
            .sorted { $0.1 > $1.1 }
            .prefix(maxSentences)
            .map { $0.0 }
        
        return topSentences.joined(separator: ". ") + "."
    }
    
    private func extractKeyPoints(from text: String, maxPoints: Int) async -> [String] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 15 && $0.count < 150 }
        
        guard !sentences.isEmpty else {
            return []
        }
        
        // Score and extract key points
        let scored = sentences.map { sentence -> (String, Double) in
            var score = 0.0
            
            // Check for action words
            let actionWords = [
                "annuncia", "dichiara", "rivela", "conferma", "propone",
                "announces", "declares", "reveals", "confirms", "proposes"
            ]
            let lowercased = sentence.lowercased()
            score += Double(actionWords.filter { lowercased.contains($0) }.count) * 2.0
            
            // Prefer shorter, punchy sentences for key points
            if sentence.count < 100 {
                score += 1.0
            }
            
            return (sentence, score)
        }
        
        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(maxPoints)
            .map { $0.0 }
    }
}


