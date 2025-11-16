//
//  LocationSettingsView.swift
//  Newssss
//
//  Created on 10 November 2025.
//

import SwiftUI

struct LocationSettingsView: View {
    @StateObject private var locationService = LocationService.shared
    @State private var selectedCountry: SupportedCountry = .italy
    @State private var searchText = ""
    @State private var showSuccessMessage = false
    
    private var filteredCountries: [SupportedCountry] {
        if searchText.isEmpty {
            return SupportedCountry.allCases
        }
        return SupportedCountry.allCases.filter { country in
            country.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            
            if searchText.isEmpty {
                currentLocationSection
            }
            
            countryList
        }
        .navigationTitle("News Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSavedCountry)
        .overlay(
            Group {
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Location updated to \(selectedCountry.displayName)")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: showSuccessMessage)
                }
            }
        )
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search countries", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var currentLocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Location")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
            
            currentLocationButton
            
            Divider()
                .padding(.top, 8)
        }
    }
    
    private var currentLocationButton: some View {
        Button(action: {}) {
            HStack {
                countryFlag(for: selectedCountry)
                countryInfo(for: selectedCountry)
                Spacer()
                checkmark
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .disabled(true)
    }
    
    private func countryFlag(for country: SupportedCountry) -> some View {
        let parts = country.displayName.split(separator: " ")
        let flag = parts.first.map(String.init) ?? ""
        return Text(flag).font(.title2)
    }
    
    private func countryInfo(for country: SupportedCountry) -> some View {
        let parts = country.displayName.split(separator: " ")
        let name = parts.last.map(String.init) ?? ""
        
        return VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .foregroundColor(.primary)
                .fontWeight(.medium)
            Text("News from \(name)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var checkmark: some View {
        Image(systemName: "checkmark")
            .foregroundColor(.blue)
            .fontWeight(.semibold)
    }
    
    private var countryList: some View {
        List {
            Section(header: Text(searchText.isEmpty ? "All Countries" : "Search Results")) {
                ForEach(filteredCountries, id: \.rawValue) { country in
                    countryRow(for: country)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func countryRow(for country: SupportedCountry) -> some View {
        Button(action: { selectCountry(country) }) {
            HStack {
                let parts = country.displayName.split(separator: " ")
                let flag = parts.first.map(String.init) ?? ""
                let name = parts.last.map(String.init) ?? ""
                
                Text(flag).font(.title2)
                Text(name).foregroundColor(.primary)
                Spacer()
                
                if selectedCountry.rawValue == country.rawValue {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func selectCountry(_ country: SupportedCountry) {
        selectedCountry = country
        
        // Update LocationService with country and its primary language
        locationService.setCountryAndLanguage(
            country: country.rawValue,
            language: country.primaryLanguage
        )
        
        // Save selected country for persistence
        UserDefaults.standard.set(country.rawValue, forKey: "selectedCountryCode")
        UserDefaults.standard.set(country.rawValue, forKey: "cachedCountryCode")
        UserDefaults.standard.set(country.primaryLanguage, forKey: "cachedLanguageCode")
        
        Logger.debug("Country set to: \(country.displayName) (\(country.rawValue)), language: \(country.primaryLanguage)", category: .general)
        
        // Show success feedback
        showSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
    
    private func loadSavedCountry() {
        // Try to load from LocationService first
        let currentCode = locationService.getNewsCountryCode()
        if let country = SupportedCountry(rawValue: currentCode) {
            selectedCountry = country
            return
        }
        
        // Fallback to saved preference
        if let savedCode = UserDefaults.standard.string(forKey: "selectedCountryCode"),
           let country = SupportedCountry(rawValue: savedCode) {
            selectedCountry = country
        }
    }
}

#Preview {
    NavigationView {
        LocationSettingsView()
    }
}
