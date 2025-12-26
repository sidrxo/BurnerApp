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
                        answer: "Yes! You will need the email of the recipient. Once transferred, you will no longer have access to this ticket. The recipient will receive a notification and the ticket will appear in their account. All transfers are final, please ensure you enter the correct recipient's email. Please contact support@burnerlive.com with any issues."
                    )

                    faqItem(
                        id: 8,
                        question: "Can I buy multiple tickets for the same event?",
                        answer: "Each account can own a single ticket. If you want to buy tickets for someone else, you will need to purchase a ticket and then transfer it to the intended recipient's BURNER account. You may re-purchase a ticket for that event."
                    )

                    faqItem(
                        id: 9,
                        question: "What happens if I lose my phone before the event?",
                        answer: "Don't worry! Sign in to your BURNER account on another device (phone, tablet, or borrowed device) to access your tickets. Your tickets are stored securely in the cloud and can be accessed from any device where you're signed in."
                    )

                    faqItem(
                        id: 10,
                        question: "Can I view past tickets?",
                        answer: "Yes! In the Tickets tab, you'll see separate sections for 'Upcoming' and 'Past' tickets. Past tickets are automatically moved after the event date."
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

           

                    // BURNER MODE
                    Text("BURNER Mode")
                        .appCard()
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                 

                    faqItem(
                        id: 19,
                        question: "How do I set up BURNER Mode?",
                        answer: "Go to Settings >  Setup BURNER Mode and enable the feature. You'll be prompted to grant Screen Time permissions in iOS Settings. Then, select which apps you want to block during events (like social media, games, etc.). BURNER Mode will automatically activate when your ticket is scanned."
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
                        answer: "Events are automatically shown based on your location (within 31 miles / 50km). Make sure location permissions are enabled in Settings > BURNER > Location. You can browse featured events on the Explore tab or use the Search tab to find specific events by name, date, or price."
                    )

                    faqItem(
                        id: 23,
                        question: "How do bookmarks work?",
                        answer: "Tap the bookmark icon on any event card to save it for later. View all your bookmarked events in the Bookmarks tab. Bookmarks sync across all devices signed in to your account, making it easy to track events you're interested in without purchasing tickets immediately."
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
                        answer: "Location access (only when the app is in use) allows us to show events within 31 miles of your current location and provide personalized recommendations. Location data is never tracked or stored in and is only used for event discovery. You can disable location access in device settings, but this will limit event recommendations."
                    )

                    faqItem(
                        id: 28,
                        question: "What data does BURNER collect?",
                        answer: "We collect account information (name, email), payment information (processed by Stripe), purchase history, bookmarks, location data (with permission), and usage analytics. We do not sell your data to third parties. For complete details, see our Privacy Policy in Settings > Privacy Policy."
                    )
                    
                    faqItem(
                        id: 29,
                        question: "How do I delete my account?",
                        answer: "Go to Settings > Account Details and scroll to the bottom to find 'Delete Account'. This action is permanent and will delete all your personal information, bookmarks, and purchase history. Active tickets may be forfeited, so ensure you don't have any upcoming events before deleting."
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
                        id: 30,
                        question: "How do I contact support?",
                        answer: "Go to Settings > Help & Support > Contact Support to submit a request. You can also email us directly at support@burnerlive.com. We typically respond within 24-48 hours. For urgent ticket issues on event day, contact venue staff directly - they can manually verify your ticket."
                    )

                    faqItem(
                        id: 31,
                        question: "The app is crashing or not working properly. What should I do?",
                        answer: "First, try restarting the app or your device. Ensure you're running the latest version of the app (check the App Store/Play Store for updates). If issues continue, contact support@burner.app with details about your device and the problem."
                    )

                    faqItem(
                        id: 32,
                        question: "Are there any age restrictions?",
                        answer: "You must be at least 13 years old to create a BURNER account and use the app. Individual events may have their own age restrictions (18+, 21+, etc.), which are clearly stated in the event details. Please check age requirements before purchasing tickets."
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
