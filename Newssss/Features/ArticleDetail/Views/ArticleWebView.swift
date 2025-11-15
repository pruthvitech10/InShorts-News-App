//
//  ArticleWebView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import SwiftUI
import WebKit


struct ArticleWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Logger.debug("Started loading web content", category: .general)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Logger.debug("Finished loading web content", category: .general)
        }
    }
}
