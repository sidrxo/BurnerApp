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
    let alignment: HorizontalAlignment

    init(
        _ lines: [String],
        fontSize: CGFloat = 48,
        fontWeight: Font.Weight = .bold,
        color: Color = .white,
        kerning: CGFloat = -1.5,
        lineSpacing: CGFloat = -15,
        alignment: HorizontalAlignment = .leading
    ) {
        self.lines = lines
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.color = color
        self.kerning = kerning
        self.lineSpacing = lineSpacing
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .appFont(size: fontSize, weight: fontWeight)
                    .kerning(kerning)
                    .foregroundColor(color)
                    .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .center)
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
        lineSpacing: CGFloat = -15,
        alignment: HorizontalAlignment = .leading
    ) {
        self.init(
            [line1, line2],
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            kerning: kerning,
            lineSpacing: lineSpacing,
            alignment: alignment
        )
    }
}

