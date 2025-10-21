//
//  TicketViews.swift
//  burner
//
//

import SwiftUI
import Kingfisher
import ActivityKit

// MARK: - Custom Ticket Stub Shape with Perforation
struct TicketStubShape: Shape {
    let perforationY: CGFloat
    let holeRadius: CGFloat = 8
    let holeSpacing: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Calculate number of holes that fit
        let holeCount = Int(rect.width / holeSpacing)

        // Start from top-left corner
        path.move(to: CGPoint(x: 0, y: 0))

        // Top edge
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // Right edge to perforation
        path.addLine(to: CGPoint(x: rect.width, y: perforationY))

        // Perforation line (right to left with semi-circles)
        for i in stride(from: holeCount, through: 0, by: -1) {
            let x = CGFloat(i) * holeSpacing
            let centerY = perforationY

            // Add semi-circle notch pointing up
            path.addArc(
                center: CGPoint(x: x, y: centerY),
                radius: 3,
                startAngle: .degrees(0),
                endAngle: .degrees(180),
                clockwise: false
            )
        }

        // Continue to bottom-right
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        // Bottom edge
        path.addLine(to: CGPoint(x: 0, y: rect.height))

        // Left edge back to start
        path.addLine(to: CGPoint(x: 0, y: 0))

        path.closeSubpath()

        return path
    }
}

// MARK: - Corner Punch Hole
struct CornerPunchHole: View {
    var body: some View {
        Circle()
            .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
            .background(Circle().fill(Color.black))
            .frame(width: 20, height: 20)
    }
}

// MARK: - Ticket Detail View
struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showingFullScreen = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main Ticket Card
                ticketCard

                Spacer()
            }
            .padding(.horizontal, 24)
        }
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
        // Use server-generated QR code from ticket data
        // QR codes are generated server-side for security (includes hash)
        return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
    }

    private var ticketCard: some View {
        GeometryReader { geometry in
            ZStack {
                // Background card
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white)
                    .shadow(color: Color.white.opacity(0.1), radius: 30, y: 10)

                VStack(spacing: 0) {
                    // Top section - Event info
                    VStack(spacing: 14) {
                        // Event name
                        Text(ticketWithEvent.event.name)
                            .appHero()
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 32)
                            .multilineTextAlignment(.center)


                        // Venue
                        Text(ticketWithEvent.event.venue.uppercased())
                            .appBody()
                            .foregroundColor(.black.opacity(0.5))
                            .multilineTextAlignment(.center)

                        // Date and time in a compact row
                        HStack(spacing: 24) {
                            VStack(spacing: 4) {
                                Text(formatDate(ticketWithEvent.event.startTime ?? Date()))
                                    .appSectionHeader()
                                    .foregroundColor(.black)

                                Text("DATE")
                                    .appCaption()
                                    .foregroundColor(.black.opacity(0.4))
                                    .tracking(1)
                            }

                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 1, height: 40)

                            VStack(spacing: 4) {
                                Text(formatTime(ticketWithEvent.event.startTime ?? Date()))
                                    .appSectionHeader()
                                    .foregroundColor(.black)

                                Text("TIME")
                                    .appCaption()
                                    .foregroundColor(.black.opacity(0.4))
                                    .tracking(1)
                            }
                        }
                    }

                    // Perforation line
                    perforationLine
                        .padding(.vertical, 20)
                    

                    // Bottom section - QR code
                    VStack(spacing: 10) {
                        Button(action: {
                            showingFullScreen = true
                        }) {
                            VStack(spacing: 16) {
                                QRCodeView(
                                    data: qrCodeData,
                                    size: 200,
                                    backgroundColor: .white,
                                    foregroundColor: .black
                                )

                                Text("TAP TO SCAN")
                                    .appCaption()
                                    .foregroundColor(.black.opacity(0.4))
                                    .tracking(1.5)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Ticket number with accent
                        HStack(spacing: 12) {
                            Text(ticketWithEvent.ticket.ticketNumber ?? "N/A")
                                .appBody()
                                .foregroundColor(.black)
                                .tracking(2)

                        }
                    }
                }

                // Corner punch holes
                VStack {
                    HStack {
                        CornerPunchHole()
                            .padding(.leading, 24)
                            .padding(.top, 24)

                        Spacer()

                        CornerPunchHole()
                            .padding(.trailing, 24)
                            .padding(.top, 24)
                    }

                    Spacer()

                    HStack {
                        CornerPunchHole()
                            .padding(.leading, 24)
                            .padding(.bottom, 24)

                        Spacer()

                        CornerPunchHole()
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.65)
        .padding(.bottom, 50)
    }

    private var perforationLine: some View {
        HStack(spacing: 8) {
            ForEach(0..<30, id: \.self) { _ in
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 3, height: 3)
            }
        }
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date).uppercased()
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
        // Use server-generated QR code from ticket data
        // QR codes are generated server-side for security (includes hash)
        return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
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
// MARK: - Preview

#if DEBUG
struct TicketViews_Previews: PreviewProvider {
    static var sampleEvent: Event {
        Event(
            id: "sampleEvent123",
            name: "Burner Nights",
            venue: "Lakota, Bristol",
            venueId: "venue001",
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date()),
            price: 15.0,
            maxTickets: 100,
            ticketsSold: 25,
            imageUrl: "https://images.unsplash.com/photo-1543353071-087092ec3934",
            isFeatured: true,
            description: "A phone-free night of music and connection.",
            status: "active",
            category: "Music",
            tags: ["techno", "house", "burner"],
            organizerId: "org123",
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
            startTime: Date(),
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
        .preferredColorScheme(.dark)
    }
}
#endif
