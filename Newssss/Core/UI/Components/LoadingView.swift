//
//  LoadingView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI

struct LoadingView: View {
    var message: String = "Loading news..."
    var scale: CGFloat = 1.5
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(scale)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
