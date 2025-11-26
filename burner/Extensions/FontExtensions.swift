import SwiftUI

extension Font {
    private static let fontFamily = "Helvetica"

    static func appFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black:
            return .custom("\(fontFamily)-Bold", size: size)
        case .medium, .semibold:
            return .custom("\(fontFamily)-Medium", size: size)
        default:
            return .custom("\(fontFamily)-Regular", size: size)
        }
    }

    // Monospaced font for buttons and code-like elements
    static func appMonospaced(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .monospaced)
    }

    // Semantic font sizes
    static var appCaption: Font { appFont(size: 12) }
    static var appSecondary: Font { appFont(size: 14) }
    static var appBody: Font { appFont(size: 16) }
    static var appCard: Font { appFont(size: 18) }
    static var appSectionHeader: Font { appFont(size: 24) }
    static var appPageHeader: Font { appFont(size: 28) }
    static var appHero: Font { appFont(size: 32) }

    static var appIcon: Font { .system(size: 16) }
    static var appLargeIcon: Font { .system(size: 60) }

    // Button font (monospaced)
    static var appButton: Font { appMonospaced(size: 16) }


}

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.appFont(size: size, weight: weight))
    }

    func appMonospaced(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.appMonospaced(size: size, weight: weight))
    }

    // Semantic font modifiers
    func appCaption() -> some View {
        self.font(.appCaption)
    }

    func appSecondary() -> some View {
        self.font(.appSecondary)
    }

    func appBody() -> some View {
        self.font(.appBody)
            .kerning(-0.3) // Negative kerning for tighter letter spacing
    }

    func appCard() -> some View {
           self.font(.appCard)
       }

    func appSectionHeader() -> some View {
        self.font(.appSectionHeader)
    }

    func appPageHeader() -> some View {
        self.font(.appPageHeader)
    }

    func appHero() -> some View {
        self.font(.appHero)
    }

    func appButton() -> some View {
        self.font(.appButton)
    }
}
