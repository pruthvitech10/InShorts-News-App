//
//  ArticleWebView.swift
//  Newssss
//
//  Enhanced WebView with translate button for Italian articles
//  Works even on paywall pages
//

import SwiftUI
import WebKit
import Translation

// Wrapper view with translate button
struct ArticleWebViewWrapper: View {
    let url: URL
    let articleTitle: String
    let articleDescription: String?
    
    @Environment(\.dismiss) private var dismiss
    @State private var showTranslationUI = false
    @State private var extractedText = ""
    @State private var webViewCoordinator = WebViewCoordinator()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Show web page
                ArticleWebViewWithExtraction(url: url, coordinator: webViewCoordinator)
            
            // Floating translate button
            HStack {
                Spacer()
                
                Button(action: {
                    Task {
                        // Extract text first
                        let text = await webViewCoordinator.extractArticleText()
                        if !text.isEmpty {
                            extractedText = text
                        } else {
                            // Fallback to title + description
                            extractedText = articleTitle + "\n\n" + (articleDescription ?? "")
                        }
                        showTranslationUI = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.body)
                        Text("Translate")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Article")
                        .font(.headline)
                }
            }
            .translationPresentation(isPresented: $showTranslationUI, text: extractedText)
        }
    }
}

// WebView Coordinator to extract text
class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var webView: WKWebView?
    
    func extractArticleText() async -> String {
        guard let webView = webView else { return "" }
        
        // JavaScript to extract article text from the page
        let script = """
        (function() {
            // Try to find article content
            let article = document.querySelector('article') ||
                         document.querySelector('.article-content') ||
                         document.querySelector('.post-content') ||
                         document.querySelector('main') ||
                         document.body;
            
            // Get all paragraphs
            let paragraphs = article.querySelectorAll('p');
            let text = '';
            
            paragraphs.forEach(function(p) {
                text += p.innerText + '\\n\\n';
            });
            
            return text;
        })();
        """
        
        do {
            let result = try await webView.evaluateJavaScript(script)
            return (result as? String) ?? ""
        } catch {
            Logger.error("Failed to extract text: \(error)", category: .general)
            return ""
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView = webView
        Logger.debug("Web page loaded", category: .general)
    }
}

// WebView with text extraction
struct ArticleWebViewWithExtraction: UIViewRepresentable {
    let url: URL
    var coordinator: WebViewCoordinator
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = coordinator
        coordinator.webView = webView
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// String extension for chunking
extension String {
    func splitIntoChunks(maxSize: Int) -> [String] {
        var chunks: [String] = []
        var currentChunk = ""
        
        let sentences = self.components(separatedBy: ". ")
        
        for sentence in sentences {
            if currentChunk.count + sentence.count > maxSize {
                chunks.append(currentChunk)
                currentChunk = sentence + ". "
            } else {
                currentChunk += sentence + ". "
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
}

// Original WebView
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
