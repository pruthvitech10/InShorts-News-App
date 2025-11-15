//
//  ToastView.swift
//  DailyNews
//
//  Created on 13 November 2025.
//

import SwiftUI


struct ToastView: View {
    let toast: Toast
    
    var body: some View {
        HStack {
            Image(systemName: toast.style.icon)
                .foregroundColor(toast.style.color)
            Text(toast.message)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}
