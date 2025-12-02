//
//  TicketViews.swift
//  burner
//
//

import SwiftUI
import Kingfisher
import ActivityKit
import FirebaseFunctions


// MARK: - Ticket Detail View
struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData
    var namespace: Namespace.ID?

    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showTransferSuccess = false
    @State private var showBurnerSetup = false
    @State private var liveActivityUpdateTimer: Timer?
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Background is simplified for the card look
            Color.black
                .ignoresSafeArea()

            VStack {
                // Main ticket design
                simpleTicketView
                    .padding(.horizontal, 20)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    CloseButton(action: {
                        dismiss()
                    }, isDark: true)
                    .padding(.top, 60)
                    .padding(.trailing, 20)
                }
                Spacer()
            }

            if showTransferSuccess {
                CustomAlertView(
                    title: "Transfer Successful",
                    description: "Ticket has been transferred successfully!",
                    primaryAction: { showTransferSuccess = false },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }
        }
        .navigationBarHidden(true)
        .if(namespace != nil && ticketWithEvent.ticket.id != nil) { view in
            view.navigationTransition(.zoom(sourceID: "ticketImage-\(ticketWithEvent.ticket.id!)", in: namespace!))
        }
        .fullScreenCover(isPresented: $showBurnerSetup) {
            BurnerModeSetupView(
                burnerManager: appState.burnerManager,
                onSkip: {
                    showBurnerSetup = false
                }
            )
        }
        .onAppear {
            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
            updateLiveActivityIfNeeded()

            // Start periodic updates every minute to catch state transitions
            liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                updateLiveActivityIfNeeded()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            liveActivityUpdateTimer?.invalidate()
            liveActivityUpdateTimer = nil
        }
    }

    // MARK: - Simple Ticket View (Modified to look like a vertical business card)

    private var simpleTicketView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. --- Logo/Title Top Section ---
            
            // 2. --- Event Details Section (Left-Aligned Stack) ---
            VStack(alignment: .leading, spacing: 20) {
                
                // Date & Time Block
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticketWithEvent.event.name.uppercased())
                        .font(.custom("Helvetica", size: 20).weight(.bold))
                        .kerning(-1.5)
                        .foregroundColor(.black)

            
                    Text(ticketWithEvent.event.venue.uppercased())
                        .appCard()
                        .foregroundColor(.black)

                    
                    Text("\(formatDateDay(ticketWithEvent.event.startTime ?? Date())) \(formatDateMonth(ticketWithEvent.event.startTime ?? Date())) \(formatDateYear(ticketWithEvent.event.startTime ?? Date()))")
                        .appCard()
                        .foregroundColor(.black)
                    
                    Text(formatTime(ticketWithEvent.event.startTime ?? Date()))
                        .appCard()
                        .foregroundColor(.black)
                    
       
                    Text((ticketWithEvent.ticket.status.uppercased()))
                        .appCard()
                            .foregroundColor(.black)
                    
                    Text(ticketWithEvent.ticket.ticketNumber ?? "N/A")
                        .appCard()
                        .foregroundColor(.black)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)

            
            // 3. --- QR Code Section ---
            VStack(spacing: 20) {
                if appState.burnerManager.hasCompletedSetup {
                    // QR Code (non-interactive)
                    QRCodeView(
                        data: qrCodeData,
                        size: 300,
                        backgroundColor: .black,
                        foregroundColor: .white
                    )
                    .padding(5)
                    .background(.white)
                } else {
                    // Locked state with setup button
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 220, height: 220)

                            VStack(spacing: 15) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white.opacity(0.3))

                                Button(action: {
                                    showBurnerSetup = true
                                }) {
                                    Text("COMPLETE SETUP")
                                        .font(.custom("Helvetica", size: 15).weight(.bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
            .background(Color.white) // Dark card background
        }

        .padding(.vertical, 32)
    }


    private var qrCodeData: String {
        return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
    }

    private func formatDateDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }

    private func formatDateMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    private func formatDateYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).uppercased()
    }

    // MARK: - Computed Properties

    private var shouldShowLiveActivityInfo: Bool {
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(ticketWithEvent.event.startTime ?? Date(), inSameDayAs: now)
        let isTomorrow = calendar.isDate(ticketWithEvent.event.startTime ?? Date(), inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)

        return (isToday || isTomorrow) && ticketWithEvent.ticket.status == "confirmed"
    }

    private var isEventToday: Bool {
        Calendar.current.isDate(ticketWithEvent.event.startTime ?? Date(), inSameDayAs: Date())
    }

    // MARK: - Live Activity Methods

    private func autoStartLiveActivityForEventDay() {
        guard isEventToday && ticketWithEvent.ticket.status == "confirmed" else {
            return
        }

        guard #available(iOS 16.1, *) else {
            return
        }

        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            return
        }

        let existingActivity = Activity<TicketActivityAttributes>.activities.first { activity in
            activity.attributes.eventName == ticketWithEvent.event.name &&
            Calendar.current.isDate(activity.attributes.startTime, inSameDayAs: ticketWithEvent.event.startTime ?? Date())
        }

        if existingActivity != nil {
            hasStartedLiveActivity = true
            return
        }

        TicketLiveActivityManager.startLiveActivity(for: ticketWithEvent)
        hasStartedLiveActivity = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            checkLiveActivityStatus()
        }
    }

    private func updateLiveActivityIfNeeded() {
        guard hasStartedLiveActivity else { return }
        guard #available(iOS 16.1, *) else { return }
        TicketLiveActivityManager.updateLiveActivity()
    }

    private func checkLiveActivityStatus() {
        guard #available(iOS 16.1, *) else { return }

        let hasActiveActivity = Activity<TicketActivityAttributes>.activities.contains { activity in
            activity.attributes.eventName == ticketWithEvent.event.name &&
            Calendar.current.isDate(activity.attributes.startTime, inSameDayAs: ticketWithEvent.event.startTime ?? Date())
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            isLiveActivityActive = hasActiveActivity
        }
    }
}

// MARK: - Preview


struct TicketViews_Previews: PreviewProvider {
    static var sampleEvent: Event {
        Event(
            id: "sampleEvent123",
            name: "Burner Nights",
            venue: "Lakota, Bristol",
            venueId: "venue001",
            startTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!, // Set to near future for Live Activity logic
            endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            price: 15.0,
            maxTickets: 100,
            ticketsSold: 25,
            imageUrl: "https://images.unsplash.com/photo-1543353071-087092ec3934",
            isFeatured: true,
            description: "A phone-free night of music and connection.",
            status: "active",
            tags: ["techno", "house", "burner"],
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static var sampleTicket: Ticket {
        Ticket(
            id: "ticket001",
            eventId: "sampleEvent123",
            userId: "user001",
            ticketNumber: "BNR-001",
            eventName: "Burner Nights",
            venue: "Lakota, Bristol",
            startTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
            totalPrice: 15.0,
            purchaseDate: Date(),
            status: "confirmed",
            qrCode: "BNR001-SECUREHASH"
        )
    }

    static var sampleTicketWithEvent: TicketWithEventData {
        TicketWithEventData(ticket: sampleTicket, event: sampleEvent)
    }

    static var previews: some View {
        NavigationView {
            TicketDetailView(ticketWithEvent: sampleTicketWithEvent)
        }
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
    }
}
