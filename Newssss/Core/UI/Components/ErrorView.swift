//
//  ErrorView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    private var isRateLimitError: Bool {
        message.lowercased().contains("rate limit") || 
        message.lowercased().contains("api limit") ||
        message.lowercased().contains("daily limit")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isRateLimitError ? "clock.badge.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(isRateLimitError ? .blue : .orange)
            
            Text(isRateLimitError ? "Rate Limit Reached" : "Oops!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if isRateLimitError {
                VStack(spacing: 8) {
                    Text("💡 Quick Fixes:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("1. Wait for rate limits to reset (midnight UTC)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("2. Get fresh API keys from gnews.io")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("3. Check your internet connection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            Button(action: retry) {
                Text(isRateLimitError ? "Use Cached News" : "Try Again")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView(message: "Unable to fetch news. Please check your internet connection.") {
        print("Retry tapped")
    }
}
