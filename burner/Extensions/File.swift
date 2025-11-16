//
//  File.swift
//  burner
//
//  Created by Sid Rao on 16/11/2025.
//

import SwiftUI


// MARK: - View Extension for Safe Conditional Modifiers
extension View {
    /// Applies a transform if the optional value is not nil
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    /// Applies a transform if the condition is met
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
