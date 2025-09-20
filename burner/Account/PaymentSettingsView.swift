//
//  PaymentSettingsView.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//


import SwiftUI

struct PaymentSettingsView: View {
    var body: some View {
        VStack {
            Text("No payment methods")
                .appFont(size: 16)
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.top, 40)
        .background(Color.black)
        .navigationTitle("Payment")
        .navigationBarTitleDisplayMode(.large)
    }
}