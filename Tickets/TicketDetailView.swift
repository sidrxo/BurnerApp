import SwiftUI
import Kingfisher
import ActivityKit

// MARK: - Complete TicketDetailView with Debug Support
struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData
    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var debugMessage = ""
    @State private var lastDebugUpdate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Event Image
                if let url = URL(string: ticketWithEvent.event.imageUrl), !ticketWithEvent.event.imageUrl.isEmpty {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                }

                VStack(spacing: 16) {
                    Text(ticketWithEvent.event.name)
                        .appFont(size: 24, weight: .bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        TicketDetailRow(icon: "location", title: "Venue", value: ticketWithEvent.event.venue)
                        TicketDetailRow(icon: "calendar", title: "Date", value: ticketWithEvent.event.date.formatted(date: .complete, time: .shortened))
                        TicketDetailRow(icon: "creditcard", title: "Price", value: "£\(String(format: "%.2f", ticketWithEvent.ticket.totalPrice))")
                        TicketDetailRow(icon: "person", title: "Status", value: ticketWithEvent.ticket.status.capitalized)

                        if let ticketNumber = ticketWithEvent.ticket.ticketNumber {
                            TicketDetailRow(icon: "number", title: "Ticket Number", value: ticketNumber)
                        }
                    }

                    // Live Activity Status Info
                    if shouldShowLiveActivityInfo {
                        LiveActivityStatusView(
                            ticketWithEvent: ticketWithEvent,
                            isActive: $isLiveActivityActive
                        )
                        .padding(.top, 8)
                    }
                    
                    // Debug Section
                    #if DEBUG
                    DebugLiveActivityView(
                        ticketWithEvent: ticketWithEvent,
                        isActive: $isLiveActivityActive,
                        debugMessage: $debugMessage,
                        lastUpdate: $lastDebugUpdate
                    )
                    .padding(.top, 8)
                    #endif

                    // Real QR Code
                    if ticketWithEvent.ticket.status == "confirmed" {
                        TicketQRCodeView(ticketWithEvent: ticketWithEvent)
                            .padding(.top, 20)
                    } else if ticketWithEvent.ticket.status == "cancelled" {
                        VStack(spacing: 12) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.red)
                            
                            Text("Ticket Cancelled")
                                .appFont(size: 18, weight: .semibold)
                                .foregroundColor(.red)
                            
                            Text("This ticket has been cancelled and cannot be used for entry")
                                .appFont(size: 14)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            debugLog("🎫 View appeared - starting auto Live Activity check")
            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            debugLog("📱 App entered foreground")
            autoStartLiveActivityForEventDay()
            updateLiveActivityIfNeeded()
            checkLiveActivityStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            debugLog("📱 App entered background")
            updateLiveActivityIfNeeded()
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
    
    // MARK: - Debug Helper
    
    private func debugLog(_ message: String) {
        print(message)
        debugMessage = message
        lastDebugUpdate = Date()
    }
    
    // MARK: - Live Activity Methods
    
    private func autoStartLiveActivityForEventDay() {
        debugLog("🔍 Checking auto-start conditions...")
        
        // Only proceed if it's event day and ticket is confirmed
        guard isEventToday && ticketWithEvent.ticket.status == "confirmed" else {
            debugLog("❌ Not starting - Event: \(isEventToday ? "TODAY" : "NOT TODAY"), Status: \(ticketWithEvent.ticket.status)")
            return
        }
        
        // Check if Live Activities are supported and enabled
        guard #available(iOS 16.1, *) else {
            debugLog("❌ Live Activities not supported on this iOS version")
            return
        }
        
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            debugLog("❌ Live Activities disabled by user - Enable in Settings → Face ID & Passcode → Live Activities")
            return
        }
        
        // Check if we already have an active Live Activity for this event
        let existingActivity = Activity<TicketActivityAttributes>.activities.first { activity in
            activity.attributes.eventName == ticketWithEvent.event.name &&
            Calendar.current.isDate(activity.attributes.eventDate, inSameDayAs: ticketWithEvent.event.date)
        }
        
        if existingActivity != nil {
            debugLog("⚠️ Live Activity already exists for this event")
            hasStartedLiveActivity = true
            return
        }
        
        // Start the Live Activity
        debugLog("🚀 Starting Live Activity for today's event: \(ticketWithEvent.event.name)")
        TicketLiveActivityManager.startLiveActivity(for: ticketWithEvent)
        hasStartedLiveActivity = true
        
        // Check if it was created successfully
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            checkLiveActivityStatus()
            
            let count = Activity<TicketActivityAttributes>.activities.count
            if count > 0 {
                debugLog("✅ Live Activity created successfully! Lock your screen to see it.")
            } else {
                debugLog("❌ Live Activity creation failed - check console for errors")
            }
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
        
        let count = Activity<TicketActivityAttributes>.activities.count
        debugLog("📊 Live Activity Status - Active: \(hasActiveActivity), Total Activities: \(count)")
    }
}

// MARK: - Debug Live Activity View
#if DEBUG
struct DebugLiveActivityView: View {
    let ticketWithEvent: TicketWithEventData
    @Binding var isActive: Bool
    @Binding var debugMessage: String
    @Binding var lastUpdate: Date
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🛠 Live Activity Debug")
                .appFont(size: 16, weight: .bold)
                .foregroundColor(.orange)
            
