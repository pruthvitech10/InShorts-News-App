import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var userSettings: UserSettings
    
    private let settingsKey = "userSettings"
    
    init() {
        self.userSettings = PersistenceManager.shared.load(forKey: settingsKey, as: UserSettings.self) ?? .default
    }
    
    func updateSettings() {
        PersistenceManager.shared.save(userSettings, forKey: settingsKey)
        Logger.debug("Settings updated", category: .general)
    }
    
    func resetToDefaults() {
        userSettings = .default
        PersistenceManager.shared.save(userSettings, forKey: settingsKey)
        Logger.debug("Settings reset to defaults", category: .general)
    }
}
