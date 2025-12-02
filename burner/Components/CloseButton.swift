//
//  CloseButton.swift
//  burner
//
//  Created by Sid Rao on 17/10/2025.
//

import SwiftUI

struct CloseButton: View {
    let action: () -> Void
    let isDark: Bool

    init(action: @escaping () -> Void, isDark: Bool = false) {
        self.action = action
        self.isDark = isDark
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.appIcon)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(isDark ? Color.black.opacity(0.7) : Color.white.opacity(0.2))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
