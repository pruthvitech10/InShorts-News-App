//
//  BackgroundRefreshService.swift
//  Newssss
//
//  ALWAYS fetches news every 20 minutes - app open or closed
//  Runs independently in background
//  Fetches fresh content directly from sources
//

import Foundation
import BackgroundTasks
import UIKit

class BackgroundRefreshService {
    static let shared = BackgroundRefreshService()
    
    private let refreshTaskIdentifier = "com.newssss.refresh"
    private let refreshInterval: TimeInterval = 20 * 60 // 20 minutes
    
    private let italianPoliticsService = ItalianPoliticsNewsService.shared
    
    private init() {}
    
    // MARK: - Setup
    
    /// Register background refresh task - RUNS ALWAYS
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        
        Logger.debug("📱 Background refresh registered (runs every 20 minutes)", category: .general)
    }
    
    /// Start automatic refresh - ALWAYS RUNNING
    func startAutoRefresh() {
        // Initial fetch immediately
        Task {
            await fetchAllNews()
        }
        
        // Schedule background refresh - iOS will run it every 20 minutes
        scheduleBackgroundRefresh()
        
        Logger.debug("⏰ Auto-refresh started (ALWAYS runs every 20 minutes)", category: .general)
    }
    
    // MARK: - Fetch News
    
    /// Fetch all news fresh from sources and store in memory
    private func fetchAllNews() async {
        Logger.debug("🔄 WIPE & REFETCH: Clearing old articles and fetching fresh...", category: .network)
        
        let startTime = Date()
        
        // STEP 1: WIPE everything from memory
        await MainActor.run {
            NewsMemoryStore.shared.clearAll()
            NewsMemoryStore.shared.setFetching(true)
        }
        
        // STEP 2: Fetch ALL categories in parallel from internet
        async let politicsArticles = italianPoliticsService.fetchItalianPolitics()
        async let sportsArticles = ItalianSportsNewsService.shared.fetchItalianSports()
        async let technologyArticles = ItalianTechnologyNewsService.shared.fetchItalianTechnology()
        async let entertainmentArticles = ItalianEntertainmentNewsService.shared.fetchItalianEntertainment()
        async let businessArticles = ItalianBusinessNewsService.shared.fetchItalianBusiness()
        async let worldArticles = ItalianWorldNewsService.shared.fetchItalianWorld()
        async let crimeArticles = ItalianCrimeNewsService.shared.fetchItalianCrime()
        async let automotiveArticles = ItalianAutomotiveNewsService.shared.fetchItalianAutomotive()
        async let lifestyleArticles = ItalianLifestyleNewsService.shared.fetchItalianLifestyle()
        async let generalArticles = ItalianGeneralNewsService.shared.fetchItalianGeneral()
        
        let (politics, sports, technology, entertainment, business, world, crime, automotive, lifestyle, general) = await (politicsArticles, sportsArticles, technologyArticles, entertainmentArticles, businessArticles, worldArticles, crimeArticles, automotiveArticles, lifestyleArticles, generalArticles)
        
        // STEP 3: Enforce STRICT category separation (NO duplicates across categories)
        let rawCategories: [String: [Article]] = [
            "politics": politics,
            "sports": sports,
            "technology": technology,
            "entertainment": entertainment,
            "business": business,
            "world": world,
            "crime": crime,
            "automotive": automotive,
            "lifestyle": lifestyle,
            "general": general
        ]
        
        // Apply strict category enforcement
        let cleanedCategories = CategoryEnforcer.shared.enforceStrictCategories(categories: rawCategories)
        
        // STEP 4: Store cleaned articles in memory
        await MainActor.run {
            NewsMemoryStore.shared.storeAll(categories: cleanedCategories)
            NewsMemoryStore.shared.setFetching(false)
        }
        
        let totalArticles = politics.count + sports.count + technology.count + entertainment.count + business.count + world.count + crime.count + automotive.count + lifestyle.count + general.count
        let duration = Date().timeIntervalSince(startTime)
        
        Logger.debug("✅ FRESH FETCH complete: \(totalArticles) articles (\(politics.count) politics + \(sports.count) sports + \(technology.count) tech + \(entertainment.count) entertainment + \(business.count) business + \(world.count) world + \(crime.count) crime + \(automotive.count) automotive + \(lifestyle.count) lifestyle + \(general.count) general) in \(String(format: "%.1f", duration))s", category: .network)
        
        // Send notification to UI to refresh if needed
        NotificationCenter.default.post(name: .newsRefreshed, object: nil)
    }
    
    // MARK: - Background Refresh (ALWAYS RUNS)
    
    /// Schedule background refresh task - iOS runs it every 20 minutes
    private func scheduleBackgroundRefresh() {
        // Cancel any existing tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
        
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            let nextRefresh = Date(timeIntervalSinceNow: refreshInterval)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            Logger.debug("📅 Next refresh: \(formatter.string(from: nextRefresh))", category: .general)
        } catch {
            Logger.error("❌ Failed to schedule background refresh: \(error)", category: .general)
        }
    }
    
    /// Handle background refresh task - RUNS AUTOMATICALLY
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        let startTime = Date()
        Logger.debug("🌙 Background refresh triggered (automatic)", category: .general)
        
        // Schedule next refresh IMMEDIATELY (ensures continuous 20-minute cycle)
        scheduleBackgroundRefresh()
        
        // Create background task
        let fetchTask = Task {
            await fetchAllNews()
        }
        
        // Handle expiration (iOS gives us ~30 seconds)
        task.expirationHandler = {
            fetchTask.cancel()
            Logger.debug("⚠️ Background refresh expired (will retry in 20 minutes)", category: .general)
        }
        
        // Complete task
        Task {
            await fetchTask.value
            let duration = Date().timeIntervalSince(startTime)
            Logger.debug("✅ Background refresh complete in \(String(format: "%.1f", duration))s", category: .general)
            task.setTaskCompleted(success: true)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newsRefreshed = Notification.Name("newsRefreshed")
}
