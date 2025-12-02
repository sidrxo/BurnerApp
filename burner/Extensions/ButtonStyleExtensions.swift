import SwiftUI

// MARK: - Unified Button Styles (ButtonStyle protocol implementations)

/// Primary button style with scaling effect on press
/// Used for main action buttons - white background with black text
struct PrimaryButton: ButtonStyle {
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var maxWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appBody()
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
/// Used for outlined buttons - transparent background with border
struct SecondaryButton: ButtonStyle {
    var backgroundColor: Color = Color.gray.opacity(0.1)
    var foregroundColor: Color = .white
    var borderColor: Color = .white
    var maxWidth: CGFloat? = nil

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appBody()
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
/// Used for icon-only buttons like bookmark/share
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

/// No highlight button style - used for navigation links with hero animations
/// Removes the default SwiftUI press highlighting to avoid visual conflicts with zoom transitions
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

// MARK: - Convenience Button Component

/// Convenience button component with primary/secondary variants
struct BurnerButton: View {
    enum Style {
        case primary    // White background, black text
        case secondary  // Outlined, white text
    }

    let title: String
    let style: Style
    let maxWidth: CGFloat?
    let action: () -> Void

    init(
        _ title: String,
        style: Style = .primary,
        maxWidth: CGFloat? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.maxWidth = maxWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(style == .primary
            ? AnyButtonStyle(PrimaryButton(maxWidth: maxWidth))
            : AnyButtonStyle(SecondaryButton(maxWidth: maxWidth))
        )
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
