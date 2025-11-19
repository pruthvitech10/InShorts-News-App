import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let background: AdaptiveColor = AdaptiveColor(light: .white, dark: .black)
    let secondaryBackground: AdaptiveColor = AdaptiveColor(light: Color(hex: "F5F5F7"), dark: Color(hex: "1C1C1E"))
    let cardBackground: AdaptiveColor = AdaptiveColor(light: .white, dark: Color(hex: "2C2C2E"))
    
    let primary: AdaptiveColor = AdaptiveColor(light: Color(hex: "007AFF"), dark: Color(hex: "0A84FF"))
    let secondary: AdaptiveColor = AdaptiveColor(light: .gray, dark: Color(hex: "8E8E93"))
    
    let text: AdaptiveColor = AdaptiveColor(light: .black, dark: .white)
    let secondaryText: AdaptiveColor = AdaptiveColor(light: Color(hex: "3C3C43").opacity(0.6), dark: Color(hex: "EBEBF5").opacity(0.6))
    
    let border: AdaptiveColor = AdaptiveColor(light: Color(hex: "E5E5EA"), dark: Color(hex: "38383A"))
    let separator: AdaptiveColor = AdaptiveColor(light: Color(hex: "C6C6C8"), dark: Color(hex: "38383A"))
    
    let success: AdaptiveColor = AdaptiveColor(light: .green, dark: Color(hex: "30D158"))
    let error: AdaptiveColor = AdaptiveColor(light: .red, dark: Color(hex: "FF453A"))
    let warning: AdaptiveColor = AdaptiveColor(light: .orange, dark: Color(hex: "FF9F0A"))
    let info: AdaptiveColor = AdaptiveColor(light: .blue, dark: Color(hex: "0A84FF"))
}

struct AdaptiveColor {
    let light: Color
    let dark: Color
    
    func value(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : light
    }
}
