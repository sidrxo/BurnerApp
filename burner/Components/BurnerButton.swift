import SwiftUI

/// Reusable button styles for the Burner app
/// Primary: White background with black text
/// Secondary: Black background with white outline and white text

struct BurnerButtonStyle: ViewModifier {
    enum Style {
        case primary    // White background, black text
        case secondary  // Outlined, white text
    }

    let style: Style
    let maxWidth: CGFloat?

    func body(content: Content) -> some View {
        content
            .appBody() // Monospaced for buttons
            .foregroundColor(style == .primary ? .black : .white)
            .frame(maxWidth: maxWidth)
            .padding(.vertical, 12)
            .background(
                style == .primary
                    ? Color.white
                    : Color.gray.opacity(0.1)
            )
            .clipShape(Capsule())
            .overlay(
                style == .secondary
                    ? Capsule().stroke(Color.white, lineWidth: 1)
                    : nil
            )
    }
}

extension View {
    func burnerButtonStyle(_ style: BurnerButtonStyle.Style = .primary, maxWidth: CGFloat? = nil) -> some View {
        self.modifier(BurnerButtonStyle(style: style, maxWidth: maxWidth))
    }
}

/// Convenience button component
struct BurnerButton: View {
    let title: String
    let style: BurnerButtonStyle.Style
    let maxWidth: CGFloat?
    let action: () -> Void

    init(
        _ title: String,
        style: BurnerButtonStyle.Style = .primary,
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
                .burnerButtonStyle(style, maxWidth: maxWidth)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            BurnerButton("LOG IN / REGISTER", style: .primary, maxWidth: 200) {
            }

            BurnerButton("EXPLORE", style: .secondary, maxWidth: 200) {
            }

            Text("CONTINUE WITH EMAIL")
                .burnerButtonStyle(.secondary, maxWidth: 200)
        }
        .padding()
    }
}
