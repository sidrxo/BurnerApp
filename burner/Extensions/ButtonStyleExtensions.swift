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

    /// Large action button style - used for prominent actions like buy ticket
    /// Full width with larger padding
    func largeActionButtonStyle(
        backgroundColor: Color = .white,
        foregroundColor: Color = .black,
        height: CGFloat = 50,
        cornerRadius: CGFloat = 25
    ) -> some View {
        self
            .foregroundColor(foregroundColor) // ✅ Fix here
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Circular button style - used for round icon buttons
    func circularButtonStyle(
        size: CGFloat = 44,
        backgroundColor: Color = Color.gray.opacity(0.2)
    ) -> some View {
        self
            .frame(width: size, height: size)
            .background(backgroundColor)
            .clipShape(Circle())
    }

    /// Destructive button style - used for delete/dangerous actions
    /// Full width with red foreground, transparent background
    func destructiveButtonStyle(
        foregroundColor: Color = .red,
        borderColor: Color = Color.red.opacity(0.3)
    ) -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.3))
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    /// Link button style - used for text-only buttons that look like links
    func linkButtonStyle(
        foregroundColor: Color = .blue
    ) -> some View {
        self
            .foregroundColor(foregroundColor)
            .underline()
    }

    /// Pill button style - used for tag/filter buttons
    func pillButtonStyle(
        backgroundColor: Color = Color.gray.opacity(0.2),
        foregroundColor: Color = .white,
        isSelected: Bool = false
    ) -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white : backgroundColor)
            .foregroundColor(isSelected ? .black : foregroundColor)
            .clipShape(Capsule())
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

/// Large action button style with scaling effect on press
struct LargeActionButton: ButtonStyle {
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var height: CGFloat = 50
    var cornerRadius: CGFloat = 25

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Destructive button style with scaling effect on press
struct DestructiveButton: ButtonStyle {
    var foregroundColor: Color = .red
    var borderColor: Color = Color.red.opacity(0.3)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Icon button style with scaling effect on press
struct IconButton: ButtonStyle {
    var size: CGFloat = 50
    var backgroundColor: Color = Color.white.opacity(0.1)
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
