
import Foundation
import SwiftUI

public struct ExpandableText: View {

    @State private var isExpanded: Bool = false
    @State private var isTruncated: Bool = false

    @State private var intrinsicSize: CGSize = .zero
    @State private var truncatedSize: CGSize = .zero
    @State private var moreTextSize: CGSize = .zero
    
    private let text: String
    private let lineLimit: Int = 3
    private let moreButtonText: String = "show more"
    private let expandAnimation: Animation = .default
    private let trimMultipleNewlinesWhenTruncated: Bool = true
    
    public init(_ text: String) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var body: some View {
        content
            .lineLimit(isExpanded ? nil : lineLimit)
            .applyingTruncationMask(size: moreTextSize, enabled: shouldShowMoreButton)
            .readSize { size in
                truncatedSize = size
                isTruncated = truncatedSize != intrinsicSize
            }
            .background(
                content
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .readSize { size in
                        intrinsicSize = size
                        isTruncated = truncatedSize != intrinsicSize
                    }
            )
            .background(
                Text(moreButtonText)
                    .font(.appBody)
                    .hidden()
                    .readSize { moreTextSize = $0 }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if shouldShowMoreButton {
                    withAnimation(expandAnimation) { isExpanded.toggle() }
                }
            }
            .modifier(OverlayAdapter(alignment: .trailingLastTextBaseline, view: {
                if shouldShowMoreButton {
                    Button {
                        withAnimation(expandAnimation) { isExpanded.toggle() }
                    } label: {
                        Text(moreButtonText)
                            .font(.appBody)
                            .foregroundColor(.white)
                    }
                }
            }))
    }
    
    private var content: some View {
        Text(.init(
            trimMultipleNewlinesWhenTruncated
                ? (shouldShowMoreButton ? textTrimmingDoubleNewlines : text)
                : text
        ))
        .font(.appBody)
        .foregroundColor(.gray)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shouldShowMoreButton: Bool {
        !isExpanded && isTruncated
    }
    
    private var textTrimmingDoubleNewlines: String {
        text.replacingOccurrences(of: #"\n\s*\n"#, with: "\n", options: .regularExpression)
    }
}

// MARK: - Supporting Views and Utilities

// OverlayAdapter
internal struct OverlayAdapter<V: View>: ViewModifier {
    let alignment: Alignment
    let view: () -> V
    
    init(alignment: Alignment, @ViewBuilder view: @escaping () -> V) {
        self.alignment = alignment
        self.view = view
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            content.overlay(alignment: alignment, content: view)
        } else {
            content.overlay(view(), alignment: alignment)
        }
    }
}

// TruncationTextMask
private struct TruncationTextMask: ViewModifier {

    let size: CGSize
    let enabled: Bool
    
    @Environment(\.layoutDirection) private var layoutDirection

    func body(content: Content) -> some View {
        if enabled {
            content
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                        HStack(spacing: 0) {
                            Rectangle()
                            HStack(spacing: 0) {
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        Gradient.Stop(color: .black, location: 0),
                                        Gradient.Stop(color: .clear, location: 0.9)
                                    ]),
                                    startPoint: layoutDirection == .rightToLeft ? .trailing : .leading,
                                    endPoint: layoutDirection == .rightToLeft ? .leading : .trailing
                                )
                                .frame(width: size.width, height: size.height)

                                Rectangle()
                                    .foregroundColor(.clear)
                                    .frame(width: size.width)
                            }
                        }.frame(height: size.height)
                    }
                )
        } else {
            content
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

internal extension View {
    func applyingTruncationMask(size: CGSize, enabled: Bool) -> some View {
        modifier(TruncationTextMask(size: size, enabled: enabled))
    }
}

// ViewSizeReader
private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

internal extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}
