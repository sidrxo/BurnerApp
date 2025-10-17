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
            SettingsHeaderSection(title: "Payment Methods")
                .padding(.horizontal, 16)
                .padding(.top, 20)
            
            Text("No payment methods")
                .appBody()
                .foregroundColor(.gray)
            Spacer()
        }
        .background(Color.black)
    }
}
