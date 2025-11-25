import SwiftUI

// MARK: - Reusable Primary Button Component
struct PrimaryButton: View {
    enum Style {
        case filled       // White background, black text
        case outlined     // Transparent background, white text with border
        case secondary    // Gray transparent background, white text
    }

    let title: String
    let style: Style
    let action: () -> Void
    var isDisabled: Bool = false
    var isLoading: Bool = false
    var icon: String? = nil
    var fullWidth: Bool = true

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.appIcon)
                    }

                    Text(title)
                        .appSecondary()
                }
            }
            .foregroundColor(textColor)
            .frame(height: 50)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 20)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(isDisabled || isLoading)
        .buttonStyle(PlainButtonStyle())
    }

    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        }

        switch style {
        case .filled:
            return Color.white
        case .outlined:
            return Color.clear
        case .secondary:
            return Color.gray.opacity(0.3)
        }
    }

    private var textColor: Color {
        if isDisabled {
            return Color.gray
        }

        switch style {
        case .filled:
            return Color.black
        case .outlined, .secondary:
            return Color.white
        }
    }

    private var borderColor: Color {
        switch style {
        case .filled:
            return Color.clear
        case .outlined:
            return Color.white.opacity(0.2)
        case .secondary:
            return Color.white.opacity(0.2)
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .filled:
            return 0
        case .outlined, .secondary:
            return 1
        }
    }
}

// MARK: - Modal Action Button (for modals like SetLocationModal)
struct ModalActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var isDisabled: Bool = false
    var showChevron: Bool = true

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .appCard()
                Text(title)
                    .appBody()
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .appSecondary()
                        .foregroundColor(.gray)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct PrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButton(title: "LOG IN / SIGN UP", style: .filled, action: {})
            PrimaryButton(title: "EXPLORE", style: .secondary, action: {})
            PrimaryButton(title: "CONTINUE", style: .outlined, action: {})
            PrimaryButton(title: "Loading...", style: .filled, action: {}, isLoading: true)
            PrimaryButton(title: "Disabled", style: .filled, action: {}, isDisabled: true)

            ModalActionButton(title: "Use Current Location", icon: "location.fill", action: {})
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
