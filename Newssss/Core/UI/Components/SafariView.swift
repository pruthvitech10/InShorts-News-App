//
//  SafariView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI
import SafariServices


struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true
        configuration.barCollapsingEnabled = true
        
        let safariVC = SFSafariViewController(url: url, configuration: configuration)
        safariVC.preferredBarTintColor = UIColor.systemBackground
        safariVC.preferredControlTintColor = UIColor.systemBlue
        safariVC.dismissButtonStyle = .close
        safariVC.delegate = context.coordinator
        
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            // Called when user taps Done button
        }
        
        func safariViewController(_ controller: SFSafariViewController, initialLoadDidRedirectTo URL: URL) {
            // Handle redirects
            Logger.debug("Safari redirected to: \(URL.absoluteString)", category: .view)
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            if !didLoadSuccessfully {
                Logger.error("Safari failed to load URL", category: .view)
            }
        }
    }
}
