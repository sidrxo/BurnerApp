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
                    Text("Effective Date: December 23, 2025")
                        .appSecondary()
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)

                    privacySection(
                        title: "1. Information We Collect",
                        content: """
                        1.1 Information You Provide
                        • Account Information: Name, email address, password (encrypted), and optional profile details
                        • Payment Information: Credit/debit card details, billing address, and transaction history (processed securely through Stripe)
                        • Purchase History: Tickets purchased, events attended, bookmarks, and preferences
                        • Communications: Support messages, feedback, and correspondence with us

                        1.2 Automatically Collected Information
                        • Device Information: Device type, operating system, unique device identifiers, mobile network information
                        • Usage Data: Features used, events viewed, search queries, time spent in app, crash reports
                        • Location Data: Approximate location (with your permission) to show nearby events within 31 miles (50km)
                        • Precise Location: Collected only during active app use for event discovery and venue navigation

                        1.3 Burner Mode Permissions (iOS Only)
                        • Screen Time API Access: If you enable Burner Mode parental controls, we request permission to block specified apps during events
                        • App Usage Data: Limited data on which apps are blocked (stored locally on your device only)
                        • This feature requires explicit permission and can be disabled at any time in Settings

                        1.4 Information from Third Parties
                        • Google Sign-In: Email address, name, and profile picture (if you choose to sign in with Google)
                        • Event Organizers: Venue check-in times and attendance verification for purchased tickets
                        """
                    )

                    privacySection(
                        title: "2. How We Use Your Information",
                        content: """
                        We use your information for the following purposes:

                        2.1 Service Delivery
                        • Process ticket purchases and generate unique QR codes for venue entry
                        • Manage your account and authenticate your identity
                        • Send purchase confirmations, ticket details, and event reminders
                        • Provide customer support and respond to your inquiries
                        • Enable Burner Mode app blocking when tickets are scanned at venues

                        2.2 Personalization and Recommendations
                        • Show events near your location based on GPS data
                        • Recommend events based on your purchase history and bookmarks
                        • Remember your preferences and settings across devices

                        2.3 Communication
                        • Send transactional emails (purchase confirmations, event updates, cancellations)
                        • Notify you of changes to our services or policies
                        • Respond to support requests and provide assistance
                        • Send marketing communications (only with your consent; you can opt out anytime)

                        2.4 Safety, Security, and Legal Compliance
                        • Detect and prevent fraud, unauthorized access, and abuse
                        • Verify ticket authenticity and prevent duplicate entry at venues
                        • Enforce our Terms of Service and protect our rights
                        • Comply with legal obligations, court orders, and regulatory requirements

                        2.5 Analytics and Improvement
                        • Analyze usage patterns to improve app performance and user experience
                        • Test new features and understand feature adoption
                        • Monitor app stability and fix bugs or crashes
                        """
                    )

                    privacySection(
                        title: "3. Information Sharing and Disclosure",
                        content: """
                        We do not sell, rent, or trade your personal information. We share information only in the following circumstances:

                        3.1 Service Providers and Business Partners
                        • Supabase: Backend infrastructure, PostgreSQL database, authentication, and edge functions
                        • Stripe: Payment processing and secure transaction handling
                        • Google Cloud Platform: Hosting and infrastructure (via Supabase)
                        • Kingfisher: Image caching library (local device storage, 7-day expiration, 300MB max)

                        All third-party providers are contractually obligated to protect your data and use it only for specified purposes.

                        3.2 Event Organizers and Venues
                        • Ticket validation data (name, ticket number, QR code verification status)
                        • Check-in times and attendance records for events you attend
                        • Limited contact information if required by venue security or event logistics

                        3.3 Legal Requirements
                        • Compliance with applicable laws, regulations, or legal processes
                        • Response to lawful requests from public authorities (law enforcement, courts)
                        • Protection of our rights, privacy, safety, or property
                        • Enforcement of our Terms of Service and investigation of violations

                        3.4 Business Transfers
                        In the event of a merger, acquisition, or sale of assets, your information may be transferred to the acquiring entity. We will notify you before your information becomes subject to a different privacy policy.

                        3.5 With Your Consent
                        We may share information with other third parties when you explicitly consent to such sharing.
                        """
                    )

                    privacySection(
                        title: "4. Data Security Measures",
                        content: """
                        We implement robust security measures to protect your personal information:

                        • End-to-End Encryption: All data transmitted between your device and our servers is encrypted using TLS 1.3
                        • Secure Storage: Personal data is encrypted at rest using industry-standard AES-256 encryption
                        • Payment Security: We are PCI-DSS compliant; payment card data is tokenized and never stored on our servers
                        • Authentication: Passwords are hashed using bcrypt; multi-factor authentication available
                        • Access Controls: Strict employee access policies with role-based permissions
                        • Regular Audits: Periodic security assessments, penetration testing, and vulnerability scanning
                        • Incident Response: 24/7 monitoring and rapid response protocols for security incidents

                        However, no method of electronic transmission or storage is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.
                        """
                    )

                    privacySection(
                        title: "5. Your Privacy Rights and Choices",
                        content: """
                        You have the following rights regarding your personal information:

                        5.1 Access and Portability
                        • Request a copy of all personal data we hold about you
                        • Export your data in a machine-readable format (JSON/CSV)
                        • Access available through Settings > Account Details > Download My Data

                        5.2 Correction and Updates
                        • Update your name, email, and profile information in Settings > Account Details
                        • Correct inaccurate or incomplete personal information

                        5.3 Deletion and Account Closure
                        • Delete your account permanently via Settings > Account Details > Delete Account
                        • Upon deletion, we remove personal data within 30 days (except where legally required to retain)
                        • Active tickets and transaction records may be retained for legal/accounting purposes (up to 7 years)

                        5.4 Marketing Communications
                        • Opt out of promotional emails via the "Unsubscribe" link in any marketing email
                        • Manage notification preferences in Settings > Notifications
                        • Transactional emails (purchase confirmations, support responses) cannot be disabled

                        5.5 Location Data
                        • Disable location access entirely in iOS/Android Settings > Burner > Location
                        • Location data is only collected when the app is in use, not in the background

                        5.6 Burner Mode Permissions
                        • Revoke Screen Time API access in iOS Settings > Screen Time > Apps with Access
                        • Disable Burner Mode in Settings > Burner Mode > Disable Feature

                        5.7 GDPR Rights (UK/EU Residents)
                        • Right to erasure ("right to be forgotten")
                        • Right to restrict processing
                        • Right to object to processing
                        • Right to lodge a complaint with the Information Commissioner's Office (ICO)

                        To exercise any of these rights, contact us at privacy@burner.app. We will respond within 30 days.
                        """
                    )

                    privacySection(
                        title: "6. Cookies and Tracking Technologies",
                        content: """
                        We use the following tracking technologies:

                        6.1 Essential Cookies
                        • Session cookies to keep you logged in
                        • Authentication tokens for secure access
                        • Shopping cart state for ticket purchases

                        6.2 Analytics and Diagnostics
                        • Session tracking: Login sessions and authentication state
                        • Error logging: Crash reports and error diagnostics for app stability
                        • Performance monitoring: API response times and app performance metrics

                        6.3 Preference Cookies
                        • Language and regional settings
                        • App theme and display preferences
                        • Notification settings and preferences

                        6.4 Managing Cookies
                        While you cannot disable essential cookies (required for core functionality), you can opt out of analytics tracking through Settings > Privacy > Analytics Sharing. Note that disabling certain cookies may limit app functionality.
                        """
                    )

                    privacySection(
                        title: "7. Children's Privacy",
                        content: """
                        Burner is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.

                        • Age Requirement: Users must be at least 13 years old to create an account
                        • Parental Controls: Burner Mode is a tool for parents to manage their own device usage, not for monitoring children
                        • Verification: We may request age verification for accounts that appear to belong to minors

                        If we discover that we have inadvertently collected information from a child under 13, we will delete that information immediately. Parents or guardians who believe their child has provided information should contact us at privacy@burner.app.
                        """
                    )

                    privacySection(
                        title: "8. Third-Party Services and Integrations",
                        content: """
                        Our app integrates with the following third-party services:

                        8.1 Authentication Services
                        • Supabase Auth: Primary authentication service with encrypted password storage
                        • Google Sign-In: OAuth authentication (https://policies.google.com/privacy)
                        • Apple Sign-In: OAuth authentication (https://www.apple.com/legal/privacy/)

                        8.2 Payment Processing
                        • Stripe: PCI-DSS compliant payment processor (https://stripe.com/privacy)
                        • Apple Pay/Google Pay: Subject to Apple/Google privacy policies

                        8.3 Backend and Infrastructure
                        • Supabase: PostgreSQL database, authentication, and serverless edge functions (https://supabase.com/privacy)
                        • Google Cloud Platform: Infrastructure hosting (via Supabase)

                        8.4 Image Caching
                        • Kingfisher: Open-source image caching library that stores images locally on your device
                        • Cache settings: 7-day expiration, 300MB disk limit, 100MB memory limit
                        • No data transmitted to third parties

                        8.5 External Links
                        Our app may contain links to event organizer websites, social media, and other external sites. We are not responsible for the privacy practices of these third parties. Please review their privacy policies before providing any information.
                        """
                    )

                    privacySection(
                        title: "9. Data Retention and Deletion",
                        content: """
                        We retain your personal information as follows:

                        9.1 Account Data
                        • Active accounts: Retained indefinitely while your account is active
                        • Deleted accounts: Personal data removed within 30 days of account deletion
                        • Backup systems: Deleted data purged from backups within 90 days

                        9.2 Transaction Records
                        • Purchase history: Retained for 7 years for accounting, tax, and legal compliance
                        • Payment card data: Tokenized data retained by Stripe per their retention policy
                        • Refund records: Retained for 7 years for financial auditing

                        9.3 Communications
                        • Support tickets: Retained for 3 years for quality assurance and legal purposes
                        • Marketing emails: Retained until you unsubscribe or delete your account

                        9.4 Analytics Data
                        • Aggregated analytics: Retained indefinitely (anonymized, no personal identifiers)
                        • Individual usage logs: Retained for 26 months, then aggregated and anonymized

                        9.5 Legal Holds
                        If your data is subject to legal proceedings, regulatory investigations, or valid legal holds, we may retain it beyond standard retention periods as required by law.
                        """
                    )

                    privacySection(
                        title: "10. International Data Transfers",
                        content: """
                        Burner operates globally and your information may be transferred to and processed in countries other than your own.

                        10.1 Transfer Mechanisms
                        • UK/EU to USA: We use Standard Contractual Clauses (SCCs) approved by the European Commission
                        • Data Processing Agreements: All service providers sign DPAs ensuring GDPR compliance
                        • Adequacy Decisions: We transfer data only to countries with adequate data protection laws

                        10.2 Data Locations
                        • Primary servers: Managed by Supabase (multi-region cloud infrastructure)
                        • Backup servers: Automated backups via Supabase on Google Cloud Platform
                        • Image caching: Stored locally on your device via Kingfisher library

                        10.3 Safeguards
                        All international transfers are protected by:
                        • Encryption in transit and at rest
                        • Contractual data protection obligations
                        • Regular compliance audits
                        • GDPR Article 46 transfer mechanisms

                        By using Burner, you consent to the transfer of your information to these locations.
                        """
                    )

                    privacySection(
                        title: "11. California Privacy Rights (CCPA)",
                        content: """
                        California residents have additional rights under the California Consumer Privacy Act (CCPA):

                        11.1 Right to Know
                        You can request disclosure of:
                        • Categories of personal information collected
                        • Sources from which information was collected
                        • Business purposes for collecting information
                        • Categories of third parties with whom we share information

                        11.2 Right to Delete
                        Request deletion of personal information we have collected (subject to legal exceptions).

                        11.3 Right to Opt-Out of Sale
                        We do not sell personal information. If this changes, we will provide an opt-out mechanism.

                        11.4 Right to Non-Discrimination
                        We will not discriminate against you for exercising your CCPA rights.

                        11.5 Exercising Rights
                        To exercise these rights, email privacy@burner.app or call our toll-free number (available in app). We will verify your identity and respond within 45 days.
                        """
                    )

                    privacySection(
                        title: "12. Changes to This Privacy Policy",
                        content: """
                        We may update this Privacy Policy periodically to reflect changes in our practices, legal requirements, or service features.

                        12.1 Notification of Changes
                        • Material changes: We will notify you via email and in-app notification at least 30 days before changes take effect
                        • Minor updates: Posted to this page with an updated "Effective Date" at the top

                        12.2 Acceptance of Changes
                        • Continued use of the app after the effective date constitutes acceptance of the updated policy
                        • If you disagree with changes, you may delete your account before they take effect

                        12.3 Version History
                        Previous versions of this Privacy Policy are available upon request by emailing privacy@burner.app.
                        """
                    )

                    privacySection(
                        title: "13. Contact Information and Data Protection Officer",
                        content: """
                        If you have questions, concerns, or requests regarding this Privacy Policy or our data practices:

                        Data Protection Officer
                        Burner App Ltd
                        United Kingdom

                        Email: privacy@burner.app
                        General Support: support@burner.app

                        For GDPR-related inquiries:
                        Email: dpo@burner.app

                        For CCPA-related inquiries:
                        Toll-Free: Available in-app under Settings > Help & Support

                        We will respond to all requests within 30 days (or as required by applicable law).

                        Regulatory Authority
                        If you are in the UK/EU and believe we have not adequately addressed your privacy concerns, you have the right to lodge a complaint with:
                        • Information Commissioner's Office (ICO): https://ico.org.uk/make-a-complaint/
                        • Your local data protection supervisory authority

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

    private func privacySection(title: String, content: String) -> some View {
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
    PrivacyPolicyView()
        .preferredColorScheme(.dark)
}
