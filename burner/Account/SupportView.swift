//
//  SupportView.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//


import SwiftUI

struct SupportView: View {
    var body: some View {
        VStack(spacing: 0) {
            CustomMenuSection(title: "HELP") {
                Button(action: { openURL("mailto:support@burner.app") }) {
                    CustomMenuItemContent(title: "Contact Support", subtitle: "Get help with your account")
                }
                Button(action: {}) {
                    CustomMenuItemContent(title: "FAQ", subtitle: "Frequently asked questions")
                }
            }
            CustomMenuSection(title: "LEGAL") {
                Button(action: { openURL("https://burner.app/terms") }) {
                    CustomMenuItemContent(title: "Terms of Service", subtitle: "Legal terms and conditions")
                }
                Button(action: { openURL("https://burner.app/privacy") }) {
                    CustomMenuItemContent(title: "Privacy Policy", subtitle: "How we protect your data")
                }
            }
            CustomMenuSection(title: "APP") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version")
                            .appFont(size: 16, weight: .medium)
                            .foregroundColor(.white)
                        Text("1.0.0")
                            .appFont(size: 14)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Button(action: { rateApp() }) {
                    CustomMenuItemContent(title: "Rate the App", subtitle: "Share your feedback")
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(Color.black)
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func rateApp() {
        guard let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
}