//
//  PrivacyPolicyView.swift
//  burner
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderSection(title: "Privacy Policy", includeTopPadding: false, includeHorizontalPadding: false)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 20) {
                    privacySection(
                        title: "1. Information We Collect",
                        content: """
                        We collect information you provide directly to us, including:
                        • Account information (name, email address, password)
                        • Payment information (processed securely through third-party payment processors)
                        • Ticket purchase history and preferences
                        • Device information and usage data
                        • Location data (with your permission) for venue-specific features
                        """
                    )

                    privacySection(
                        title: "2. How We Use Your Information",
                        content: """
                        We use the information we collect to:
                        • Process ticket purchases and manage your account
                        • Send you confirmations, updates, and support messages
                        • Personalize your experience and provide recommendations
                        • Improve our services and develop new features
                        • Detect and prevent fraud and abuse
                        • Comply with legal obligations
                        """
                    )

                    privacySection(
                        title: "3. Information Sharing",
                        content: """
                        We do not sell your personal information. We may share your information with:
                        • Event organizers and venues for ticket validation
                        • Payment processors for transaction processing
                        • Service providers who assist in operating our platform
                        • Law enforcement when required by law or to protect our rights
                        """
                    )

                    privacySection(
                        title: "4. Data Security",
                        content: """
                        We implement industry-standard security measures to protect your personal information, including:
                        • Encryption of sensitive data in transit and at rest
                        • Secure authentication protocols
                        • Regular security audits and updates
                        • Access controls and monitoring systems
                        However, no method of transmission over the internet is 100% secure.
                        """
                    )

                    privacySection(
                        title: "5. Your Rights and Choices",
                        content: """
                        You have the right to:
                        • Access, update, or delete your personal information
                        • Opt out of marketing communications
                        • Request a copy of your data
                        • Withdraw consent for data processing (where applicable)
                        • Lodge a complaint with a data protection authority
                        """
                    )

                    privacySection(
                        title: "6. Cookies and Tracking",
                        content: """
                        We use cookies and similar technologies to:
                        • Remember your preferences and settings
                        • Analyze usage patterns and improve our service
                        • Provide personalized content and recommendations
                        You can control cookies through your browser settings, though some features may not function properly without them.
                        """
                    )

                    privacySection(
                        title: "7. Children's Privacy",
                        content: """
                        Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.
                        """
                    )

                    privacySection(
                        title: "8. Third-Party Services",
                        content: """
                        Our app may contain links to third-party websites and services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any personal information.
                        """
                    )

                    privacySection(
                        title: "9. Data Retention",
                        content: """
                        We retain your personal information for as long as necessary to provide our services and comply with legal obligations. Deleted account data may be retained in backup systems for a limited period but will not be accessible.
                        """
                    )

                    privacySection(
                        title: "10. International Data Transfers",
                        content: """
                        Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with applicable data protection laws.
                        """
                    )

                    privacySection(
                        title: "11. Changes to This Policy",
                        content: """
                        We may update this Privacy Policy from time to time. We will notify you of significant changes by email or through the app. Your continued use of the service after changes indicates acceptance of the updated policy.
                        """
                    )

                    privacySection(
                        title: "12. Contact Us",
                        content: """
                        If you have questions about this Privacy Policy or our data practices, please contact us at:
                        Email: privacy@burner.app
                        Address: Burner App Ltd, United Kingdom

                        Last updated: October 2025
                        """
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func privacySection(title: String, content: String) -> some View {
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
    PrivacyPolicyView()
        .preferredColorScheme(.dark)
}
