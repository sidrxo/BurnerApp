import SwiftUI

/// A reusable header component with tight line spacing and negative kerning
/// Used for large, impactful headers in onboarding and other flows
struct TightHeaderText: View {
    let lines: [String]
    let fontSize: CGFloat
    let fontWeight: Font.Weight
    let color: Color
    let kerning: CGFloat
    let lineSpacing: CGFloat

    init(
        _ lines: [String],
        fontSize: CGFloat = 48,
        fontWeight: Font.Weight = .bold,
        color: Color = .white,
        kerning: CGFloat = -1.5,
        lineSpacing: CGFloat = -15
    ) {
        self.lines = lines
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.kerning = kerning
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: fontSize, weight: fontWeight, design: .default))
                    .kerning(kerning)
                    .foregroundColor(color)
                    .padding(.bottom, index < lines.count - 1 ? lineSpacing : 0)
            }
        }
    }
}

// Convenience initializer for two-line headers
extension TightHeaderText {
    init(
        _ line1: String,
        _ line2: String,
        fontSize: CGFloat = 48,
        fontWeight: Font.Weight = .bold,
        color: Color = .white,
        kerning: CGFloat = -1.5,
        lineSpacing: CGFloat = -15
    ) {
        self.init(
            [line1, line2],
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            kerning: kerning,
            lineSpacing: lineSpacing
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 40) {
            TightHeaderText("WHERE WILL", "YOU GO?")
            TightHeaderText(
                ["WELCOME TO", "BURNER"],
                fontSize: 40,
                color: .white
            )
        }
    }
}
