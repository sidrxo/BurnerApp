//
//  FAQView.swift
//  burner
//
//  Created by Claude on 22/10/2025.
//

import SwiftUI

struct FAQView: View {
    @State private var expandedQuestions: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderSection(title: "FAQ", includeTopPadding: false, includeHorizontalPadding: false)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                VStack(spacing: 12) {
                    // ACCOUNT & GETTING STARTED
                    Text("Account & Getting Started")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 0,
                        question: "How do I create an account?",
                        answer: "You can create an account by downloading the Burner app and signing up with your email address and password, or by using Google Sign-In for quick authentication. You must be at least 13 years old to create an account."
                    )

                    faqItem(
                        id: 1,
                        question: "Can I sign in with Google?",
                        answer: "Yes! When creating an account or signing in, you can choose 'Sign in with Google' to authenticate using your existing Google account. This makes login faster and more convenient."
                    )

                    faqItem(
                        id: 2,
                        question: "How do I reset my password?",
                        answer: "On the login screen, tap 'Forgot Password' and enter your email address. You'll receive a password reset link via email. Follow the link to create a new password. If you signed up with Google Sign-In, you'll need to reset your password through Google."
                    )

                    faqItem(
                        id: 3,
                        question: "How do I delete my account?",
                        answer: "Go to Settings > Account Details and scroll to the bottom to find 'Delete Account'. This action is permanent and will delete all your personal information, bookmarks, and purchase history. Active tickets may be forfeited, so ensure you don't have any upcoming events before deleting."
                    )

