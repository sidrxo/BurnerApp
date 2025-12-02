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

                VStack(spacing: 16) {
                    faqItem(
                        id: 0,
                        question: "How do I purchase tickets?",
                        answer: "Browse events on the home or search tab, select an event you're interested in, and tap 'Buy Ticket'. You can pay using Apple Pay or a saved credit/debit card."
                    )

                    faqItem(
                        id: 1,
                        question: "Can I get a refund for my ticket?",
                        answer: "All ticket sales are final and non-refundable unless the event is cancelled by the organizer. If an event is cancelled, you will receive a full refund to your original payment method within 5-10 business days."
                    )

                    faqItem(
                        id: 2,
                        question: "How do I access my tickets?",
                        answer: "Your tickets are available in the 'Tickets' tab. Each ticket has a unique QR code that will be scanned at the venue entrance. Make sure to have your phone charged and ready when arriving at the event."
                    )

                    faqItem(
                        id: 3,
                        question: "Can I transfer my ticket to someone else?",
                        answer: "Ticket transfers are not currently supported. Tickets are tied to the purchasing account and cannot be transferred or resold. Please ensure you can attend before purchasing."
                    )

                    faqItem(
                        id: 4,
                        question: "What is Burner Mode?",
                        answer: "Burner Mode is a parental control feature that blocks access to distracting apps during events. It can be set up in Settings and automatically activates when your ticket is scanned at the venue, helping you stay present and enjoy the experience."
                    )

                    faqItem(
                        id: 5,
                        question: "How do I add a payment method?",
                        answer: "Go to Settings > Payment, then tap 'Add Payment Method'. Enter your card details securely. Your payment information is encrypted and processed through industry-standard secure payment processors."
                    )

                    faqItem(
                        id: 6,
                        question: "What happens if I lose my phone before the event?",
                        answer: "Sign in to your Burner account on another device to access your tickets. Your tickets are stored securely in your account and can be accessed from any device where you're signed in."
                    )

                    faqItem(
                        id: 7,
                        question: "How do bookmarks work?",
                        answer: "Tap the bookmark icon on any event to save it for later. View all your bookmarked events in Settings > Bookmarks. This helps you keep track of events you're interested in without purchasing tickets immediately."
                    )

                    faqItem(
                        id: 8,
                        question: "Can I buy multiple tickets for the same event?",
                        answer: "Currently, you can purchase one ticket per event per account. If you need tickets for a group, each person will need to purchase their own ticket through their individual account."
                    )

                    faqItem(
                        id: 9,
                        question: "What should I do if my QR code won't scan?",
                        answer: "Ensure your screen brightness is at maximum and the QR code is clearly visible. If the code still won't scan, venue staff can manually verify your ticket using your ticket number found in the ticket details."
                    )

                    faqItem(
                        id: 10,
                        question: "How do I delete my account?",
                        answer: "Go to Settings > Account Details and scroll to the bottom to find 'Delete Account'. Note that this action is permanent and will delete all your tickets, bookmarks, and account information."
                    )

                    faqItem(
                        id: 11,
                        question: "Are there any age restrictions?",
                        answer: "You must be at least 13 years old to create a Burner account. Individual events may have their own age restrictions, which will be clearly stated in the event details. Please check before purchasing."
                    )

                    faqItem(
                        id: 12,
                        question: "How do I contact support?",
                        answer: "Go to Settings > Help & Support > Contact Support. You can also email us directly at support@burner.app. We typically respond within 24-48 hours."
                    )

                    faqItem(
                        id: 13,
                        question: "What payment methods do you accept?",
                        answer: "We accept Apple Pay and all major credit and debit cards (Visa, Mastercard, American Express). All payments are processed securely through Stripe."
                    )

                    faqItem(
                        id: 14,
                        question: "Can I view past tickets?",
                        answer: "Yes! In the Tickets tab, switch to the 'Past' filter to view all your previous event tickets. You can swipe left on past tickets to delete them from your view while keeping a record in our system."
                    )

                    faqItem(
                        id: 15,
                        question: "How are events sorted in search?",
                        answer: "Events can be sorted by date (showing upcoming events first) or by price (from lowest to highest). Use the filter buttons at the top of the Search tab to change the sorting method."
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
                HStack {
                    Text(question)
                        .appBody()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: expandedQuestions.contains(id) ? "chevron.up" : "chevron.down")
                        .appFont(size: 12)
                        .foregroundColor(.gray)
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
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
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
