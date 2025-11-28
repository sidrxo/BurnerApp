//
//  FilterButton.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//

import SwiftUI

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, design: .monospaced))
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white : Color.gray.opacity(0.1))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
