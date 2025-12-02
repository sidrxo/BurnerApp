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
    let includeTopPadding: Bool
    let includeHorizontalPadding: Bool

    init(title: String, includeTopPadding: Bool = true, includeHorizontalPadding: Bool = true) {
        self.title = title
        self.includeTopPadding = includeTopPadding
        self.includeHorizontalPadding = includeHorizontalPadding
    }

    var body: some View {
        HStack {
            Text(title)
                .appPageHeader()
                .foregroundColor(.white)
            Spacer()
        }
        .if(includeHorizontalPadding) { view in
            view.padding(.horizontal, 10)
        }
        .if(includeTopPadding) { view in
            view.padding(.top, 14)
        }
        .padding(.bottom, 30)
    }
}
