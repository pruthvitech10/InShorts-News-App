import Foundation

struct ValidationUtil {
    /// Validate search query
    /// - Returns: Tuple of (isValid, errorMessage)
    static func validateSearchQuery(_ query: String) -> (isValid: Bool, error: String?) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return (false, "Search query cannot be empty")
        }
        
        if trimmed.count < 2 {
            return (false, "Search query must be at least 2 characters")
        }
        
        if trimmed.count > 200 {
            return (false, "Search query cannot exceed 200 characters")
        }
        
        // Check for invalid characters
        let allowedCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -\"'"))
        if !trimmed.allSatisfy({ allowedCharacterSet.contains($0.unicodeScalars.first!) }) {
            return (false, "Search query contains invalid characters")
        }
        
        return (true, nil)
    }
    
    /// Sanitize user input for display
    static func sanitizeForDisplay(_ text: String, maxLength: Int = 1000) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if result.count > maxLength {
            result = String(result.prefix(maxLength)) + "..."
        }
        
        return result
    }
}
