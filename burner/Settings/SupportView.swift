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
            SettingsHeaderSection(title: "Support")
                .padding(.top, 20)
            MenuSection(title: "HELP") {
                Button(action: { openURL("mailto:support@burner.app") }) {
                    MenuItemContent(title: "Contact Support", subtitle: "Get help with your account")
                }
                NavigationLink(destination: FAQView()) {
                    MenuItemContent(title: "FAQ", subtitle: "Frequently asked questions")
                }
            }
            MenuSection(title: "LEGAL") {
                NavigationLink(destination: TermsOfServiceView()) {
                    MenuItemContent(title: "Terms of Service", subtitle: "Legal terms and conditions")
                }
                NavigationLink(destination: PrivacyPolicyView()) {
                    MenuItemContent(title: "Privacy Policy", subtitle: "How we protect your data")
                }
            }
            MenuSection(title: "APP") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version")
.appBody()                            .foregroundColor(.white)
                        Text("1.0.0")
                            .appSecondary()
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Button(action: { rateApp() }) {
                    MenuItemContent(title: "Rate the App", subtitle: "Share your feedback")
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color.black)

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
