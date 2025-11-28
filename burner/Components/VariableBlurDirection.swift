//
//  VariableBlurDirection.swift
//  burner
//
//  Created by Sid Rao on 16/11/2025.
//

import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins
import QuartzCore

public enum VariableBlurDirection {
    case blurredTopClearBottom
    case blurredBottomClearTop
}

public struct VariableBlurView: UIViewRepresentable {
    
    public var maxBlurRadius: CGFloat
    public var direction: VariableBlurDirection
    /// For `.blurredBottomClearTop`:
    ///   startOffset = 0.7  -> bottom (1 - 0.7) = 30% is blurred, top 70% clear.
    /// For `.blurredTopClearBottom` it's mirrored.
    public var startOffset: CGFloat
    
    public init(
        maxBlurRadius: CGFloat = 20,
        direction: VariableBlurDirection = .blurredTopClearBottom,
        startOffset: CGFloat = 0
    ) {
        self.maxBlurRadius = maxBlurRadius
        self.direction = direction
        self.startOffset = startOffset
    }
    
    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(
            maxBlurRadius: maxBlurRadius,
            direction: direction,
            startOffset: startOffset
        )
    }

    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
        // If you later want dynamic updates, you can add an update API on VariableBlurUIView.
    }
}

/// credit https://github.com/jtrivedi/VariableBlurView
open class VariableBlurUIView: UIVisualEffectView {

    public init(
        maxBlurRadius: CGFloat = 20,
        direction: VariableBlurDirection = .blurredTopClearBottom,
        startOffset: CGFloat = 0
    ) {
        super.init(effect: UIBlurEffect(style: .regular))

        let clsName = String("retliFAC".reversed()) // "CAFilter"
        guard let Cls = NSClassFromString(clsName) as? NSObject.Type else {
            return
        }
        let selName = String(":epyThtiWretlif".reversed()) // "filterWithType:"
        guard let variableBlur = Cls.self
            .perform(NSSelectorFromString(selName), with: "variableBlur")
            .takeUnretainedValue() as? NSObject else {
            return
        }

        // Mask decides blur radius: alpha 1 → maxBlurRadius, alpha 0 → no blur.
        let gradientImage = makeGradientImage(
            width: 200,
            height: 400,
            startOffset: startOffset,
            direction: direction
        )

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(gradientImage, forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        // Use CABackdropLayer from UIVisualEffectView to apply the filter to content underneath.
        let backdropLayer = subviews.first?.layer
        backdropLayer?.filters = [variableBlur]
        
        // Remove extra dimming/tint views so there’s no hard overlay.
        for subview in subviews.dropFirst() {
            subview.alpha = 0
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToWindow() {
        // fixes visible pixelization at unblurred edge (https://github.com/nikstar/VariableBlur/issues/1)
        guard let window, let backdropLayer = subviews.first?.layer else { return }
        backdropLayer.setValue(window.traitCollection.displayScale, forKey: "scale")
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // `super.traitCollectionDidChange(previousTraitCollection)` crashes the app
    }
    
    /// Creates a blur mask where only the bottom `(1 - startOffset)` or top `(1 - startOffset)` is blurred,
    /// with a gentle ramp using smoothLinearGradient + gamma easing.
    private func makeGradientImage(
        width: CGFloat = 100,
        height: CGFloat = 100,
        startOffset: CGFloat,
        direction: VariableBlurDirection
    ) -> CGImage {
        let gradient = CIFilter.smoothLinearGradient()
        gradient.color0 = CIColor.black   // full blur
        gradient.color1 = CIColor.clear   // no blur

        // Clamp startOffset to [0, 1]. For bottom blur: 0.7 => bottom 30% blurred.
        let clampedOffset = max(0.0, min(1.0, startOffset))
        let blurFraction = max(0.0, min(1.0, 1.0 - clampedOffset)) // portion of height that will be blurred

        let blurHeight = height * blurFraction

        switch direction {
        case .blurredBottomClearTop:
            // Bottom blurred: black at y = 0, clear at y = blurHeight
            gradient.point0 = CGPoint(x: 0, y: 0)
            gradient.point1 = CGPoint(x: 0, y: blurHeight)

        case .blurredTopClearBottom:
            // Top blurred: black at y = height, clear at y = height - blurHeight
            gradient.point0 = CGPoint(x: 0, y: height)
            gradient.point1 = CGPoint(x: 0, y: height - blurHeight)
        }

        let context = CIContext()
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        guard let baseImage = gradient.outputImage else {
            fatalError("[VariableBlur] Failed to create gradient output image")
        }

        // Apply gamma to make the transition softer (non-linear falloff).
        let gamma = CIFilter.gammaAdjust()
        gamma.inputImage = baseImage
        gamma.power = 2.2   // tweak 1.6–3.0 for different softness

        guard let easedImage = gamma.outputImage,
              let cgImage = context.createCGImage(easedImage, from: rect) else {
            fatalError("[VariableBlur] Failed to create CGImage for gradient mask")
        }

        return cgImage
    }
}