                    // TICKETS & PURCHASES
                    Text("Tickets & Purchases")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 4,
                        question: "How do I purchase tickets?",
                        answer: "Browse events on the Explore or Search tab, select an event you're interested in, and tap 'Buy Ticket'. Choose your payment method (Apple Pay, Google Pay, or credit/debit card) and confirm your purchase. You'll receive a confirmation email immediately."
                    )

                    faqItem(
                        id: 5,
                        question: "Can I get a refund for my ticket?",
                        answer: "All ticket sales are final and non-refundable unless: (1) the event is cancelled by the organizer (full refund within 5-10 business days), (2) the event is rescheduled and you cannot attend the new date (refund at organizer's discretion), or (3) a technical error resulted in duplicate purchases (refund of duplicate only)."
                    )

                    faqItem(
                        id: 6,
                        question: "How do I access my tickets?",
                        answer: "Your tickets are available in the 'Tickets' tab at the bottom of the screen. Tap on any ticket to view its unique QR code, which will be scanned at the venue entrance. Make sure your phone is charged and ready when arriving at the event."
                    )

                    faqItem(
                        id: 7,
                        question: "Can I transfer my ticket to someone else?",
                        answer: "Ticket transfers are not currently supported. All tickets are tied to the purchasing account and cannot be transferred, shared, or resold. Each account is limited to one ticket per event. Please ensure you can attend before purchasing."
                    )

                    faqItem(
                        id: 8,
                        question: "Can I buy multiple tickets for the same event?",
                        answer: "Currently, you can purchase one ticket per event per account. If you need tickets for friends or family, each person will need to create their own Burner account and purchase tickets individually."
                    )

                    faqItem(
                        id: 9,
                        question: "What happens if I lose my phone before the event?",
                        answer: "Don't worry! Sign in to your Burner account on another device (phone, tablet, or borrowed device) to access your tickets. Your tickets are stored securely in the cloud and can be accessed from any device where you're signed in."
                    )

                    faqItem(
                        id: 10,
                        question: "Can I view past tickets?",
                        answer: "Yes! In the Tickets tab, you'll see separate sections for 'Upcoming' and 'Past' tickets. Past tickets are automatically moved after the event date. You can swipe left on past tickets to delete them from your view while maintaining a record in our system."
                    )

                    // PAYMENTS & BILLING
                    Text("Payments & Billing")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 11,
                        question: "What payment methods do you accept?",
                        answer: "We accept Apple Pay (iOS), Google Pay (Android), and all major credit/debit cards including Visa, Mastercard, and American Express. All payments are processed securely through Stripe, a PCI-DSS compliant payment processor."
                    )

                    faqItem(
                        id: 12,
                        question: "How do I add a payment method?",
                        answer: "During ticket purchase, you'll be prompted to add a payment method. You can also add cards in advance by going to Settings > Payment Methods > Add Payment Method. Your card details are encrypted and tokenized by Stripe—we never store your full card number on our servers."
                    )

                    faqItem(
                        id: 13,
                        question: "Is it safe to save my payment information?",
                        answer: "Yes! All payment information is encrypted and tokenized by Stripe, a PCI-DSS Level 1 compliant payment processor. We never store your full credit card number, CVV, or PIN. Your payment data is protected using bank-level security."
                    )

                    faqItem(
                        id: 14,
                        question: "Why did my payment fail?",
                        answer: "Payment failures can occur due to insufficient funds, expired cards, incorrect billing information, or your bank declining the transaction. Check your card details and try again. If the problem persists, contact your bank or try a different payment method. You'll only be charged if the purchase is successful."
                    )

                    // VENUE ENTRY & QR CODES
                    Text("Venue Entry & QR Codes")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 15,
                        question: "What should I do if my QR code won't scan?",
                        answer: "First, ensure your screen brightness is at maximum and the QR code is clearly visible without glare. Clean your screen if necessary. If the code still won't scan, venue staff can manually verify your ticket using the ticket number displayed below the QR code in the ticket details."
                    )

                    faqItem(
                        id: 16,
                        question: "Do I need an internet connection at the venue?",
                        answer: "Tickets are cached locally on your device, so you can display your QR code even without an internet connection. However, we recommend having a connection when possible for real-time updates about the event."
                    )

                    faqItem(
                        id: 17,
                        question: "Can I use a screenshot of my ticket?",
                        answer: "While screenshots may work at some venues, we strongly recommend using the live QR code from the app. The app ensures your ticket is valid, not already scanned, and provides the most up-to-date information. Screenshots may be rejected by venue security."
                    )

                    // BURNER MODE
                    Text("Burner Mode")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 18,
                        question: "What is Burner Mode?",
                        answer: "Burner Mode is an optional iOS feature (iOS 16.1+) that uses the Screen Time API to block distracting apps during events. When your ticket is scanned at the venue, Burner Mode automatically activates and blocks apps you've configured, helping you stay present and focused on the live experience."
                    )

                    faqItem(
                        id: 19,
                        question: "How do I set up Burner Mode?",
                        answer: "Go to Settings > Burner Mode and enable the feature. You'll be prompted to grant Screen Time permissions in iOS Settings. Then, select which apps you want to block during events (like social media, games, etc.). Burner Mode will automatically activate when your ticket is scanned."
                    )

                    faqItem(
                        id: 20,
                        question: "Can I disable Burner Mode during an event?",
                        answer: "Burner Mode is designed to help you stay focused, but you can disable it at any time through iOS Settings > Screen Time. However, the goal is to enjoy the event without digital distractions. Emergency services (Phone, Messages, emergency calls) are never blocked."
                    )

                    faqItem(
                        id: 21,
                        question: "Is Burner Mode available on Android?",
                        answer: "Burner Mode is currently only available on iOS 16.1 and later due to the Screen Time API. We're exploring similar functionality for Android in future updates. Android users can still enjoy all other features of the app."
                    )

                    // EVENTS & DISCOVERY
                    Text("Events & Discovery")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 22,
                        question: "How do I find events near me?",
                        answer: "Events are automatically shown based on your location (within 31 miles / 50km). Make sure location permissions are enabled in Settings > Burner > Location. You can browse featured events on the Explore tab or use the Search tab to find specific events by name, date, or price."
                    )

                    faqItem(
                        id: 23,
                        question: "How do bookmarks work?",
                        answer: "Tap the bookmark icon on any event card to save it for later. View all your bookmarked events in the Bookmarks tab. Bookmarks sync across all devices signed in to your account, making it easy to track events you're interested in without purchasing tickets immediately."
                    )

                    faqItem(
                        id: 24,
                        question: "How are events sorted in search?",
                        answer: "In the Search tab, you can sort events by date (showing upcoming events first) or by price (from lowest to highest). Use the filter buttons at the top of the Search tab to change the sorting method and find events that match your preferences."
                    )

                    faqItem(
                        id: 25,
                        question: "What if an event is cancelled or rescheduled?",
                        answer: "You'll receive an immediate notification via email and push notification if an event is cancelled or rescheduled. For cancellations, refunds are processed automatically to your original payment method within 5-10 business days. For rescheduled events, your ticket remains valid for the new date."
                    )

                    // PRIVACY & SECURITY
                    Text("Privacy & Security")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 26,
                        question: "How is my personal information protected?",
                        answer: "We use industry-standard security measures including TLS 1.3 encryption for data transmission, AES-256 encryption for data storage, and secure authentication protocols. Payment data is tokenized by Stripe and never stored on our servers. Read our Privacy Policy for detailed information."
                    )

                    faqItem(
                        id: 27,
                        question: "Why does the app need location access?",
                        answer: "Location access (only when the app is in use) allows us to show events within 31 miles of your current location and provide personalized recommendations. Location data is never tracked in the background and is only used for event discovery. You can disable location access in device settings, but this will limit event recommendations."
                    )

                    faqItem(
                        id: 28,
                        question: "What data does Burner collect?",
                        answer: "We collect account information (name, email), payment information (processed by Stripe), purchase history, bookmarks, location data (with permission), and usage analytics. We do not sell your data to third parties. For complete details, see our Privacy Policy in Settings > Privacy Policy."
                    )

                    // SUPPORT
                    Text("Support")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    faqItem(
                        id: 29,
                        question: "How do I contact support?",
                        answer: "Go to Settings > Help & Support > Contact Support to submit a request. You can also email us directly at support@burner.app. We typically respond within 24-48 hours. For urgent ticket issues on event day, contact venue staff directly—they can manually verify your ticket."
                    )

                    faqItem(
                        id: 30,
                        question: "The app is crashing or not working properly. What should I do?",
                        answer: "First, try restarting the app or your device. Ensure you're running the latest version of the app (check the App Store/Play Store for updates). Clear the app cache in Settings > Storage if the problem persists. If issues continue, contact support@burner.app with details about your device and the problem."
                    )

                    faqItem(
                        id: 31,
                        question: "Are there any age restrictions?",
                        answer: "You must be at least 13 years old to create a Burner account and use the app. Individual events may have their own age restrictions (18+, 21+, etc.), which are clearly stated in the event details. Please check age requirements before purchasing tickets."
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }

    private func faqItem(id: Int, question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedQuestions.contains(id) {
                        expandedQuestions.remove(id)
                    } else {
                        expandedQuestions.insert(id)
                    }
                }
            }) {
                HStack(alignment: .top) {
                    Text(question)
                        .appBody()
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: 12)

                    Image(systemName: expandedQuestions.contains(id) ? "chevron.up" : "chevron.down")
                        .appFont(size: 14)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())

            if expandedQuestions.contains(id) {
                Text(answer)
                    .appSecondary()
                    .foregroundColor(.gray)
                    .lineSpacing(6)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    FAQView()
        .preferredColorScheme(.dark)
}
