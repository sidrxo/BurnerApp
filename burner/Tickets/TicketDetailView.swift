//
//  TicketViews.swift
//  burner
//
//

import SwiftUI
import Kingfisher
import ActivityKit
import FirebaseFunctions

// MARK: - Modern Ticket Shape with Notches
struct ModernTicketShape: Shape {
    let notchSize: CGFloat = 24
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 32
        
        // Start from top-left, after corner radius
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // Top edge to top-right corner
        path.addLine(to: CGPoint(x: rect.width - cornerRadius, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: cornerRadius),
            control: CGPoint(x: rect.width, y: 0)
        )
        
        // Right edge to middle (before notch)
        let middleY = rect.height / 2
        path.addLine(to: CGPoint(x: rect.width, y: middleY - notchSize))
        
        // Right notch
        path.addArc(
            center: CGPoint(x: rect.width, y: middleY),
            radius: notchSize,
            startAngle: .degrees(270),
            endAngle: .degrees(90),
            clockwise: true
        )
        
        // Continue right edge to bottom
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cornerRadius, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: rect.height))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cornerRadius),
            control: CGPoint(x: 0, y: rect.height)
        )
        
        // Left edge to middle (before notch)
        path.addLine(to: CGPoint(x: 0, y: middleY + notchSize))
        
        // Left notch
        path.addArc(
            center: CGPoint(x: 0, y: middleY),
            radius: notchSize,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: true
        )
        
        // Continue left edge to top
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Dashed Separator Line
struct DashedSeparator: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 8]))
            .foregroundColor(Color.white.opacity(0.5))
        }
        .frame(height: 1)
    }
}

// MARK: - Ticket Detail View
struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showTransferSuccess = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        ZStack {
            // Dynamic background based on event image
            if !ticketWithEvent.event.imageUrl.isEmpty {
                KFImage(URL(string: ticketWithEvent.event.imageUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .blur(radius: 80)
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            
            // Solid black background
            Color.black
                .opacity(0.7)
                .ignoresSafeArea()

            VStack {
                Spacer()
                
                // Main ticket design
                modernTicketView
                    .padding(.horizontal, 20)
                
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
        }
    }

    // MARK: - Modern Ticket View

    private var modernTicketView: some View {
        GeometryReader { geometry in
            let ticketHeight = geometry.size.height * 0.75
            let topSectionHeight = ticketHeight / 2
            let bottomSectionHeight = ticketHeight / 2
            
            ZStack {
                // Ticket shape background
                ModernTicketShape()
                    .fill(Color.black)
                    .shadow(color: Color.white.opacity(0.05), radius: 30, y: 20)
                
                // Border overlay
                ModernTicketShape()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                
                VStack(spacing: 0) {
                    // Top section - Event details
                    VStack(spacing: 14) {
                        // Status badge
                        HStack {
                            Spacer()
                            statusBadge
                            Spacer()
                        }
                        .padding(.top, 16)
                        
                        // Event name - Large and bold
                        Text(ticketWithEvent.event.name.uppercased())
                            .font(.custom("Avenir", size: 28))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 28)
                            .tracking(1)
                        
                        // Venue
                        Text(ticketWithEvent.event.venue.uppercased())
                            .font(.custom("Avenir", size: 12).weight(.semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        
                        // Date and time display
                        HStack(spacing: 0) {
                            // Date block
                            VStack(spacing: 4) {
                                Text("\(formatDateDay(ticketWithEvent.event.startTime ?? Date())) \(formatDateMonth(ticketWithEvent.event.startTime ?? Date()))")
                                    .font(.custom("Avenir", size: 24))
                                    .foregroundColor(.white)
                                
                                Text("DATE")
                                    .font(.custom("Avenir", size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(2)
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Vertical divider
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 1, height: 70)
                            
                            // Time block
                            VStack(spacing: 4) {
                                Text(formatTime(ticketWithEvent.event.startTime ?? Date()))
                                    .font(.custom("Avenir", size: 24))
                                    .foregroundColor(.white)
                                
                                Text("DOORS OPEN")
                                    .font(.custom("Avenir", size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                    }
                    .frame(height: topSectionHeight)
                    
                    // Dashed separator - positioned at the notch level
                    DashedSeparator()
                        .padding(.horizontal, 24)
                    
                    // Bottom section - QR code
                    VStack(spacing: 10) {
                        if appState.burnerManager.isSetupValid {
                            // QR Code section
                            Button(action: {
                                coordinator.showFullScreenQRCode(for: ticketWithEvent.ticket)
                            }) {
                                VStack(spacing: 12) {
                                    QRCodeView(
                                        data: qrCodeData,
                                        size: 180,
                                        backgroundColor: .white,
                                        foregroundColor: .black
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Locked state
                            VStack(spacing: 16) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 200, height: 200)

                                    VStack(spacing: 10) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white.opacity(0.3))

                                        Text("BURNER MODE\nREQUIRED")
                                            .font(.custom("Avenir", size: 15).weight(.black))
                                            .foregroundColor(.white.opacity(0.8))
                                            .multilineTextAlignment(.center)
                                            .tracking(1)

                                        Text("Enable in Settings")
                                            .font(.custom("Avenir", size: 10).weight(.semibold))
                                            .foregroundColor(.white.opacity(0.4))
                                            .tracking(1)
                                    }
                                }
                            }
                        }

                        // Ticket number - only show if burner mode is setup
                        if appState.burnerManager.isSetupValid {
                            Text(ticketWithEvent.ticket.ticketNumber ?? "N/A")
                                .font(.custom("Avenir", size: 15).weight(.black))
                                .foregroundColor(.white)
                                .tracking(3)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(height: bottomSectionHeight)
                }
            }
            .frame(width: geometry.size.width, height: ticketHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .padding(.bottom, 68)
    }
    
    // MARK: - Status Badge
    
    private var statusBadge: some View {
        Text(ticketWithEvent.ticket.status.uppercased())
            .font(.custom("Avenir", size: 10))
            .foregroundColor(statusColor)
            .tracking(2)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var statusColor: Color {
        switch ticketWithEvent.ticket.status.lowercased() {
        case "confirmed":
            return Color.green
        case "pending":
            return Color.yellow
        case "cancelled":
            return Color.red
        default:
            return Color.white
        }
    }

    // MARK: - Helper Methods

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

            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text(ticketWithEvent.event.name.uppercased())
                        .font(.custom("Avenir", size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .tracking(1)
                        .padding(.horizontal, 40)
                    
                    Text(ticketWithEvent.event.venue.uppercased())
                        .font(.custom("Avenir", size: 12).weight(.semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)
                }

                // QR Code with white border
                QRCodeView(
                    data: qrCodeData,
                    size: min(UIScreen.main.bounds.width - 60, 340),
                    backgroundColor: .white,
                    foregroundColor: .black
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

                // Ticket number (without "TICKET №" label)
                Text(ticketWithEvent.ticket.ticketNumber ?? "")
                    .font(.custom("Avenir", size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(3)

                Spacer()

                // Close button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("CLOSE")
                        .font(.custom("Avenir", size: 15))
                        .foregroundColor(.black)
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
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
    @EnvironmentObject var coordinator: NavigationCoordinator

    private var qrCodeData: String {
        return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
    }

    var body: some View {
        Button(action: {
            coordinator.showFullScreenQRCode(for: ticketWithEvent.ticket)
        }) {
            QRCodeView(
                data: qrCodeData,
                size: 200,
                backgroundColor: .white,
                foregroundColor: .black
            )
        }
        .buttonStyle(PlainButtonStyle())
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
            startTime: Date(),
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
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
    }
}

