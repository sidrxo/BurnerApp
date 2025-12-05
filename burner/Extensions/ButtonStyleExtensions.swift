import SwiftUI

// MARK: - Unified Button Styles (ButtonStyle protocol implementations)

/// Primary button style with scaling effect on press
struct PrimaryButton: ButtonStyle {
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var maxWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, design: .monospaced))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: maxWidth)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style with scaling effect on press
struct SecondaryButton: ButtonStyle {
    var backgroundColor: Color = Color.gray.opacity(0.1)
    var foregroundColor: Color = .white
    var borderColor: Color = .white
    var maxWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, design: .monospaced))
            .foregroundColor(foregroundColor)
            .frame(maxWidth: maxWidth)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Icon button style with scaling effect on press
struct IconButton: ButtonStyle {
    var size: CGFloat = 50
    var backgroundColor: Color = Color.white.opacity(0.05)
    var cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// No highlight button style
struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == NoHighlightButtonStyle {
    static var noHighlight: NoHighlightButtonStyle {
        NoHighlightButtonStyle()
    }
}

// MARK: - New Button Style for Dimmed States (CORRECTED)

/// Dedicated style for states like "SOLD OUT" or "TICKET PURCHASED".
/// **Only the background fill is translucent and dimmed (opacity 0.5).**
/// **Text and outline remain at full opacity (1.0).**
struct DimmedOutlineButtonStyle: ButtonStyle {
    var customColor: Color // Red or White
    var dimmedOpacity: Double = 0.5
    var maxWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, design: .monospaced))
            .foregroundColor(customColor) // 1. Full Color Text
            .frame(maxWidth: maxWidth)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.gray.opacity(0.1)) // Translucent base fill
                    .opacity(dimmedOpacity) // 2. Dim the translucent fill to 50%
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(customColor, lineWidth: 1.5) // 3. Full Color Outline
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


// MARK: - Convenience Button Component (UPDATED)

/// Convenience button component with primary/secondary variants
struct BurnerButton: View {
    enum Style {
        case primary    // Solid White
        case secondary  // Translucent with White outline (Full Opacity)
        case dimmed     // Translucent Fill (Dimmed), Custom Color Outline/Text (Full Opacity)
    }

    let title: String
    let style: Style
    let maxWidth: CGFloat?
    let customColor: Color? // Used only for .dimmed style
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        maxWidth: CGFloat? = nil,
        customColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.maxWidth = maxWidth
        self.customColor = customColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle({
            switch style {
            case .primary:
                return AnyButtonStyle(PrimaryButton(maxWidth: maxWidth))
            case .secondary:
                return AnyButtonStyle(SecondaryButton(maxWidth: maxWidth))
            case .dimmed:
                // Use the new dedicated style for dimmed states
                let color = customColor ?? .gray
                return AnyButtonStyle(DimmedOutlineButtonStyle(customColor: color, maxWidth: maxWidth))
            }
        }())
    }
}

// Helper to erase ButtonStyle type
struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView

    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}
