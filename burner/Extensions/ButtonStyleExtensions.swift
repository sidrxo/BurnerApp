import SwiftUI

// MARK: - Button Style Modifiers
extension View {
    /// Primary button style - used for main action buttons like sign-in buttons
    /// Background with border and full width
    func primaryButtonStyle(
        backgroundColor: Color = Color.black.opacity(0.7),
        foregroundColor: Color = .white,
        borderColor: Color = Color.white.opacity(0.2)
    ) -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
    }
    /// Secondary button style - used for call-to-action buttons
    /// Solid background, no border
    func secondaryButtonStyle(
        backgroundColor: Color = .white,
        foregroundColor: Color = .black,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor) // ✅ Fix
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Icon button style - used for icon-only buttons like bookmark/share
    /// Square/rounded button with background
    func iconButtonStyle(
        size: CGFloat = 50,
        backgroundColor: Color = Color.white.opacity(0.1),
        cornerRadius: CGFloat = 12
    ) -> some View {
        self
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
}

// MARK: - Button Styles (ButtonStyle protocol implementations)

/// Primary button style with scaling effect on press
struct PrimaryButton: ButtonStyle {
    var backgroundColor: Color = Color.black.opacity(0.7)
    var foregroundColor: Color = .white
    var borderColor: Color = Color.white.opacity(0.2)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style with scaling effect on press
struct SecondaryButton: ButtonStyle {
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var cornerRadius: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
