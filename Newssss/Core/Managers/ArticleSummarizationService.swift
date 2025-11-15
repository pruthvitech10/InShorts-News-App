//
//  ArticleSummarizationService.swift
//  DailyNews
//
//  On-Device AI Summarization using Apple's NaturalLanguage framework
//  Created on 5 November 2025
//

import Foundation
import NaturalLanguage

// Summarization errors

enum SummarizationError: LocalizedError {
    case textTooShort
    case invalidInput
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .textTooShort:
            return "Text is too short to summarize"
        case .invalidInput:
            return "Invalid or empty text provided"
        case .processingFailed:
            return "Failed to process text for summarization"
        }
    }
}

// AI-powered article summarization
// Runs off main thread for performance
actor ArticleSummarizationService {
    static let shared = ArticleSummarizationService()
    
    // Settings
    
    private struct Config {
        static let minTextLength = 100
        static let minSentenceLength = 10
        static let targetSentences = 3
        static let keywordCount = 5
        static let maxTextLength = 50_000
        
        // Scoring weights
        static let positionWeight = 0.4
        static let lengthWeight = 0.3
        static let keywordWeight = 0.3
    }
    
    // Summary cache
    
    private var summaryCache: [String: String] = [:]
    private var keywordCache: [String: [String]] = [:]
    private let maxCacheSize = 100
    
    private init() {}
    
    // Summarize articles
    
    // Extract key sentences from article
    /// - Parameters:
    ///   - text: Full article text
    ///   - sentences: Number of sentences to return (default: 3)
    /// - Returns: Summary text
    func summarize(_ text: String, sentences: Int = Config.targetSentences) async throws -> String {
        // Validate input
        guard !text.isEmpty else {
            throw SummarizationError.invalidInput
        }
        
        // Clean the text
        let cleanedText = text.cleanedForNews()
        
        // Check minimum length
        guard cleanedText.count >= Config.minTextLength else {
            return cleanedText // Return as-is if too short
        }
        
        // Truncate if too long
        let processableText = cleanedText.count > Config.maxTextLength
            ? String(cleanedText.prefix(Config.maxTextLength))
            : cleanedText
        
        // Check cache
        let cacheKey = "\(processableText.hashValue)-\(sentences)"
        if let cached = summaryCache[cacheKey] {
            Logger.debug("📝 Using cached summary", category: .general)
            return cached
        }
        
        // Process on background queue
        let summary = try await Task.detached(priority: .userInitiated) {
            try await self.performSummarization(processableText, targetSentences: sentences)
        }.value
        
        // Cache result
        await cacheSummary(summary, forKey: cacheKey)
        
        Logger.debug("📝 Generated summary: \(summary.prefix(100))...", category: .general)
        
        return summary
    }
    
    /// Clear summary cache
    func clearCache() {
        summaryCache.removeAll()
        keywordCache.removeAll()
        Logger.debug("🗑️ Summary cache cleared", category: .general)
    }
    
    // Internal logic
    
    private func cacheSummary(_ summary: String, forKey key: String) {
        // Limit cache size
        if summaryCache.count >= maxCacheSize {
            // Remove oldest entries (simple FIFO)
            let keysToRemove = Array(summaryCache.keys.prefix(10))
            keysToRemove.forEach { summaryCache.removeValue(forKey: $0) }
        }
        summaryCache[key] = summary
    }
    
    private func performSummarization(_ text: String, targetSentences: Int) async throws -> String {
        // Extract sentences
        let sentences = extractSentences(from: text)
        
        // If fewer sentences than target, return original
        guard sentences.count >= targetSentences else {
            return text
        }
        
        // Extract keywords (cached)
        let keywords = await extractKeywords(from: text)
        
        // Score sentences
        let scoredSentences = scoreSentences(sentences, keywords: keywords)
        
        // Get top N sentences
        let topSentences = Array(scoredSentences.prefix(targetSentences))
        
        // Sort by original order for coherent reading
        let orderedSentences = topSentences.sorted { $0.index < $1.index }
        
        // Join sentences
        let summary = orderedSentences.map { $0.sentence }.joined(separator: " ")
        
        return summary
    }
    
    /// Extract sentences from text using NLTokenizer
    private func extractSentences(from text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [String] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = String(text[range])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Filter short and invalid sentences
            if sentence.count >= Config.minSentenceLength &&
               sentence.hasMeaningfulContent {
                sentences.append(sentence)
            }
            
            return true
        }
        
        return sentences
    }
    
    /// Score sentences based on multiple criteria
    private func scoreSentences(
        _ sentences: [String],
        keywords: [String]
    ) -> [(sentence: String, score: Double, index: Int)] {
        sentences.enumerated().map { index, sentence in
            var score = 0.0
            
            // 1. Position score (first sentences often contain key info)
            let positionScore = 1.0 - (Double(index) / Double(max(sentences.count, 1)))
            score += positionScore * Config.positionWeight
            
            // 2. Length score (prefer medium-length sentences)
            let wordCount = sentence.split(separator: " ").count
            let lengthScore: Double
            if wordCount >= 10 && wordCount <= 30 {
                lengthScore = 1.0
            } else if wordCount >= 5 && wordCount <= 50 {
                lengthScore = 0.7
            } else {
                lengthScore = 0.3
            }
            score += lengthScore * Config.lengthWeight
            
            // 3. Keyword score (sentences with important words)
            let sentenceLower = sentence.lowercased()
            let matchedKeywords = keywords.filter { sentenceLower.contains($0) }
            let keywordScore = min(Double(matchedKeywords.count) / Double(max(Config.keywordCount, 1)), 1.0)
            score += keywordScore * Config.keywordWeight
            
            // 4. Bonus for sentences with numbers (often contain facts)
            if sentence.range(of: #"\d+"#, options: .regularExpression) != nil {
                score += 0.1
            }
            
            // 5. Penalty for questions (usually less informative in summaries)
            if sentence.hasSuffix("?") {
                score -= 0.1
            }
            
            return (sentence: sentence, score: max(score, 0), index: index)
        }
        .sorted { $0.score > $1.score }
    }
    
    /// Extract important keywords using NLTagger
    private func extractKeywords(from text: String) async -> [String] {
        // Check cache first
        let cacheKey = "\(text.hashValue)"
        if let cached = keywordCache[cacheKey] {
            return cached
        }
        
        // Perform extraction on background
        let keywords = await Task.detached(priority: .utility) {
            self.performKeywordExtraction(from: text)
        }.value
        
        // Cache keywords
        if keywordCache.count >= maxCacheSize {
            let keysToRemove = Array(keywordCache.keys.prefix(10))
            keysToRemove.forEach { keywordCache.removeValue(forKey: $0) }
        }
        keywordCache[cacheKey] = keywords
        
        return keywords
    }
    
    private nonisolated func performKeywordExtraction(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        
        tagger.enumerateTags(
            in: text.startIndex..<text.endIndex,
            unit: .word,
            scheme: .lexicalClass,
            options: options
        ) { tag, range in
            // Extract nouns (most important content words)
            if tag == .noun {
                let word = String(text[range]).lowercased()
                // Filter short and common words
                if word.count > 3 && !Self.commonWords.contains(word) {
                    keywords.append(word)
                }
            }
            return true
        }
        
        // Calculate frequency and return top keywords
        let frequency = Dictionary(grouping: keywords, by: { $0 })
            .mapValues { $0.count }
        
        let topKeywords = frequency
            .sorted { $0.value > $1.value }
            .prefix(Config.keywordCount)
            .map { $0.key }
        
        return Array(topKeywords)
    }
    
    // Common words to filter out
    private static let commonWords: Set<String> = [
        "this", "that", "these", "those", "which", "what", "when", "where",
        "there", "their", "they", "them", "have", "been", "being", "said",
        "would", "could", "should", "will", "about", "after", "before",
        "more", "most", "some", "such", "into", "through", "over", "under"
    ]
}

