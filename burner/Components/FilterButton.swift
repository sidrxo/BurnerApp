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
                    .appSecondary()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.appCaption)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(red: 33/255, green: 33/255, blue: 35/255))
            .clipShape(Capsule())
        }
    }
}
