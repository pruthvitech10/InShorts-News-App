import Foundation

struct SecurityUtil {
    /// Safely mask sensitive strings for logging
    static func maskSensitive(_ value: String, showChars: Int = 4) -> String {
        guard value.count > showChars * 2 else {
            return String(repeating: "*", count: value.count)
        }
        
        let visible = value.prefix(showChars) + String(repeating: "*", count: value.count - showChars * 2) + value.suffix(showChars)
        return String(visible)
    }
    
    /// Mask URL query parameters
    static func maskURL(_ url: URL) -> String {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var masked = url.absoluteString
        
        if let queryItems = components?.queryItems {
            for item in queryItems where ["apikey", "apiKey", "key", "token"].contains(item.name.lowercased()) {
                if let value = item.value {
                    let maskedValue = maskSensitive(value)
                    masked = masked.replacingOccurrences(of: value, with: maskedValue)
                }
            }
        }
        
        return masked
    }
}
