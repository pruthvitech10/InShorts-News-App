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
    private let refreshInterval: TimeInterval = TimeInterval(AppConstants.backgroundRefreshIntervalMinutes * 60)
    
    // CRITICAL: Fetch state management (thread-safe with actor)
    private let fetchState = FetchStateActor()
    
    private init() {}
}

// MARK: - Thread-Safe Fetch State Actor
actor FetchStateActor {
    private var isFetching = false
    private var lastFetchAttempt: Date?
    private let minimumFetchInterval: TimeInterval = 5.0
    
    func canStartFetch() -> Bool {
        // Check if already fetching
        if isFetching {
            return false
        }
        
        // Check debounce
        if let lastAttempt = lastFetchAttempt {
            let timeSince = Date().timeIntervalSince(lastAttempt)
            if timeSince < minimumFetchInterval {
                return false
            }
        }
        
        return true
    }
    
    func startFetch() {
        isFetching = true
        lastFetchAttempt = Date()
    }
    
    func endFetch() {
        isFetching = false
    }
}

// MARK: - Background Refresh Service
extension BackgroundRefreshService {
    
    // MARK: - Setup
    
    /// Register background refresh task - RUNS ALWAYS
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            guard let appRefreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleBackgroundRefresh(task: appRefreshTask)
        }
        
        Logger.debug("📱 Background refresh registered (runs every 20 minutes)", category: .general)
    }
    
    /// Start automatic refresh - WITH ACTOR-BASED LOCK AND DEBOUNCE
    func startAutoRefresh() {
        Task {
            // CRITICAL: Check if we can start fetch (thread-safe with actor)
            let canStart = await fetchState.canStartFetch()
            
            if !canStart {
                Logger.debug("⏭️ Fetch blocked (already running or debounced)", category: .network)
                return
            }
            
            Logger.debug("🚀 Starting auto-refresh...", category: .network)
            
            // Start fetch
            await fetchAllNews()
        }
        
        // Schedule background refresh - iOS will run it every 20 minutes
        scheduleBackgroundRefresh()
        
        Logger.debug("⏰ Auto-refresh scheduled (runs every 20 minutes)", category: .general)
    }
    
    /// ⚡ FORCE refresh - User pulled down to refresh
    public func forceRefresh() {
        Task {
            await fetchAllNews(forceRefresh: true)
        }
    }
    
    // MARK: - Fetch News
    
    /// Fetch all news from Firebase Storage - WITH ACTOR-BASED LOCK AND FIREBASE CHECK
    private func fetchAllNews(forceRefresh: Bool = false) async {
        // CRITICAL: Check if Firebase is ready
        guard FirebaseInitializer.shared.isReady else {
            Logger.debug("⏭️ Firebase not ready, skipping fetch", category: .network)
            return
        }
        
        // CRITICAL: Check if we can start fetch
        let canStart = await fetchState.canStartFetch()
        guard canStart else {
            Logger.debug("⏭️ Already fetching, skipping duplicate call", category: .network)
            return
        }
        
        // CRITICAL: Mark as fetching
        await fetchState.startFetch()
        
        defer {
            // CRITICAL: Always clear fetching flag
            Task {
                await fetchState.endFetch()
            }
        }
        
        Logger.debug("🔒 Fetch lock acquired", category: .network)
        
        // If force refresh, clear cache
        if forceRefresh {
            await MainActor.run {
                NewsMemoryStore.shared.clearAll()
            }
            Logger.debug("🔄 FORCE REFRESH: Cleared cache", category: .network)
        } else {
            // Check if cache is fresh
            let cacheAge = await NewsMemoryStore.shared.getTimeSinceLastFetch()
            let cacheValiditySeconds = TimeInterval(AppConstants.cacheValidityMinutes * 60)
            let hasFreshCache = await !NewsMemoryStore.shared.isEmpty() && (cacheAge ?? 99999) < cacheValiditySeconds
            
            if hasFreshCache {
                Logger.debug("⚡ Cache is fresh, skipping fetch", category: .network)
                return
            }
        }
        
        Logger.debug("🔥 Downloading JSON from Firebase Storage...", category: .network)
        let startTime = Date()
        
        // Mark as fetching in memory store
        await MainActor.run {
            NewsMemoryStore.shared.setFetching(true)
        }
        
        // Download JSON files from Firebase Storage (with exponential backoff)
        var lastError: Error?
        for attempt in 1...3 {
            do {
                if attempt > 1 {
                    // Exponential backoff: 2s, 4s, 8s
                    let delay = pow(2.0, Double(attempt - 1)) * 2.0
                    Logger.debug("🔄 Retry attempt \(attempt)/3 after \(Int(delay))s delay...", category: .network)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                Logger.debug("📡 Fetching from Firebase Storage (attempt \(attempt)/3)...", category: .network)
                let firebaseArticles = try await FirebaseNewsService.shared.fetchAllCategories()
                
                // Store articles
                await MainActor.run {
                    NewsMemoryStore.shared.storeAll(categories: firebaseArticles)
                    NewsMemoryStore.shared.setFetching(false)
                }
                
                let duration = Date().timeIntervalSince(startTime)
                let totalCount = firebaseArticles.values.reduce(0) { $0 + $1.count }
                Logger.debug("✅ Downloaded \(totalCount) articles in \(String(format: "%.2f", duration))s", category: .network)
                
                // Notify UI
                NotificationCenter.default.post(name: .newsRefreshed, object: nil)
                return // Success!
                
            } catch {
                lastError = error
                Logger.debug("⚠️ Attempt \(attempt) failed: \(error)", category: .network)
            }
        }
        
        // All retries failed
        await MainActor.run {
            NewsMemoryStore.shared.setFetching(false)
        }
        Logger.error("❌ Firebase download failed after 3 attempts: \(lastError?.localizedDescription ?? "Unknown")", category: .network)
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
