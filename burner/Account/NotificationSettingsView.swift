//
//  NotificationSettingsView.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//


import SwiftUI

struct NotificationSettingsView: View {
    @State private var pushEnabled = true
    @State private var emailEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            CustomMenuSection(title: "NOTIFICATIONS") {
                HStack {
                    Text("Push Notifications")
                        .appFont(size: 16, weight: .medium)
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $pushEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                HStack {
                    Text("Email Notifications")
                        .appFont(size: 16, weight: .medium)
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $emailEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .white))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(Color.black)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}