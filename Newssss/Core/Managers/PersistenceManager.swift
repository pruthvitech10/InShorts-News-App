//
//  PersistenceManager.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation


class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    private func fileURL(for filename: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent(filename)
    }
    
    // MARK: - Save
    func save<T: Codable>(_ object: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key)
            Logger.debug("Saved data for key: \(key)", category: .persistence)
        } catch {
            Logger.error("Failed to save data for key \(key): \(error.localizedDescription)", category: .persistence)
        }
    }
    
    func save<T: Codable>(_ object: T, to filename: String) {
        guard let url = fileURL(for: filename) else {
            Logger.error("Failed to get file URL for \(filename)", category: .persistence)
            return
        }
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url, options: .atomic)
            Logger.debug("Saved data to file: \(filename)", category: .persistence)
        } catch {
            Logger.error("Failed to save data to file \(filename): \(error.localizedDescription)", category: .persistence)
        }
    }
    
    // MARK: - Load
    func load<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            let object = try JSONDecoder().decode(T.self, from: data)
            return object
        } catch {
            Logger.error("Failed to load data for key \(key): \(error.localizedDescription)", category: .persistence)
            return nil
        }
    }
    
    func load<T: Codable>(from filename: String, as type: T.Type) -> T? {
        guard let url = fileURL(for: filename), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let object = try JSONDecoder().decode(T.self, from: data)
            Logger.debug("Loaded data from file: \(filename)", category: .persistence)
            return object
        } catch {
            Logger.error("Failed to load data from file \(filename): \(error.localizedDescription)", category: .persistence)
            return nil
        }
    }
    
    // MARK: - Remove
    func remove(forKey key: String) {
        userDefaults.removeObject(forKey: key)
        Logger.debug("Removed data for key: \(key)", category: .persistence)
    }
    
    // MARK: - Swipe History
    func saveSwipeHistory(_ articles: [Article]) {
        save(articles, to: "swipe_history.json")
    }
    
    func loadSwipeHistory() -> [Article] {
        return load(from: "swipe_history.json", as: [Article].self) ?? []
    }
}

