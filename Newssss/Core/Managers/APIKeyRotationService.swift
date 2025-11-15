//
//  APIKeyRotationService.swift
//  Newssss
//
//  Created on 29 October 2025.
//

import Foundation

// Manages API key rotation for all news services
// Automatically switches keys when rate limits are hit
///
/// ⚠️ SECURITY NOTE:
/// API keys are stored in Config.xcconfig which is:
/// - NOT committed to version control (.gitignore)
/// - LOCAL ONLY (each developer has their own)
/// - NEVER exposed in source code
actor APIKeyRotationService {
    static let shared = APIKeyRotationService()
    
    // Key storage
    
    private struct KeySet {
        let keys: [String]
        var currentIndex: Int
        let serviceName: String
        
        mutating func rotate() {
            guard !keys.isEmpty else { return }
            currentIndex = (currentIndex + 1) % keys.count
        }
        
        func getCurrentKey() throws -> String {
            guard !keys.isEmpty else {
                throw NetworkError.apiKeyMissing(apiName: serviceName)
            }
            let index = currentIndex >= keys.count ? 0 : currentIndex
            let key = keys[index]
            guard !key.isEmpty else {
                throw NetworkError.apiKeyMissing(apiName: serviceName)
            }
            return key
        }
    }
    
    private var gnewsKeySet: KeySet?
    private var newsDataIOKeySet: KeySet?
    private var newsAPIKeySet: KeySet?
    private var newsDataHubKeySet: KeySet?
    private var rapidAPIKeySet: KeySet?
    
    // Cache to avoid repeated keychain/plist reads
    private var keysCache: [String: [String]] = [:]
    private var lastCacheRefresh: Date = .distantPast
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // Load keys from config
    
    private func loadKeys(forService service: String) -> [String] {
        // Check cache first
        let now = Date()
        if now.timeIntervalSince(lastCacheRefresh) < cacheValidityDuration,
           let cached = keysCache[service] {
            return cached
        }
        
        var keys: [String] = []
        
        // Try Keychain first
        if let keychainKey = try? KeychainService.shared.getAPIKey(forService: service) {
            keys = keychainKey
                .split(separator: ",")
                .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.isEmpty }
        }
        
        // Fallback to Info.plist if keychain is empty
        if keys.isEmpty {
            if let info = Bundle.main.infoDictionary,
               let plistValue = info[service] as? String {
                keys = plistValue
                    .split(separator: ",")
                    .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    .filter { !$0.isEmpty }
            }
        }
        
        // Update cache
        keysCache[service] = keys
        lastCacheRefresh = now
        
        #if DEBUG
        if keys.isEmpty {
            Logger.error("⚠️ No API keys found for service: \(service)", category: .network)
        } else {
            Logger.debug("✅ Loaded \(keys.count) key(s) for \(service)", category: .network)
        }
        #endif
        
        return keys
    }
    
    private func ensureKeySet(_ keySet: inout KeySet?, service: String, displayName: String) {
        if keySet == nil {
            let keys = loadKeys(forService: service)
            keySet = KeySet(keys: keys, currentIndex: 0, serviceName: displayName)
        }
    }
    
    // Refresh key cache
    
    /// Manually refresh the key cache (useful after updating keys)
    func refreshCache() {
        keysCache.removeAll()
        lastCacheRefresh = .distantPast
        
        // Clear key sets to force reload
        gnewsKeySet = nil
        newsDataIOKeySet = nil
        newsAPIKeySet = nil
        newsDataHubKeySet = nil
        rapidAPIKeySet = nil
        
        #if DEBUG
        Logger.debug("🔄 API key cache refreshed", category: .network)
        #endif
    }
    
    // GNews keys
    
    func getGNewsKey() async throws -> String {
        ensureKeySet(&gnewsKeySet, service: "GNEWS_API_KEYS", displayName: "GNews")
        return try gnewsKeySet!.getCurrentKey()
    }
    
    func rotateGNewsKey() {
        gnewsKeySet?.rotate()
        #if DEBUG
        if let index = gnewsKeySet?.currentIndex, let count = gnewsKeySet?.keys.count {
            Logger.debug("🔄 GNews key rotated to index \(index)/\(count)", category: .network)
        }
        #endif
    }
    
    // NewsData.io keys
    
    func getNewsDataIOKey() async throws -> String {
        ensureKeySet(&newsDataIOKeySet, service: "NEWSDATA_IO_KEYS", displayName: "NewsData.io")
        return try newsDataIOKeySet!.getCurrentKey()
    }
    
    func rotateNewsDataIOKey() {
        newsDataIOKeySet?.rotate()
        #if DEBUG
        if let index = newsDataIOKeySet?.currentIndex, let count = newsDataIOKeySet?.keys.count {
            Logger.debug("🔄 NewsData.io key rotated to index \(index)/\(count)", category: .network)
        }
        #endif
    }
    
    // NewsAPI.org keys
    
    func getNewsAPIKey() async throws -> String {
        ensureKeySet(&newsAPIKeySet, service: "NEWS_API_KEYS", displayName: "NewsAPI.org")
        return try newsAPIKeySet!.getCurrentKey()
    }
    
    func rotateNewsAPIKey() {
        newsAPIKeySet?.rotate()
        #if DEBUG
        if let index = newsAPIKeySet?.currentIndex, let count = newsAPIKeySet?.keys.count {
            Logger.debug("🔄 NewsAPI.org key rotated to index \(index)/\(count)", category: .network)
        }
        #endif
    }
    
    // NewsDataHub keys
    
    func getNewsDataHubAPIKey() async throws -> String {
        ensureKeySet(&newsDataHubKeySet, service: "NEWSDATAHUB_API_KEYS", displayName: "NewsDataHub")
        return try newsDataHubKeySet!.getCurrentKey()
    }
    
    func getNewsDataHubKey() async throws -> String {
        try await getNewsDataHubAPIKey()
    }
    
    func rotateNewsDataHubAPIKey() {
        newsDataHubKeySet?.rotate()
        #if DEBUG
        if let index = newsDataHubKeySet?.currentIndex, let count = newsDataHubKeySet?.keys.count {
            Logger.debug("🔄 NewsDataHub key rotated to index \(index)/\(count)", category: .network)
        }
        #endif
    }
    
    func rotateNewsDataHubKey() {
        rotateNewsDataHubAPIKey()
    }
    
    // RapidAPI keys
    
    func getRapidAPIKey() async throws -> String {
        ensureKeySet(&rapidAPIKeySet, service: "RAPIDAPI_KEYS", displayName: "RapidAPI")
        return try rapidAPIKeySet!.getCurrentKey()
    }
    
    func rotateRapidAPIKey() {
        rapidAPIKeySet?.rotate()
        #if DEBUG
        if let index = rapidAPIKeySet?.currentIndex, let count = rapidAPIKeySet?.keys.count {
            Logger.debug("🔄 RapidAPI key rotated to index \(index)/\(count)", category: .network)
        }
        #endif
    }
    
    // Bulk operations
    
    /// Get all available keys for a specific provider
    func getAvailableKeys(for provider: NewsAPIProvider) async throws -> [String] {
        switch provider {
        case .gnews:
            ensureKeySet(&gnewsKeySet, service: "GNEWS_API_KEYS", displayName: "GNews")
            return gnewsKeySet?.keys ?? []
        case .newsDataIO:
            ensureKeySet(&newsDataIOKeySet, service: "NEWSDATA_IO_KEYS", displayName: "NewsData.io")
            return newsDataIOKeySet?.keys ?? []
        case .newsAPI:
            ensureKeySet(&newsAPIKeySet, service: "NEWS_API_KEYS", displayName: "NewsAPI.org")
            return newsAPIKeySet?.keys ?? []
        case .newsDataHub:
            ensureKeySet(&newsDataHubKeySet, service: "NEWSDATAHUB_API_KEYS", displayName: "NewsDataHub")
            return newsDataHubKeySet?.keys ?? []
        case .rapidAPI:
            ensureKeySet(&rapidAPIKeySet, service: "RAPIDAPI_KEYS", displayName: "RapidAPI")
            return rapidAPIKeySet?.keys ?? []
        case .all:
            return []
        }
    }
    
    /// Check if a provider has any configured keys
    func hasKeys(for provider: NewsAPIProvider) async -> Bool {
        guard let keys = try? await getAvailableKeys(for: provider) else {
            return false
        }
        return !keys.isEmpty
    }
    
    /// Rotate key for a specific provider
    func rotateKey(for provider: NewsAPIProvider) {
        switch provider {
        case .gnews:
            rotateGNewsKey()
        case .newsDataIO:
            rotateNewsDataIOKey()
        case .newsAPI:
            rotateNewsAPIKey()
        case .newsDataHub:
            rotateNewsDataHubKey()
        case .rapidAPI:
            rotateRapidAPIKey()
        case .all:
            break
        }
    }
    
    // Key status info
    
    struct KeyStatus {
        let provider: NewsAPIProvider
        let totalKeys: Int
        let currentIndex: Int
        let hasKeys: Bool
        
        var displayInfo: String {
            hasKeys ? "\(provider.displayName): \(currentIndex + 1)/\(totalKeys)" : "\(provider.displayName): No keys"
        }
    }
    
    func getStatus(for provider: NewsAPIProvider) async -> KeyStatus {
        let keys = (try? await getAvailableKeys(for: provider)) ?? []
        let currentIndex: Int
        
        switch provider {
        case .gnews:
            currentIndex = gnewsKeySet?.currentIndex ?? 0
        case .newsDataIO:
            currentIndex = newsDataIOKeySet?.currentIndex ?? 0
        case .newsAPI:
            currentIndex = newsAPIKeySet?.currentIndex ?? 0
        case .newsDataHub:
            currentIndex = newsDataHubKeySet?.currentIndex ?? 0
        case .rapidAPI:
            currentIndex = rapidAPIKeySet?.currentIndex ?? 0
        case .all:
            currentIndex = 0
        }
        
        return KeyStatus(
            provider: provider,
            totalKeys: keys.count,
            currentIndex: currentIndex,
            hasKeys: !keys.isEmpty
        )
    }
    
    func getAllStatuses() async -> [KeyStatus] {
        await withTaskGroup(of: KeyStatus.self) { group in
            for provider in NewsAPIProvider.allCases where provider != .all {
                group.addTask {
                    await self.getStatus(for: provider)
                }
            }
            
            var statuses: [KeyStatus] = []
            for await status in group {
                statuses.append(status)
            }
            return statuses
        }
    }
    
    // Debug helpers
    
    #if DEBUG
    func debugKeysInfo() async {
        Logger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: .network)
        Logger.log("🔑 API Key Configuration Status", category: .network)
        Logger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: .network)
        
        let maskKey: @Sendable (String) -> String = { s in
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.count > 8 else { return "****" }
            return "\(trimmed.prefix(4))...\(trimmed.suffix(4))"
        }
        
        let providers: [(provider: NewsAPIProvider, getter: () async throws -> String)] = [
            (.gnews, { try await self.getGNewsKey() }),
            (.newsAPI, { try await self.getNewsAPIKey() }),
            (.newsDataIO, { try await self.getNewsDataIOKey() }),
            (.newsDataHub, { try await self.getNewsDataHubAPIKey() }),
            (.rapidAPI, { try await self.getRapidAPIKey() })
        ]
        
        for (provider, getter) in providers {
            do {
                let key = try await getter()
                let status = await getStatus(for: provider)
                Logger.log("✅ \(provider.displayName): \(maskKey(key)) [\(status.displayInfo)]", category: .network)
            } catch {
                Logger.error("❌ \(provider.displayName): \(error.localizedDescription)", category: .network)
            }
        }
        
        Logger.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", category: .network)
    }
    
    func debugRotateAllKeys() {
        Logger.log("🔄 Rotating all API keys...", category: .network)
        rotateGNewsKey()
        rotateNewsAPIKey()
        rotateNewsDataIOKey()
        rotateNewsDataHubKey()
        rotateRapidAPIKey()
        Logger.log("✅ All keys rotated", category: .network)
    }
    #endif
}

