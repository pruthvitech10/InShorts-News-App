//
//  SplashScreenView.swift
//  Newssss
//
//  Created on 19 November 2025.
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var opacity = 0.0
    @State private var scale = 0.8
    
    // Logo animation state
    @State private var dotOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo Container
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(30)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Text
                VStack(spacing: 5) {
                    Text("InShorts")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.2, green: 0.1, blue: 0.4)) // Dark Purple
                    
                    Text("stay informed")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .tracking(2)
                }
                .opacity(opacity)
                .offset(y: 10)
            }
        }
        .onAppear {
            // 1. Animate Logo
            withAnimation(.easeOut(duration: 0.8)) {
                self.opacity = 1.0
                self.scale = 1.0
            }
            
            // 2. Pre-load Data
            Task {
                await preloadData()
            }
        }
    }
    
    private func preloadData() async {
        Logger.debug("⚡ SPLASH: Starting 2-second splash with background loading...", category: .network)
        
        let startTime = Date()
        
        // Wait for Firebase to be ready
        _ = await FirebaseInitializer.shared.waitUntilReady()
        
        // Start loading data in background IMMEDIATELY (during splash)
        Task.detached(priority: .userInitiated) {
            do {
                Logger.debug("🚀 SPLASH: Loading data in background...", category: .network)
                
                // Fetch all 4 categories in parallel
                async let general = FirebaseNewsService.shared.fetchCategory("general")
                async let politics = FirebaseNewsService.shared.fetchCategory("politics")
                async let world = FirebaseNewsService.shared.fetchCategory("world")
                async let business = FirebaseNewsService.shared.fetchCategory("business")
                
                let results = try await [general, politics, world, business]
                
                // Store in NewsMemoryStore
                await MainActor.run {
                    NewsMemoryStore.shared.store(articles: results[0], for: "general")
                    NewsMemoryStore.shared.store(articles: results[1], for: "politics")
                    NewsMemoryStore.shared.store(articles: results[2], for: "world")
                    NewsMemoryStore.shared.store(articles: results[3], for: "business")
                }
                
                // Load Breaking News
                await SearchViewModel.shared.loadBreakingNews()
                
                Logger.debug("✅ SPLASH: All data loaded successfully!", category: .network)
                
            } catch {
                Logger.error("❌ SPLASH: Failed to load data: \(error)", category: .network)
            }
        }
        
        // Show splash for EXACTLY 2 seconds (with animation)
        let splashDuration = 2.0
        try? await Task.sleep(nanoseconds: UInt64(splashDuration * 1_000_000_000))
        
        // Dismiss splash after 2 seconds (whether data is loaded or not)
        withAnimation(.easeOut(duration: 0.5)) {
            self.isActive = false
        }
        
        // Log timing
        let elapsed = Date().timeIntervalSince(startTime)
        Logger.debug("⏱️ SPLASH: Dismissed after \(String(format: "%.1f", elapsed))s", category: .network)
        
        // Don't cancel the loading task - let it finish in background
        // If data isn't ready, Feed will show loading spinner
    }
}

struct DotView: View {
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 8, height: 8)
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
}
