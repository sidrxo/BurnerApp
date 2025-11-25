//
//  HeaderSection.swift
//  burner
//
//  Created by Sid Rao on 23/09/2025.
//


import SwiftUI

// MARK: - Header Section Component
struct HeaderSection: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .appPageHeader()
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
        .padding(.bottom, 30)
    }
}
