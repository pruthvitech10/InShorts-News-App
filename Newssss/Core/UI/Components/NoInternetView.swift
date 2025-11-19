//
//  NoInternetView.swift
//  Newssss
//
//  Created on 19 November 2025.
//

import SwiftUI

struct NoInternetView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 70))
                    .foregroundColor(.red)
                
                Text("No Internet Connection")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This app requires an active internet connection to function. Please check your settings and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Open Settings Button
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Open Settings")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
            }
        }
        .zIndex(999) // Ensure it covers everything
    }
}

#Preview {
    NoInternetView()
}
