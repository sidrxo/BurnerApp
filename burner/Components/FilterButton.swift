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
                    .appFont(size: 14, weight: .semibold)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .appFont(size: 12, weight: .bold)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .clipShape(Capsule())
        }
    }
}
