//
//  TicketViews.swift
//  burner
//
//

import SwiftUI
import Kingfisher
import ActivityKit

// MARK: - Ticket Detail View
struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showingFullScreen = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Main Ticket Card
                ticketCard
                    .padding(.top, 40)
                    .padding(.horizontal, 20)
                
                // Action Button
            
                Spacer()
                    .frame(height: 40)
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenQRCodeView(
                ticketWithEvent: ticketWithEvent,
                qrCodeData: qrCodeData
            )
        }
        .onAppear {
            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
        }
    }
    
    // MARK: - UI Components
    
    private var qrCodeData: String {
        guard let ticketId = ticketWithEvent.ticket.id,
              let eventId = ticketWithEvent.event.id else {
            return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
        }
        
        return QRCodeGenerator.generateQRCodeData(
            ticketId: ticketId,
            eventId: eventId,
            userId: ticketWithEvent.ticket.userId
        )
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(ticketWithEvent.event.name)
                .appHero()
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)
            
            Text(ticketWithEvent.event.venue)
                .appBody()
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
        }
    }
    
    private var ticketCard: some View {
        VStack(spacing: 0) {
            // Date/Time Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .appCaption()
                        .foregroundColor(.black.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(ticketWithEvent.event.date.formatted(.dateTime.day().month().year()))
                        .appBody()
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 8)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Time")
                        .appCaption()
                        .foregroundColor(.black.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Text(ticketWithEvent.event.date.formatted(.dateTime.hour().minute()))
                        .appBody()
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(red: 0.8, green: 1.0, blue: 0.2))
            
            // Main ticket content
            VStack(spacing: 24) {
                // Header Section
                headerSection
                    .padding(.top, 8)
                // QR Code Section
                Button(action: {
                    showingFullScreen = true
                }) {
                    VStack(spacing: 12) {
                        QRCodeView(
                            data: qrCodeData,
                            size: 180,
                            backgroundColor: .white,
                            foregroundColor: .black
                        )
                        
                        Text("Tap to scan")
                            .appSecondary()
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Ticket Details
                VStack(spacing: 16) {
                    detailRow(label: "Ticket Number", value: ticketWithEvent.ticket.ticketNumber ?? "N/A")
                    detailRow(label: "Status", value: ticketWithEvent.ticket.status.capitalized)
                }
                .padding(.horizontal, 24)
            }
            .padding(.vertical, 32)
            .background(.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .white.opacity(0.05), radius: 20, y: 10)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .appSecondary()
                .foregroundColor(.black.opacity(0.5))
            
            Spacer()
            
            Text(value)
                .appBody()
                .foregroundColor(.black)
        }
    }
    
    
    // MARK: - Computed Properties
    
    private var shouldShowLiveActivityInfo: Bool {
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(ticketWithEvent.event.date, inSameDayAs: now)
        let isTomorrow = calendar.isDate(ticketWithEvent.event.date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        
        return (isToday || isTomorrow) && ticketWithEvent.ticket.status == "confirmed"
    }
    
    private var isEventToday: Bool {
        Calendar.current.isDate(ticketWithEvent.event.date, inSameDayAs: Date())
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
            Calendar.current.isDate(activity.attributes.eventDate, inSameDayAs: ticketWithEvent.event.date)
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
            Calendar.current.isDate(activity.attributes.eventDate, inSameDayAs: ticketWithEvent.event.date)
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isLiveActivityActive = hasActiveActivity
        }
    }
}

// MARK: - Full Screen QR Code View
struct FullScreenQRCodeView: View {
    let ticketWithEvent: TicketWithEventData
    let qrCodeData: String
    @Environment(\.presentationMode) var presentationMode
    @State private var originalBrightness: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Event name
                Text(ticketWithEvent.event.name)
                    .appSectionHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // QR Code
                QRCodeView(
                    data: qrCodeData,
                    size: min(UIScreen.main.bounds.width - 80, 320),
                    backgroundColor: .white,
                    foregroundColor: .black
                )
                
                // Ticket number
                Text(ticketWithEvent.ticket.ticketNumber ?? "")
                    .appSecondary()
                    .foregroundColor(.gray)
                    .tracking(2)
                
                Spacer()
                
                // Close button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Close")
                        .appBody()
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        }
        .onDisappear {
            UIScreen.main.brightness = originalBrightness
        }
    }
}

// MARK: - Ticket QR Code View (for reuse elsewhere)
struct TicketQRCodeView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var showingFullScreen = false
    
    private var qrCodeData: String {
        guard let ticketId = ticketWithEvent.ticket.id,
              let eventId = ticketWithEvent.event.id else {
            return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
        }
        
        return QRCodeGenerator.generateQRCodeData(
            ticketId: ticketId,
            eventId: eventId,
            userId: ticketWithEvent.ticket.userId
        )
    }
    
    var body: some View {
        Button(action: {
            showingFullScreen = true
        }) {
            QRCodeView(
                data: qrCodeData,
                size: 200,
                backgroundColor: .white,
                foregroundColor: .black
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenQRCodeView(
                ticketWithEvent: ticketWithEvent,
                qrCodeData: qrCodeData
            )
        }
    }
}
#Preview {
    NavigationView {
        TicketDetailView(
            ticketWithEvent: TicketWithEventData(
                ticket: Ticket(
                    id: "preview-ticket-123",
                    eventId: "preview-event-456",
                    eventName: "Summer Music Festival 2025",
                    eventDate: Date().addingTimeInterval(86400),
                    venue: "Madison Square Garden",
                    userId: "preview-user-789",
                    pricePerTicket: 75.00,
                    totalPrice: 75.00,
                    purchaseDate: Date(),
                    status: "confirmed",
                    qrCode: "PREVIEW_QR_CODE",
                    ticketNumber: "TKT-2025-001"
                ),
                event: Event(
                    id: "preview-event-456",
                    name: "Summer Music Festival 2025",
                    venue: "Madison Square Garden",
                    date: Date().addingTimeInterval(86400),
                    price: 75.00,
                    maxTickets: 1000,
                    ticketsSold: 450,
                    imageUrl: "https://example.com/festival.jpg",
                    isFeatured: true,
                    description: "An amazing music festival featuring top artists"
                )
            )
        )
    }
}
