//
//  OnboardingView.swift
//  Newssss
//
//  Feature showcase screen shown on first launch
//  Gives time to load news in background
//

import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Content card
                VStack(spacing: 30) {
                    Text("What's New?")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 30)
                        .padding(.top, 30)
                    
                    TabView(selection: $currentPage) {
                        // Feature 1: Italian News
                        FeatureCard(
                            number: "1",
                            title: "Italian News",
                            description: "Get news from 8 Italian sources including ANSA, La Repubblica, Corriere della Sera, and sports newspapers.",
                            icon: "🇮🇹"
                        )
                        .tag(0)
                        
                        // Feature 2: Swipe Cards
                        FeatureCard(
                            number: "2",
                            title: "Swipe to Read",
                            description: "Swipe left to skip, swipe right to read. Never see the same article twice!",
                            icon: "👆"
                        )
                        .tag(1)
                        
                        // Feature 3: Translate
                        FeatureCard(
                            number: "3",
                            title: "Translate Articles",
                            description: "Tap the translate button to read Italian articles in English instantly.",
                            icon: "🌐"
                        )
                        .tag(2)
                        
                        // Feature 4: Categories
                        FeatureCard(
                            number: "4",
                            title: "8 Categories",
                            description: "Politics, Sports, Business, Entertainment, Health, Science, and more!",
                            icon: "📰"
                        )
                        .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(height: 300)
                    
                    // Continue button
                    Button(action: {
                        withAnimation {
                            showOnboarding = false
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                        }
                    }) {
                        Text("Continue Reading")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
    }
}

struct FeatureCard: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(icon)
                .font(.system(size: 80))
            
            HStack(alignment: .top, spacing: 8) {
                Text(number)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
}