// Batch processing

extension ArticleSummarizationService {
    /// Summarize multiple articles in parallel with rate limiting
    /// - Parameters:
    ///   - articles: Articles to summarize
    ///   - maxConcurrent: Maximum concurrent operations (default: 5)
    /// - Returns: Articles with summaries
    func summarizeBatch(
        _ articles: [Article],
        maxConcurrent: Int = 5
    ) async -> [Article] {
        await withTaskGroup(of: (Int, Article).self, returning: [Article].self) { group in
            var index = 0
            var results: [(Int, Article)] = []
            results.reserveCapacity(articles.count)
            
            // Process in batches to avoid overwhelming the system
            for article in articles {
                let currentIndex = index
                index += 1
                
                // Wait if we've reached max concurrent tasks
                if index % maxConcurrent == 0 {
                    if let result = await group.next() {
                        results.append(result)
                    }
                }
                
                group.addTask {
                    let text = article.content ?? article.description ?? ""
                    do {
                        let summary = try await self.summarize(text)
                        return (currentIndex, article.withSummary(summary))
                    } catch {
                        Logger.error("Failed to summarize article: \(error)", category: .general)
                        // Return original article on error
                        return (currentIndex, article)
                    }
                }
            }
            
            // Collect remaining results
            for await result in group {
                results.append(result)
            }
            
            // Sort by original order
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    /// Quick summarization for preview purposes (less accurate but faster)
    func quickSummarize(_ text: String) async -> String {
        let cleaned = text.cleanedForNews()
        
        // For quick summaries, just take first 2 sentences
        guard cleaned.count >= Config.minTextLength else {
            return cleaned
        }
        
        let sentences = extractSentences(from: cleaned)
        let preview = Array(sentences.prefix(2)).joined(separator: " ")
        
        return preview.truncatedAtWord(to: 200)
    }
}

// Article helpers
// Article.withSummary() is defined in Models/Article.swift
