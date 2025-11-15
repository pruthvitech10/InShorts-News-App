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
    private var currentCountryCode: String = "us" // Default to US
    private var currentLanguageCode: String = "en" // Default to English
    
    // Country information
    struct CountryInfo {
        let code: String
        let name: String
        var displayName: String { "\(name) (\(code.uppercased()))" }
    }
    
    private(set) var detectedCountry: CountryInfo = CountryInfo(code: "us", name: "United States")
    
    private override init() {
        super.init()
        setupLocationManager()
        loadCachedLocation()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyReduced
    }
    
    private func loadCachedLocation() {
        // Load cached values from UserDefaults
        if let country = UserDefaults.standard.string(forKey: "cachedCountryCode") {
            currentCountryCode = country.lowercased()
            updateCountryInfo(code: currentCountryCode)
        }
        
        if let language = UserDefaults.standard.string(forKey: "cachedLanguageCode") {
            currentLanguageCode = language.lowercased()
        } else {
            // Fallback to device language
            currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
            UserDefaults.standard.set(currentLanguageCode, forKey: "cachedLanguageCode")
        }
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
        UserDefaults.standard.set(lowercasedCode, forKey: "cachedCountryCode")
    }
    
    /// Updates the preferred language code
    func updateLanguageCode(_ code: String) {
        let lowercasedCode = code.lowercased()
        guard lowercasedCode != currentLanguageCode else { return }
        
        currentLanguageCode = lowercasedCode
        UserDefaults.standard.set(lowercasedCode, forKey: "cachedLanguageCode")
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
        UserDefaults.standard.set(currentCountryCode, forKey: "cachedCountryCode")
        
        let countryName = name ?? Locale.current.localizedString(forRegionCode: code.uppercased()) ?? "Unknown"
        detectedCountry = CountryInfo(code: code, name: countryName)
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
