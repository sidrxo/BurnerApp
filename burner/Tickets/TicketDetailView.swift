//
//  TicketViews.swift
//  burner
//
//  Created by Sid Rao on 18/09/2025.
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
        VStack(spacing: 0) {
            // Main Content
            VStack(spacing: 0) {
                Spacer()
                
                // Main Ticket Card (centered)
                ticketCard
                
                Spacer()
            }
            
            // Navigation Controls
            navigationControls
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
    
    private func menuItem(_ title: String, isSelected: Bool = false) -> some View {
        VStack(spacing: 0) {
            Text(title)
               .appBody()
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.vertical, 16)
            
            Rectangle()
                .fill(isSelected ? Color.white : Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
    
 private var ticketCard: some View {
        VStack(spacing: 0) {
            // Ticket Content
            VStack(spacing: 20) {
                // Artist Name - Fixed to prevent clipping
                Text(ticketWithEvent.event.name.uppercased())
                    .appPageHeader()
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                
                // Date and Time
                HStack {
                    Text(ticketWithEvent.event.date.formatted(.dateTime.day().month().year()))
                       .appBody()
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text(ticketWithEvent.event.date.formatted(.dateTime.hour().minute()))
                       .appBody()
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 30)
                
                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 2)
                    .padding(.horizontal, 30)
                
                // Venue and Status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VENUE")
                            .appSecondary()
                            .foregroundColor(.black)
                        Text(ticketWithEvent.event.venue.uppercased())
                            .appBody()
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("STATUS")
                            .appSecondary()
                            .foregroundColor(.black)
                        Text(ticketWithEvent.ticket.status.uppercased())
                            .appBody()
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 30)
                
                // Add more spacing before dashed line
                Spacer()
                    .frame(height: 20)
                
                // Dashed line separator (full width)
                VStack(spacing: 20) {
                    dashedLine
                    
                    // Bottom section with circular text and QR code
                    VStack(spacing: 16) {
                        HStack(alignment: .center, spacing: 20) {
                            // Circular text on the left
                            CircularTextView(text: "MEET ME IN THE MOMENT   ", radius: 50)
                                .frame(width: 100, height: 100)
                            
                            Spacer()
                            
                            // QR Code on the right
                            Button(action: {
                                showingFullScreen = true
                            }) {
                                QRCodeView(
                                    data: qrCodeData,
                                    size: 120,
                                    backgroundColor: .clear,
                                    foregroundColor: .black
                                )
                                .background(Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    // MARK: - Dashed Line
    private var dashedLine: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .foregroundColor(.black.opacity(0.6))
        }
        .frame(height: 2)
    }

    // MARK: - Circular Text View
    struct CircularTextView: View {
        let text: String
        let radius: CGFloat
        
        var body: some View {
            ZStack {
                ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(text.count))))
                }
            }
            .rotationEffect(.degrees(-90)) // Start from top
        }
    }
    
    private var navigationControls: some View {
        HStack {
            // Progress indicators
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 30, height: 4)
                    .clipShape(Capsule())
                
                Rectangle()
                    .fill(Color(red: 0.8, green: 1.0, blue: 0.2))
                    .frame(width: 30, height: 4)
                    .clipShape(Capsule())
                
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 30, height: 4)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Button(action: {
                // Next action
            }) {
                HStack(spacing: 8) {
                    Text("NEXT")
                       .appBody()
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                       .appBody()
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 30)
        .padding(.bottom, 40)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(ticketWithEvent.ticket.status.capitalized)
                .appFont(size: 14, weight: .medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var statusColor: Color {
        switch ticketWithEvent.ticket.status {
        case "confirmed": return .green
        case "cancelled": return .red
        case "pending": return .orange
        default: return .gray
        }
    }
    
    private var eventDetailsCard: some View {
        // This component is no longer needed in the new design
        EmptyView()
    }
    
    private var qrCodeSection: some View {
        // This component is no longer needed in the new design
        EmptyView()
    }
    
    private var cancelledTicketView: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text("Ticket Cancelled")
                    .appFont(size: 20, weight: .semibold)
                    .foregroundColor(.red)
                
                Text("This ticket has been cancelled and cannot be used for entry. Please contact support if you believe this is an error.")
                    .appFont(size: 14)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
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

// MARK: - Ticket QR Code View
struct TicketQRCodeView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var showingFullScreen = false
    @State private var brightness: Double = UIScreen.main.brightness
    
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
        VStack(spacing: 16) {
            Button(action: {
                showingFullScreen = true
            }) {
                VStack(spacing: 12) {
                    QRCodeView(
                        data: qrCodeData,
                        size: 200,
                        backgroundColor: .white,
                        foregroundColor: .black
                    )
                    
                    Text(ticketWithEvent.ticket.ticketNumber ?? "No Ticket Number")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(spacing: 8) {
                Button(action: {
                    showingFullScreen = true
                }) {
                    Text("Tap to enlarge")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.blue)
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            FullScreenQRCodeView(
                ticketWithEvent: ticketWithEvent,
                qrCodeData: qrCodeData
            )
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
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                }
            
            VStack {
                Spacer()
                
                // QR Code only
                QRCodeView(
                    data: qrCodeData,
                    size: min(UIScreen.main.bounds.width - 80, 300),
                    backgroundColor: .white,
                    foregroundColor: .black
                )
                .shadow(color: .black.opacity(0.3), radius: 20)
                
                Spacer()
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

// MARK: - Enhanced Ticket Detail Row
struct EnhancedTicketDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appFont(size: 13)
                    .foregroundColor(.gray)
                
                Text(value)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(.white)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - View Extensions
extension View {
    func ticketCard() -> some View {
        self
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
            )
    }
}
