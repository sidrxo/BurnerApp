//
//  FavoritesView.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//


import SwiftUI

struct FavoritesView: View {
    var body: some View {
        VStack {
            Text("No favorites yet")
                .appFont(size: 16)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.top, 40)
        .background(Color.black)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.large)
    }
}