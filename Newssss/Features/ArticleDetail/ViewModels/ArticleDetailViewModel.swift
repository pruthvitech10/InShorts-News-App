//
//  ArticleDetailViewModel.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation
import Combine


@MainActor
class ArticleDetailViewModel: ObservableObject {
    @Published var translatedSummary: String = ""
    @Published var isTranslating: Bool = false
    @Published var translationError: String? = nil
    @Published var article: Article
    @Published var isBookmarked: Bool = false
    @Published var summary: String = ""
    @Published var keyPoints: [String] = []
    @Published var isLoadingSummary: Bool = false
    
    private let bookmarkService = BookmarkService.shared
    private let llmService = LLMService.shared
    private let translationService = TranslationService.shared
    
    init(article: Article) {
        self.article = article
        self.isBookmarked = bookmarkService.isBookmarked(article)
        Task {
            do {
                try await generateSummary()
            } catch {
                Logger.error("Failed to generate summary in init: \(error.localizedDescription)", category: .viewModel)
            }
        }
    }
    @MainActor
    func translateSummary(to targetLanguage: String) async {
        isTranslating = true
        translationError = nil
        do {
            let translated = try await translationService.translate(text: summary, to: targetLanguage)
            translatedSummary = translated
        } catch {
            translationError = error.localizedDescription
        }
        isTranslating = false
    }
    
    func toggleBookmark() {
        bookmarkService.toggleBookmark(article)
        isBookmarked = bookmarkService.isBookmarked(article)
    }
    
    private func generateSummary() async throws {
        isLoadingSummary = true
        Logger.debug("Generating summary for: \(article.title.prefix(50))...", category: Logger.LoggerCategory.general)
        do {
            summary = try await llmService.summarizeArticle(article)
            keyPoints = try await llmService.generateKeyPoints(article)
            Logger.debug("Summary generated: \(summary.prefix(100))...", category: Logger.LoggerCategory.general)
        } catch {
            Logger.error("Failed to generate summary: \(error.localizedDescription)", category: Logger.LoggerCategory.viewModel)
            summary = article.description ?? "No summary available"
            keyPoints = []
        }
        isLoadingSummary = false
    }
    
    func refreshSummary() async {
        do {
            try await generateSummary()
        } catch {
            Logger.error("Failed to refresh summary: \(error.localizedDescription)", category: .viewModel)
        }
    }
}
