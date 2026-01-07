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
                    Text("Effective Date: December 23, 2025")
                        .appSecondary()
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)

                    termsSection(
                        title: "1. Acceptance of Terms",
                        content: """
                        1.1 Agreement to Terms
                        By creating an account, accessing, or using the Burner mobile application (the "App"), you agree to be bound by these Terms of Service ("Terms"). These Terms constitute a legally binding agreement between you and Burner App Ltd ("Burner", "we", "us", or "our").

                        1.2 Eligibility
                        You must be at least 13 years old to use the App. By using the App, you represent and warrant that you meet this age requirement and have the legal capacity to enter into this agreement.

                        1.3 Modifications
                        We reserve the right to update these Terms at any time. If you do not agree to these Terms or any future modifications, you must immediately cease using the App and delete your account.
                        """
                    )

                    termsSection(
                        title: "2. Service Description",
                        content: """
                        2.1 Platform Overview
                        Burner is an event ticketing platform that allows users to:
                        • Discover and browse upcoming events near their location
                        • Purchase digital tickets for events using secure payment methods
                        • Manage purchased tickets and access QR codes for venue entry
                        • Bookmark events for future consideration
                        • Use optional parental control features (Burner Mode) to limit distractions during events

                        2.2 Service Availability
                        The App is currently available on iOS and Android devices. We do not guarantee uninterrupted or error-free service and reserve the right to modify, suspend, or discontinue features at any time without prior notice.

                        2.3 Geographic Limitations
                        Certain features, such as event discovery and location-based recommendations, are only available in supported regions. Events are displayed within 31 miles (50km) of your current location.
                        """
                    )

                    termsSection(
                        title: "3. Account Registration and Security",
                        content: """
                        3.1 Account Creation
                        To purchase tickets, you must create an account by providing:
                        • A valid email address
                        • A secure password (encrypted and stored securely)
                        • Optional: Google Sign-In for authentication

                        3.2 Account Security
                        You are solely responsible for:
                        • Maintaining the confidentiality of your login credentials
                        • All activities that occur under your account
                        • Notifying us immediately of any unauthorized access or security breaches

                        3.3 Account Accuracy
                        You agree to provide accurate, current, and complete information and to update this information promptly if it changes. Providing false information may result in account termination.

                        3.4 Account Termination
                        You may delete your account at any time through Settings > Account Details > Delete Account. Account deletion is permanent and cannot be reversed. Active tickets may be forfeited upon account deletion.
                        """
                    )

                    termsSection(
                        title: "4. Ticket Purchases and Payment",
                        content: """
                        4.1 Ticket Sales
                        All ticket purchases are final and non-refundable except in the following circumstances:
                        • Event is cancelled by the organizer (full refund within 5-10 business days)
                        • Event is rescheduled and you cannot attend the new date (refund at organizer's discretion)
                        • Technical error results in duplicate purchases (refund of duplicate only)

                        4.2 Payment Methods
                        We accept the following payment methods:
                        • Apple Pay (iOS) / Google Pay (Android)
                        • Credit and debit cards: Visa, Mastercard, American Express
                        • All payments are processed securely through Stripe, a PCI-DSS compliant payment processor

                        4.3 Pricing and Fees
                        • All prices are displayed in the local currency (GBP, USD, EUR as applicable)
                        • Prices include applicable taxes unless otherwise stated
                        • Service fees, if any, are clearly displayed before purchase confirmation
                        • Prices are subject to change without notice, but confirmed purchases honor the price at time of transaction

                        4.4 Payment Authorization
                        By providing payment information, you:
                        • Authorize us to charge your payment method for the total purchase amount
                        • Represent that you are authorized to use the payment method
                        • Agree to pay all charges incurred, including taxes and fees
                        • Accept that payment card data is tokenized and stored securely by Stripe (not on our servers)

                        4.5 Failed Transactions
                        If a payment fails due to insufficient funds, expired card, or payment processor decline, the ticket will not be issued. You will be notified via email and in-app notification.
                        """
                    )

                    termsSection(
                        title: "5. Ticket Usage and Restrictions",
                        content: """
                        5.1 Ticket Validity
                        • Each ticket is valid only for the specific event, date, and time stated
                        • Tickets are non-transferable and cannot be resold without prior written authorization
                        • Each ticket is tied to the purchasing account and contains a unique QR code for entry
                        • You are limited to one ticket per event per account

                        5.2 Venue Entry
                        • Present your ticket QR code at the venue entrance for scanning
                        • Ensure your device is charged and the QR code is clearly visible
                        • If the QR code fails to scan, venue staff can manually verify your ticket number
                        • Venues reserve the right to refuse entry for policy violations, intoxication, or security concerns

                        5.3 Event Changes or Cancellations
                        • We are not responsible for event cancellations, postponements, or changes made by event organizers
                        • Refunds for cancelled events are processed automatically within 5-10 business days
                        • For rescheduled events, tickets remain valid for the new date unless a refund is offered
                        • You will be notified of significant event changes via email and push notification

                        5.4 Prohibited Ticket Activities
                        You may not:
                        • Share, transfer, or sell tickets to third parties
                        • Use automated systems (bots) to purchase tickets
                        • Purchase tickets for resale or commercial purposes
                        • Duplicate, counterfeit, or tamper with ticket QR codes
                        • Use tickets obtained through fraudulent means

                        Violation of these restrictions may result in ticket cancellation without refund and account termination.
                        """
                    )

                    termsSection(
                        title: "6. Burner Mode Feature (Parental Controls)",
                        content: """
                        6.1 Feature Description
                        Burner Mode is an optional iOS feature that uses the Screen Time API to block access to distracting apps during events you attend. This feature is designed to help you stay present and focused during live experiences.

                        6.2 How It Works
                        • You configure which apps to block in Settings > Burner Mode
                        • When your ticket is scanned at a venue, Burner Mode automatically activates
                        • Blocked apps become inaccessible for the duration of the event
                        • Burner Mode deactivates automatically when the event ends

                        6.3 Permissions and Privacy
                        • Burner Mode requires Screen Time API permission (granted in iOS Settings)
                        • App blocking data is stored locally on your device only
                        • We do not collect or transmit information about which apps you block
                        • You can disable Burner Mode at any time in Settings

                        6.4 Limitations and Disclaimers
                        • Burner Mode is only available on iOS 16.1 and later
                        • Emergency services (Phone, Messages, 911) are never blocked
                        • Determined users may bypass Burner Mode through device settings
                        • We are not liable for any consequences of using or disabling Burner Mode
                        • This feature is provided "as is" without warranties of effectiveness
                        """
                    )

                    termsSection(
                        title: "7. User Conduct and Prohibited Activities",
                        content: """
                        You agree NOT to:

                        7.1 Legal Violations
                        • Violate any local, national, or international laws or regulations
                        • Engage in fraudulent activities, identity theft, or financial crimes
                        • Use the App for money laundering or terrorist financing

                        7.2 Security and Access
                        • Attempt to gain unauthorized access to our systems, servers, or databases
                        • Reverse engineer, decompile, or disassemble the App
                        • Use automated scripts, bots, or crawlers to access the App
                        • Circumvent security measures or authentication systems

                        7.3 Harmful Activities
                        • Transmit viruses, malware, trojans, or other malicious code
                        • Conduct denial-of-service attacks or disrupt App functionality
                        • Interfere with other users' enjoyment of the service
                        • Harass, threaten, or abuse other users or our support staff

                        7.4 Intellectual Property
                        • Infringe on our or third parties' copyrights, trademarks, or intellectual property
                        • Copy, reproduce, or distribute App content without permission
                        • Use our branding, logos, or design elements without authorization

                        7.5 Misrepresentation
                        • Impersonate another person, organization, or event organizer
                        • Provide false or misleading information in your account
                        • Claim affiliation with Burner or event organizers without authorization

                        Violation of any of these prohibitions may result in immediate account termination, forfeiture of tickets without refund, and potential legal action.
                        """
                    )

                    termsSection(
                        title: "8. Intellectual Property Rights",
                        content: """
                        8.1 Our Intellectual Property
                        All content, features, and functionality of the App, including but not limited to:
                        • Text, graphics, logos, icons, images, and software
                        • User interface design and app architecture
                        • Trademarks: "Burner" name and logo
                        • Copyrighted materials and proprietary algorithms

                        are owned by Burner App Ltd and protected by copyright, trademark, and other intellectual property laws.

                        8.2 Limited License
                        We grant you a limited, non-exclusive, non-transferable, revocable license to:
                        • Access and use the App for personal, non-commercial purposes
                        • View and display tickets for events you have purchased
                        • Download the App on devices you own or control

                        This license does not grant you any ownership rights or permission to:
                        • Modify, copy, distribute, or create derivative works
                        • Use the App for commercial purposes without written authorization
                        • Extract or reuse any portions of the App's code or design

                        8.3 User-Generated Content
                        You retain ownership of any personal information or preferences you provide. By using the App, you grant us a worldwide, royalty-free license to use, display, and process this information solely to provide and improve our services.

                        8.4 Event Organizer Content
                        Event descriptions, images, and promotional materials are owned by the respective event organizers and are used with permission. We do not claim ownership of third-party content.
                        """
                    )

                    termsSection(
                        title: "9. Disclaimers and Warranties",
                        content: """
                        9.1 "AS IS" Service
                        THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:
                        • Merchantability, fitness for a particular purpose, or non-infringement
                        • Uninterrupted, timely, secure, or error-free service
                        • Accuracy or completeness of event information or ticket availability
                        • Compatibility with all devices or operating systems

                        9.2 Event Organizer Disclaimer
                        We act solely as a ticketing platform and intermediary. We are NOT:
                        • Responsible for event content, quality, or safety
                        • Liable for event cancellations, changes, or organizer misconduct
                        • Guarantors of event organizer performance or solvency

                        9.3 Third-Party Services
                        We rely on third-party services (Stripe, Supabase, Google Cloud) for critical functionality. We are not responsible for:
                        • Outages or failures of third-party services
                        • Security breaches at third-party providers
                        • Changes to third-party terms or pricing

                        9.4 User Responsibility
                        You are solely responsible for:
                        • Ensuring device compatibility and internet connectivity
                        • Backing up important data before using the App
                        • Reviewing event details and venue policies before purchase
                        • Your conduct at events and compliance with venue rules
                        """
                    )

                    termsSection(
                        title: "10. Limitation of Liability",
                        content: """
                        10.1 Damages Cap
                        TO THE MAXIMUM EXTENT PERMITTED BY LAW, BURNER APP LTD SHALL NOT BE LIABLE FOR:
                        • Indirect, incidental, special, consequential, or punitive damages
                        • Loss of profits, revenue, data, or business opportunities
                        • Service interruptions, errors, or data loss
                        • Unauthorized access to your account or payment information
                        • Events you missed due to App errors or ticket issues

                        10.2 Maximum Liability
                        Our total liability for any claim related to the App shall not exceed the greater of:
                        • £100 (GBP) or equivalent in your local currency
                        • The total amount you paid for tickets in the 12 months preceding the claim

                        10.3 Exceptions
                        Some jurisdictions do not allow limitations on implied warranties or liability for incidental/consequential damages. In such jurisdictions, our liability is limited to the maximum extent permitted by law.

                        10.4 User Indemnification
                        You agree to indemnify, defend, and hold harmless Burner App Ltd, its officers, directors, employees, and agents from any claims, losses, damages, or expenses (including legal fees) arising from:
                        • Your violation of these Terms
                        • Your use or misuse of the App
                        • Your violation of any third-party rights
                        • Your conduct at events or interactions with other users
                        """
                    )

                    termsSection(
                        title: "11. Privacy and Data Protection",
                        content: """
                        11.1 Privacy Policy Incorporation
                        Your use of the App is governed by our Privacy Policy, which is incorporated by reference into these Terms. Please review the Privacy Policy to understand how we collect, use, and protect your personal information.

                        11.2 Data Sharing
                        By using the App, you consent to:
                        • Sharing your name and ticket information with event organizers for entry verification
                        • Processing payments through Stripe (subject to Stripe's privacy policy)
                        • Using Supabase for backend database, authentication, and serverless functions
                        • Data hosting on Google Cloud Platform infrastructure (via Supabase)

                        11.3 Communications
                        By creating an account, you consent to receive:
                        • Transactional emails (purchase confirmations, event updates, refund notifications)
                        • Service announcements (app updates, policy changes, security alerts)
                        • Optional marketing communications (you may opt out at any time)

                        All communications are governed by our Privacy Policy and applicable data protection laws (GDPR, CCPA).
                        """
                    )

                    termsSection(
                        title: "12. Dispute Resolution and Governing Law",
                        content: """
                        12.1 Governing Law
                        These Terms shall be governed by and construed in accordance with the laws of England and Wales, without regard to conflict of law principles.

                        12.2 Jurisdiction
                        You agree that any legal action or proceeding arising out of or relating to these Terms or the App shall be brought exclusively in the courts of England and Wales. You consent to the personal jurisdiction of these courts.

                        12.3 Informal Resolution
                        Before initiating formal legal proceedings, you agree to contact us at support@burner.app to attempt informal resolution. We will respond within 14 business days and work in good faith to resolve the dispute.

                        12.4 Arbitration (Optional)
                        For disputes that cannot be resolved informally, parties may agree to binding arbitration under the rules of the London Court of International Arbitration (LCIA).

                        12.5 Class Action Waiver
                        You agree to resolve disputes individually and waive the right to participate in class action lawsuits or class-wide arbitration (to the extent permitted by law).

                        12.6 Time Limitation
                        Any claim related to these Terms or the App must be filed within one (1) year of the event giving rise to the claim, or it will be permanently barred.
                        """
                    )

                    termsSection(
                        title: "13. Termination and Suspension",
                        content: """
                        13.1 Termination by You
                        You may terminate your account at any time by:
                        • Going to Settings > Account Details > Delete Account
                        • Emailing support@burner.app with a deletion request
                        • Account deletion is permanent and cannot be undone

                        13.2 Termination by Us
                        We reserve the right to suspend or terminate your account immediately, without prior notice, for:
                        • Violation of these Terms or our policies
                        • Fraudulent activity, payment disputes, or chargebacks
                        • Abusive behavior toward other users or support staff
                        • Suspected security threats or unauthorized access
                        • Legal requirements or law enforcement requests

                        13.3 Effect of Termination
                        Upon termination:
                        • Your access to the App will be immediately revoked
                        • Active tickets may be forfeited without refund (at our discretion)
                        • Personal data will be deleted per our Privacy Policy (within 30 days)
                        • Transaction records may be retained for legal/accounting purposes (up to 7 years)

                        13.4 Survival
                        The following sections survive termination: Intellectual Property Rights, Disclaimers, Limitation of Liability, Indemnification, Governing Law, and Dispute Resolution.
                        """
                    )

                    termsSection(
                        title: "14. Miscellaneous Provisions",
                        content: """
                        14.1 Entire Agreement
                        These Terms, together with our Privacy Policy, constitute the entire agreement between you and Burner App Ltd regarding the App and supersede all prior agreements or understandings.

                        14.2 Severability
                        If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions will remain in full force and effect.

                        14.3 No Waiver
                        Our failure to enforce any right or provision of these Terms does not constitute a waiver of that right or provision.

                        14.4 Assignment
                        You may not assign or transfer these Terms or your account without our written consent. We may assign these Terms to any successor entity in the event of a merger, acquisition, or sale of assets.

                        14.5 Force Majeure
                        We are not liable for delays or failures in performance due to circumstances beyond our reasonable control, including natural disasters, wars, pandemics, or infrastructure failures.

                        14.6 Third-Party Beneficiaries
                        These Terms do not create any third-party beneficiary rights except as expressly stated.

                        14.7 Notices
                        All notices to you will be sent to the email address associated with your account. Notices to us should be sent to legal@burner.app.

                        14.8 Language
                        These Terms are written in English. Any translations are provided for convenience only, and the English version controls in case of conflict.
                        """
                    )

                    termsSection(
                        title: "15. Contact Information",
                        content: """
                        If you have questions, concerns, or legal inquiries regarding these Terms:

                        Burner App Ltd
                        United Kingdom

                        General Support: support@burner.app
                        Legal Inquiries: legal@burner.app
                        Privacy Questions: privacy@burner.app

                        For urgent matters, contact us through Settings > Help & Support in the App.

                        Last updated: December 23, 2025
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
                .appCard()
                .foregroundColor(.white)
                .fontWeight(.bold)

            Text(content)
                .appSecondary()
                .foregroundColor(.gray)
                .lineSpacing(6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TermsOfServiceView()
        .preferredColorScheme(.dark)
}
