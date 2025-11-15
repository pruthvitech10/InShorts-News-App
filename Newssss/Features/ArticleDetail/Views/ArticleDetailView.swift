//
//  ArticleDetailView.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//


import SwiftUI



struct ArticleDetailView: View {
    @StateObject var viewModel: ArticleDetailViewModel
    @State private var showWebView = false
    @Environment(\.dismiss) private var dismiss

    init(article: Article) {
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Robust image loading with fallback
                    if let imageUrl = viewModel.article.urlToImage, let url = URL(string: imageUrl), !imageUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxHeight: 300)
                                        .clipped()
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 300)
                                        .overlay(ProgressView())
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                @unknown default:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                            }
                            Divider()

                            if viewModel.isLoadingSummary {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Loading summary...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    if !viewModel.summary.isEmpty {
                                        Text("Summary")
                                            .font(.headline)
                                        Text(viewModel.summary)
                                            .font(.body)
                                    } else {
                                        Text("No summary available.")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            #if DEBUG
                                            .onAppear {
                                                print("[ArticleDetailView] Summary is empty for article: \(viewModel.article.title)")
                                            }
                                            #endif
                                    }
                                    if !viewModel.translatedSummary.isEmpty {
                                        Divider()
                                        Text("Translated Summary")
                                            .font(.headline)
                                        Text(viewModel.translatedSummary)
                                            .font(.body)
                                    }
                                    if viewModel.isTranslating {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                            Text("Translating...")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    // Always show Translate button
                                    Button(action: {
                                        Task {
                                            let lang = TranslationService.shared.getUserPreferredLanguage()
                                            await viewModel.translateSummary(to: lang)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "globe")
                                            Text("Translate")
                                        }
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    if let error = viewModel.translationError {
                                        Text(error)
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            }

                            Divider()

                            if let description = viewModel.article.description, !description.isEmpty {
                                Text(description)
                                    .font(.body)
                            } else {
                                Text("No description available.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Button(action: {
                                showWebView = true
                            }) {
                                HStack {
                                    Text("Read Full Article")
                                    Image(systemName: "arrow.up.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.toggleBookmark()
                    }) {
                        Image(systemName: viewModel.isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                }
            }
            .fullScreenCover(isPresented: $showWebView) {
                let urlString = viewModel.article.url
                if let url = URL(string: urlString) {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
        }
    }
}