            // Status Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("iOS Version:")
                        .appFont(size: 12, weight: .medium)
                    Spacer()
                    Text("\(UIDevice.current.systemVersion)")
                        .appFont(size: 12)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Activities Enabled:")
                        .appFont(size: 12, weight: .medium)
                    Spacer()
                    if #available(iOS 16.1, *) {
                        Text(ActivityAuthorizationInfo().areActivitiesEnabled ? "✅ YES" : "❌ NO")
                            .appFont(size: 12)
                            .foregroundColor(ActivityAuthorizationInfo().areActivitiesEnabled ? .green : .red)
                    } else {
                        Text("❌ Not Supported")
                            .appFont(size: 12)
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    Text("Is Event Today:")
                        .appFont(size: 12, weight: .medium)
                    Spacer()
                    Text(Calendar.current.isDate(ticketWithEvent.event.date, inSameDayAs: Date()) ? "✅ YES" : "❌ NO")
                        .appFont(size: 12)
                        .foregroundColor(Calendar.current.isDate(ticketWithEvent.event.date, inSameDayAs: Date()) ? .green : .red)
                }
                
                HStack {
                    Text("Ticket Status:")
                        .appFont(size: 12, weight: .medium)
                    Spacer()
                    Text(ticketWithEvent.ticket.status.uppercased())
                        .appFont(size: 12)
                        .foregroundColor(ticketWithEvent.ticket.status == "confirmed" ? .green : .orange)
                }
                
                HStack {
                    Text("Active Activities:")
                        .appFont(size: 12, weight: .medium)
                    Spacer()
                    if #available(iOS 16.1, *) {
                        Text("\(Activity<TicketActivityAttributes>.activities.count)")
                            .appFont(size: 12)
                            .foregroundColor(.blue)
                    } else {
                        Text("N/A")
                            .appFont(size: 12)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Debug Message
            if !debugMessage.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Debug:")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.orange)
                    
                    Text(debugMessage)
                        .appFont(size: 10)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text("Updated: \(lastUpdate.formatted(date: .omitted, time: .standard))")
                        .appFont(size: 10)
                        .foregroundColor(.gray)
                }
            }
            
            // Action Buttons
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button("Check Status") {
                        if #available(iOS 16.1, *) {
                            TicketLiveActivityManager.debugCurrentActivities()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Force Start") {
                        TicketLiveActivityManager.startLiveActivity(for: ticketWithEvent)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                HStack(spacing: 12) {
                    Button("Update All") {
                        if #available(iOS 16.1, *) {
                            TicketLiveActivityManager.updateLiveActivity()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.blue)
                    
                    Button("End All") {
                        if #available(iOS 16.1, *) {
                            TicketLiveActivityManager.endLiveActivity()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }
                
                // Test with fake today's date
                Button("TEST: Fake Today's Event") {
                    // Create a fake event for today for testing
                    let fakeEvent = Event(
                        id: "test-event-today",
                        name: "TEST EVENT - Today",
                        description: "Test event for Live Activity",
                        date: Date(), // Right now
                        venue: "Test Venue",
                        imageUrl: "",
                        createdBy: ticketWithEvent.event.createdBy
                    )
                    
                    let fakeTicket = Ticket(
                        id: "test-ticket",
                        eventId: "test-event-today",
                        userId: ticketWithEvent.ticket.userId,
                        ticketNumber: "TEST123",
                        qrCode: "test-qr-code-data",
                        status: "confirmed",
                        purchaseDate: Date(),
                        totalPrice: 50.0
                    )
                    
                    let testTicketWithEvent = TicketWithEventData(
                        ticket: fakeTicket,
                        event: fakeEvent
                    )
                    
                    TicketLiveActivityManager.startLiveActivity(for: testTicketWithEvent)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(.purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
#endif

// MARK: - Live Activity Status View for Single Ticket
struct LiveActivityStatusView: View {
    let ticketWithEvent: TicketWithEventData
    @Binding var isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: isActive ? "dot.radiowaves.left.and.right" : "clock")
                    .foregroundColor(isActive ? .blue : .orange)
                    .font(.system(size: 16))
                
                Text("Live Activity")
                    .appFont(size: 16, weight: .medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(isActive ? .green : .orange)
                        .frame(width: 8, height: 8)
                    
                    Text(isActive ? "Active" : "Starting...")
                        .appFont(size: 14)
                        .foregroundColor(isActive ? .green : .orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if isEventToday {
                    if isActive {
                        Text("🎫 Your ticket QR code is now available on your lock screen for easy scanning")
                            .appFont(size: 12)
                            .foregroundColor(.green)
                    } else {
                        Text("🎫 Starting Live Activity - Your ticket will appear on your lock screen shortly")
                            .appFont(size: 12)
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("📱 Event details are displayed on your lock screen. QR code will appear on event day")
                        .appFont(size: 12)
                        .foregroundColor(.gray)
                }
                
                if #available(iOS 16.1, *), !ActivityAuthorizationInfo().areActivitiesEnabled {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Enable Live Activities in Settings → Face ID & Passcode → Live Activities")
                            .appFont(size: 11)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var isEventToday: Bool {
        Calendar.current.isDate(ticketWithEvent.event.date, inSameDayAs: Date())
    }
}

// MARK: - QR Code Display View
struct QRCodeDisplayView: View {
    let data: String
    
    var body: some View {
        if let qrImage = generateQRCode(from: data) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    VStack {
                        Image(systemName: "qrcode")
                            .foregroundColor(.gray)
                            .font(.largeTitle)
                        Text("QR Code")
                            .foregroundColor(.gray)
                    }
                )
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                let context = CIContext()
                if let cgImage = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgImage)
                }
            }
        }
        
        return nil
    }
}

// MARK: - Ticket Detail Row
struct TicketDetailRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 20)

            Text(title)
                .appFont(size: 16)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .appFont(size: 16, weight: .medium)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}
