import SwiftUI

extension Font {
    // Central font configuration - change this to switch fonts app-wide
    private static let fontFamily = "Avenir" // Main app font
    private static let displayFontFamily = "AvenirNext" // For hero/display text
    
    static func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black:
            return .custom("\(fontFamily)-Bold", size: size)
        case .medium, .semibold:
            return .custom("\(fontFamily)-Regular", size: size)
        default:
            return .custom("\(fontFamily)-Regular", size: size)
        }
    }
    
    // Display fonts for hero sections, headers, and emphasis
    static func displayFont(size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        switch weight {
        case .black, .heavy:
            return .custom("\(displayFontFamily)-Heavy", size: size)
        case .bold:
            return .custom("\(displayFontFamily)-Bold", size: size)
        case .medium, .semibold:
            return .custom("\(displayFontFamily)-Medium", size: size)
        default:
            return .custom("\(displayFontFamily)-Regular", size: size)
        }
    }
    
    // System font alternative for maximum reliability
    static func systemDisplayFont(size: CGFloat, weight: Font.Weight = .heavy, design: Font.Design = .default) -> Font {
        return .system(size: size, weight: weight, design: design)
    }
    
    // Convenience methods that match SwiftUI's built-in styles
    static var appLargeTitle: Font { appFont(size: 34, weight: .black) }
    static var appTitle: Font { appFont(size: 28, weight: .bold) }
    static var appTitle2: Font { appFont(size: 22, weight: .regular) }
    static var appTitle3: Font { appFont(size: 20, weight: .regular) }
    static var appHeadline: Font { appFont(size: 17, weight: .semibold) }
    static var appSubheadline: Font { appFont(size: 15, weight: .regular) }
    static var appBody: Font { appFont(size: 17, weight: .regular) }
    static var appCallout: Font { appFont(size: 16, weight: .regular) }
    static var appFootnote: Font { appFont(size: 13, weight: .regular) }
    static var appCaption: Font { appFont(size: 12, weight: .regular) }
    static var appCaption2: Font { appFont(size: 11, weight: .regular) }
    
    // New display font styles
    static var heroTitle: Font { displayFont(size: 36, weight: .heavy) }
    static var featuredTitle: Font { displayFont(size: 32, weight: .heavy) }
    static var displayLarge: Font { displayFont(size: 28, weight: .bold) }
    static var displayMedium: Font { displayFont(size: 24, weight: .bold) }
    
    // System font alternatives
    static var systemHeroTitle: Font { systemDisplayFont(size: 36, weight: .heavy) }
    static var systemFeaturedTitle: Font { systemDisplayFont(size: 32, weight: .heavy) }
}

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.appFont(size: size, weight: weight))
    }
    
    func displayFont(size: CGFloat, weight: Font.Weight = .heavy) -> some View {
        self.font(.displayFont(size: size, weight: weight))
    }
    
    func systemDisplayFont(size: CGFloat, weight: Font.Weight = .heavy, design: Font.Design = .default) -> some View {
        self.font(.systemDisplayFont(size: size, weight: weight, design: design))
    }
    
    // Convenience modifiers for hero text styling
    func heroTextStyle() -> some View {
        self
            .font(.heroTitle)
            .tracking(1.2)
            .lineSpacing(2)
    }
    
    func systemHeroTextStyle() -> some View {
        self
            .font(.systemHeroTitle)
            .tracking(1.2)
            .lineSpacing(2)
    }
}
