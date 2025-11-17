//
//  String+Clean.swift
//  ShortsNewsClone
//
//  Created on 29 October 2025.
//

import Foundation

// Remove HTML tags and entities

extension String {
    /// Removes HTML tags and decodes HTML entities
    /// - Returns: Clean plain text string
    func stripHTML() -> String {
        var result = self
        
        // Remove HTML tags
        result = result.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Decode HTML entities
        result = result.decodingHTMLEntities()
        
        // Clean up whitespace
        result = result.cleanWhitespace()
        
        return result
    }
    
    /// Decodes common HTML entities (e.g., &amp; → &, &quot; → ")
    func decodingHTMLEntities() -> String {
        guard self.contains("&") else { return self }
        
        var result = self
        
        // Common HTML entities
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&nbsp;": " ",
            "&ndash;": "–",
            "&mdash;": "—",
            "&hellip;": "…",
            "&rsquo;": "'",
            "&lsquo;": "'",
            "&rdquo;": "\u{0022}",
            "&ldquo;": "\u{0022}"
        ]
        
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Decode numeric entities (e.g., &#8217; or &#x2019;)
        result = result.replacingOccurrences(
            of: "&#(\\d+);",
            with: "$1",
            options: .regularExpression
        )
        
        return result
    }
    
    /// Strips HTML while preserving basic structure (line breaks)
    func stripHTMLPreservingStructure() -> String {
        var result = self
        
        // Convert block-level tags to newlines
        let blockTags = ["</p>", "</div>", "</br>", "<br>", "<br/>", "</h[1-6]>"]
        for tag in blockTags {
            result = result.replacingOccurrences(
                of: tag,
                with: "\n",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Remove all other HTML tags
        result = result.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Decode entities
        result = result.decodingHTMLEntities()
        
        // Clean excessive newlines (max 2 consecutive)
        result = result.replacingOccurrences(
            of: "\n{3,}",
            with: "\n\n",
            options: .regularExpression
        )
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Truncate text

extension String {
    /// Truncates string to specified length
    /// - Parameters:
    ///   - length: Maximum length
    ///   - addEllipsis: Whether to add "..." at the end
    /// - Returns: Truncated string
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        guard self.count > length else { return self }
        
        let truncated = String(self.prefix(length))
        return addEllipsis ? truncated + "…" : truncated
    }
    
    /// Truncates to specified length at word boundary
    /// - Parameters:
    ///   - length: Maximum length
    ///   - addEllipsis: Whether to add "..." at the end
    /// - Returns: Truncated string at nearest word boundary
    func truncatedAtWord(to length: Int, addEllipsis: Bool = true) -> String {
        guard self.count > length else { return self }
        
        // Find the last space before the length limit
        let truncatedString = String(self.prefix(length))
        if let lastSpace = truncatedString.lastIndex(of: " ") {
            let result = String(truncatedString[..<lastSpace])
            return addEllipsis ? result + "…" : result
        }
        
        // No space found, use character truncation
        return self.truncated(to: length, addEllipsis: addEllipsis)
    }
    
    /// Truncates to specified number of sentences
    /// - Parameters:
    ///   - sentences: Number of sentences to keep
    ///   - addEllipsis: Whether to add "..." at the end
    /// - Returns: Truncated string
    func truncatedToSentences(_ sentences: Int, addEllipsis: Bool = true) -> String {
        let sentenceEndings = [".", "!", "?"]
        var count = 0
        var _ = startIndex
        
        for (index, char) in self.enumerated() {
            if sentenceEndings.contains(String(char)) {
                count += 1
                if count == sentences {
                    let endIndex = self.index(startIndex, offsetBy: index + 1)
                    return String(self[..<endIndex])
                }
            }
        }
        
        // If we didn't find enough sentences, return the whole string
        return self
    }
}

// Clean up whitespace

extension String {
    /// Removes extra whitespace and newlines, keeping single spaces
    func cleanWhitespace() -> String {
        self.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    /// Removes all whitespace (including spaces)
    func removeAllWhitespace() -> String {
        self.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }
    
    /// Normalizes whitespace (replaces multiple spaces with single space)
    func normalizeWhitespace() -> String {
        self.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Removes leading and trailing whitespace from each line
    func trimLines() -> String {
        self.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
    }
}

// Handle special characters

extension String {
    /// Removes emoji characters
    func removingEmojis() -> String {
        self.filter { !$0.isEmoji }
    }
    
    /// Removes special characters, keeping only alphanumerics and spaces
    func removingSpecialCharacters() -> String {
        self.components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
    }
    
    /// Keeps only alphanumeric characters
    func alphanumericOnly() -> String {
        self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

// Remove URLs from text

extension String {
    /// Removes URLs from text
    func removingURLs() -> String {
        self.replacingOccurrences(
            of: "https?://[^\\s]+",
            with: "",
            options: .regularExpression
        ).cleanWhitespace()
    }
    
    /// Extracts all URLs from text
    func extractingURLs() -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }
        
        let matches = detector.matches(in: self, range: NSRange(location: 0, length: utf16.count))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: self) else { return nil }
            return String(self[range])
        }
    }
}

// Clean text for news display

extension String {
    /// Cleans text for news article display
    /// Removes HTML, normalizes whitespace, and decodes entities
    func cleanedForNews() -> String {
        self.stripHTML()
            .cleanWhitespace()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Creates a clean summary from news content
    /// - Parameters:
    ///   - maxLength: Maximum character length
    ///   - sentences: Maximum number of sentences
    /// - Returns: Clean summary text
    func newsExcerpt(maxLength: Int = 200, sentences: Int = 2) -> String {
        let cleaned = self.cleanedForNews()
        let truncated = cleaned.truncatedToSentences(sentences)
        return truncated.truncatedAtWord(to: maxLength)
    }
}

// Text validation

extension String {
    /// Checks if string contains only whitespace or is empty
    var isBlankOrEmpty: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Checks if string has meaningful content (not just whitespace/HTML)
    var hasMeaningfulContent: Bool {
        let cleaned = self.stripHTML()
        return !cleaned.isBlankOrEmpty && cleaned.count >= AppConstants.minSentenceLength
    }
}

// Emoji detection

private extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
