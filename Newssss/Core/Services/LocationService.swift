//
//  LocationService.swift
//  Newss
//
//  Created on 15 November 2025.
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private var currentCountryCode: String = "it"  // Default to Italy (Europe)
    private var currentLanguageCode: String = "en"
    
    // Country information
    struct CountryInfo {
        let code: String
        let name: String
        var displayName: String { "\(name) (\(code.uppercased()))" }
    }
    
    private(set) var detectedCountry: CountryInfo = CountryInfo(code: "it", name: "Italy")
    
    private override init() {
        super.init()
        setupLocationManager()
        detectLocationFromLocale()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    }
    
    /// Detect location from device locale/region settings (works in simulator!)
    private func detectLocationFromLocale() {
        // Get country from device region settings
        if let regionCode = Locale.current.region?.identifier {
            currentCountryCode = regionCode.lowercased()
            let countryName = Locale.current.localizedString(forRegionCode: regionCode) ?? "Unknown"
            detectedCountry = CountryInfo(code: currentCountryCode, name: countryName)
            
            Logger.debug("📍 Detected from locale: \(countryName) (\(regionCode))", category: .general)
        }
        
        // Get language from device settings
        currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        
        Logger.debug("🌍 Country: \(currentCountryCode.uppercased()), Language: \(currentLanguageCode)", category: .general)
    }
    
    func startUpdatingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    
    // Public Methods
    
    /// Returns the current country code for news API (e.g., "us", "gb")
    func getNewsCountryCode() -> String {
        return currentCountryCode
    }
    
    /// Returns the current language code for news API (e.g., "en", "es")
    func getNewsLanguageCode() -> String {
        return currentLanguageCode
    }
    
    /// Updates the preferred country code
    func updateCountryCode(_ code: String) {
        let lowercasedCode = code.lowercased()
        guard lowercasedCode != currentCountryCode else { return }
        
        currentCountryCode = lowercasedCode
        
        // Update country info
        let countryName = Locale.current.localizedString(forRegionCode: code.uppercased()) ?? "Unknown"
        detectedCountry = CountryInfo(code: lowercasedCode, name: countryName)
        
        Logger.debug("📍 Location updated: \(countryName) (\(code.uppercased()))", category: .general)
        
        // Post notification that location was updated
        NotificationCenter.default.post(name: .locationDidUpdate, object: nil)
    }
    
    /// Updates the preferred language code
    func updateLanguageCode(_ code: String) {
        let lowercasedCode = code.lowercased()
        guard lowercasedCode != currentLanguageCode else { return }
        
        currentLanguageCode = lowercasedCode
        
        Logger.debug("🌍 Language updated: \(code)", category: .general)
        
        // Post notification that location was updated
        NotificationCenter.default.post(name: .locationDidUpdate, object: nil)
    }
    
    /// Manually set country and language (useful for Italian users or testing)
    func setCountryAndLanguage(country: String, language: String) {
        updateCountryCode(country)
        updateLanguageCode(language)
        
        Logger.debug("📍 Manually set location to \(country.uppercased()), language: \(language)", category: .general)
    }
}

// CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Reverse geocode to get country code
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let placemark = placemarks?.first {
                if let countryCode = placemark.isoCountryCode?.lowercased() {
                    DispatchQueue.main.async {
                        self.updateCountryInfo(
                            code: countryCode,
                            name: placemark.country ?? "Unknown"
                        )
                        
                        // Post notification that location was updated
                        NotificationCenter.default.post(name: .locationDidUpdate, object: nil)
                    }
                }
            }
        }
        
        // Stop updating location after getting one good result
        manager.stopUpdatingLocation()
    }
    
    private func updateCountryInfo(code: String, name: String? = nil) {
        currentCountryCode = code.lowercased()
        
        let countryName = name ?? Locale.current.localizedString(forRegionCode: code.uppercased()) ?? "Unknown"
        detectedCountry = CountryInfo(code: code, name: countryName)
        
        Logger.debug("📍 GPS location detected: \(countryName) (\(code.uppercased()))", category: .general)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("Location manager failed with error: \(error.localizedDescription)")
        #endif
    }
}

// Notification Extension

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
}
