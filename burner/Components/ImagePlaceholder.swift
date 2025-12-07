//
//  ImagePlaceholder.swift
//  burner
//
//  Shared image placeholder component
//

import SwiftUI

/// Reusable placeholder for missing/loading images
struct ImagePlaceholder: View {
    let size: CGFloat
    let cornerRadius: CGFloat
    let iconSize: CGFloat

    init(size: CGFloat = 60, cornerRadius: CGFloat = 8, iconSize: CGFloat = 16) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.iconSize = iconSize
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "music.note")
                    .appFont(size: iconSize)
                    .foregroundColor(.gray)
            )
    }
}
