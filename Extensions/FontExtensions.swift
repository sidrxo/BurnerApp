import SwiftUI

extension Font {
    // Central font configuration - change this to switch fonts app-wide
    private static let fontFamily = "Avenir" // Change this to switch fonts easily
    
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
    
    // Convenience methods that match SwiftUI's built-in styles
    static var appLargeTitle: Font { appFont(size: 34, weight: .regular) }
    static var appTitle: Font { appFont(size: 28, weight: .regular) }
    static var appTitle2: Font { appFont(size: 22, weight: .regular) }
    static var appTitle3: Font { appFont(size: 20, weight: .regular) }
    static var appHeadline: Font { appFont(size: 17, weight: .semibold) }
    static var appSubheadline: Font { appFont(size: 15, weight: .regular) }
    static var appBody: Font { appFont(size: 17, weight: .regular) }
    static var appCallout: Font { appFont(size: 16, weight: .regular) }
    static var appFootnote: Font { appFont(size: 13, weight: .regular) }
    static var appCaption: Font { appFont(size: 12, weight: .regular) }
    static var appCaption2: Font { appFont(size: 11, weight: .regular) }
}

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.font(.appFont(size: size, weight: weight))
    }
}
