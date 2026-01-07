//
//  VariableBlurDirection.swift
//  burner
//
//  Created by Sid Rao on 16/11/2025.
//

import SwiftUI
import UIKit

public enum VariableBlurDirection {
    case blurredTopClearBottom
    case blurredBottomClearTop
}

public struct VariableBlurView: UIViewRepresentable {
    
    public var maxBlurRadius: CGFloat
    public var direction: VariableBlurDirection
    
    public init(
        maxBlurRadius: CGFloat = 20,
        direction: VariableBlurDirection = .blurredBottomClearTop
    ) {
        self.maxBlurRadius = maxBlurRadius
        self.direction = direction
    }
    
    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(
            maxBlurRadius: maxBlurRadius,
            direction: direction
        )
    }

    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
        uiView.update(
            maxBlurRadius: maxBlurRadius,
            direction: direction
        )
    }
}

open class VariableBlurUIView: UIVisualEffectView {
    
    private let gradientMaskLayer = CAGradientLayer()
    
    public init(
        maxBlurRadius: CGFloat = 20,
        direction: VariableBlurDirection = .blurredBottomClearTop
    ) {
        // Use .dark for a heavier, contrasty look
        super.init(effect: UIBlurEffect(style: .dark))
        
        self.layer.mask = gradientMaskLayer
        
        update(maxBlurRadius: maxBlurRadius, direction: direction)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientMaskLayer.frame = bounds
    }
    
    public func update(
        maxBlurRadius: CGFloat,
        direction: VariableBlurDirection
    ) {
        // Configure the Gradient Mask with a custom curve
        let stops = makeEasingStops(direction: direction)
        
        gradientMaskLayer.colors = stops.map { $0.color }
        gradientMaskLayer.locations = stops.map { $0.location }
        
        gradientMaskLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientMaskLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
    
    /// Creates a custom "S-Curve" gradient
    private func makeEasingStops(
        direction: VariableBlurDirection
    ) -> [(color: CGColor, location: NSNumber)] {
        
        let clear = UIColor.clear.cgColor
        let opaque = UIColor.black.cgColor // In a mask, black = visible blur
        
        switch direction {
        case .blurredBottomClearTop:
            // EDITED: Adjusted stops to make the blur start higher up.
            // It now starts transitioning at 25% down instead of 40%.
            return [
                (clear, 0.0),                       // Top: Clear
                (clear, 0.25),                      // 25% down: Start transition (was 0.4)
                (opaque.copy(alpha: 0.15)!, 0.4),   // 40%: Noticeable start
                (opaque.copy(alpha: 0.5)!, 0.6),    // 60%: Significant blur
                (opaque.copy(alpha: 0.85)!, 0.85),  // 85%: Heavy blur
                (opaque, 1.0)                       // Bottom: Full blur
            ]
            
        case .blurredTopClearBottom:
            // Mirrored logic (not strictly necessary for this specific card design but good practice)
            return [
                (opaque, 0.0),
                (opaque.copy(alpha: 0.85)!, 0.15),
                (opaque.copy(alpha: 0.5)!, 0.4),
                (opaque.copy(alpha: 0.15)!, 0.6),
                (clear, 0.75),
                (clear, 1.0)
            ]
        }
    }
}