// Helper methods

extension APIKeyRotationService {
    /// Convenience method to handle key rotation on rate limit errors
    func handleRateLimitError(for provider: NewsAPIProvider) async {
        #if DEBUG
        Logger.error("⚠️ Rate limit hit for \(provider.displayName), rotating key...", category: .network)
        #endif
        
        rotateKey(for: provider)
        
        // Small delay to avoid hammering the API immediately
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    /// Try to get a key with automatic retry on failure
    func getKey(for provider: NewsAPIProvider, maxRetries: Int = 3) async throws -> String {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                switch provider {
                case .gnews:
                    return try await getGNewsKey()
                case .newsDataIO:
                    return try await getNewsDataIOKey()
                case .newsAPI:
                    return try await getNewsAPIKey()
                case .newsDataHub:
                    return try await getNewsDataHubAPIKey()
                case .rapidAPI:
                    return try await getRapidAPIKey()
                case .all:
                    throw NetworkError.apiKeyMissing(apiName: "Invalid provider: .all")
                }
            } catch {
                lastError = error
                
                if attempt < maxRetries - 1 {
                    #if DEBUG
                    Logger.error("⚠️ Attempt \(attempt + 1) failed for \(provider.displayName), retrying...", category: .network)
                    #endif
                    
                    rotateKey(for: provider)
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                }
            }
        }
        
        throw lastError ?? NetworkError.apiKeyMissing(apiName: provider.displayName)
    }
}
