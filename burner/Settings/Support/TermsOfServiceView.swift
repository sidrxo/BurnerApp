//
//  TermsOfServiceView.swift
//  burner
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderSection(title: "Terms of Service", includeTopPadding: false, includeHorizontalPadding: false)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 20) {
                    termsSection(
                        title: "1. Acceptance of Terms",
                        content: """
                        By accessing and using the Burner app, you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to these terms, please do not use our service.
                        """
                    )

                    termsSection(
                        title: "2. Use of Service",
                        content: """
                        Burner provides a platform for purchasing and managing event tickets. You agree to use the service only for lawful purposes and in accordance with these terms. You are responsible for maintaining the confidentiality of your account credentials.
                        """
                    )

                    termsSection(
                        title: "3. Ticket Purchases",
                        content: """
                        All ticket purchases are final and non-refundable unless the event is cancelled. Tickets are valid only for the specified event and cannot be transferred or resold without prior authorization. You agree to comply with all venue rules and regulations.
                        """
                    )

                    termsSection(
                        title: "4. Payment",
                        content: """
                        You agree to provide current, complete, and accurate payment information. We use secure third-party payment processors to handle all transactions. You are responsible for all charges incurred under your account.
                        """
                    )

                    termsSection(
                        title: "5. User Content",
                        content: """
                        By using our service, you may provide personal information and preferences. You retain all rights to your content, but grant us a license to use, display, and process this information to provide our services.
                        """
                    )

                    termsSection(
                        title: "6. Prohibited Activities",
                        content: """
                        You may not use the service to: violate any laws, infringe intellectual property rights, transmit malicious code, attempt unauthorized access, or engage in fraudulent activities. Violation of these terms may result in account termination.
                        """
                    )

                    termsSection(
                        title: "7. Limitation of Liability",
                        content: """
                        Burner is not liable for any indirect, incidental, special, or consequential damages arising from your use of the service. We do not guarantee uninterrupted or error-free service and are not responsible for event cancellations or changes.
                        """
                    )

                    termsSection(
                        title: "8. Privacy",
                        content: """
                        Your use of the service is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding the collection and use of your personal information.
                        """
                    )

                    termsSection(
                        title: "9. Modifications",
                        content: """
                        We reserve the right to modify these terms at any time. We will notify users of significant changes via email or app notification. Continued use of the service after changes constitutes acceptance of the modified terms.
                        """
                    )

                    termsSection(
                        title: "10. Termination",
                        content: """
                        We may terminate or suspend your account at any time for violations of these terms. Upon termination, your right to use the service will immediately cease, but your obligations and our liability limitations will survive.
                        """
                    )

                    termsSection(
                        title: "11. Governing Law",
                        content: """
                        These terms shall be governed by and construed in accordance with the laws of the United Kingdom. Any disputes arising from these terms or the service will be resolved in the courts of the United Kingdom.
                        """
                    )

                    termsSection(
                        title: "12. Contact Information",
                        content: """
                        If you have any questions about these Terms of Service, please contact us at support@burner.app.
                        """
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func termsSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .appBody()
                .foregroundColor(.white)
                .fontWeight(.semibold)

            Text(content)
                .appSecondary()
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
    }
}

#Preview {
    TermsOfServiceView()
        .preferredColorScheme(.dark)
}
