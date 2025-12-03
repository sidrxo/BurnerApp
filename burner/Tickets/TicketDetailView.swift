//
//  TicketDetailView.swift
//  Updated with flip animation and fixed card width to match original
//

import SwiftUI
import Kingfisher
import ActivityKit
import FirebaseFunctions


// MARK: - Ticket Detail View
struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData

    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showTransferSuccess = false
    @State private var showBurnerSetup = false
    @State private var liveActivityUpdateTimer: Timer?
    @State private var flipped = true // Start with image side showing
    @State private var qrCodeImage: UIImage? = nil // Pre-generated QR code
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                
                // Flippable ticket card
                ZStack {
                    // Back of card (Event Image)
                    cardBackView
                        .opacity(flipped ? 1 : 0)
                        .rotation3DEffect(
                            flipped ? Angle(degrees: 0) : Angle(degrees: -180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                    
                    // Front of card (Ticket Details)
                    simpleTicketView
                        .opacity(flipped ? 0 : 1)
                        .rotation3DEffect(
                            flipped ? Angle(degrees: 180) : Angle(degrees: 0),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
                .frame(height: 550)
                .padding(.horizontal, 20)
                
                // Transfer ticket text below card
                if !flipped && appState.burnerManager.hasCompletedSetup && ticketWithEvent.ticket.status == "confirmed" {
                    Button(action: {
                        if let ticketId = ticketWithEvent.ticket.id {
                            coordinator.navigate(to: .transferTicket(ticketWithEvent.ticket))
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("TRANSFER TICKET")
                                .font(.custom("Helvetica", size: 14).weight(.bold))
                                .foregroundColor(.white)

                            Image(systemName: "arrow.up.forward")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }

            // Close button (only on details side)
            if !flipped {
                VStack {
                    HStack {
                        Spacer()
                        CloseButton(action: {
                            dismiss()
                        }, isDark: true)
                        .padding(.top, 100)
                        .padding(.trailing, 40)
                    }
                    Spacer()
                }
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
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showBurnerSetup) {
            BurnerModeSetupView(
                burnerManager: appState.burnerManager,
                onSkip: {
                    showBurnerSetup = false
                }
            )
        }
        .onAppear {
            // Pre-generate QR code in background
            Task {
                qrCodeImage = await generateQRCode(from: qrCodeData, size: 300)
            }
            
            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
            updateLiveActivityIfNeeded()

            // Start periodic updates every minute to catch state transitions
            liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                updateLiveActivityIfNeeded()
            }
            
            // Automatically flip to show ticket details after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    flipped = false
                }
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            liveActivityUpdateTimer?.invalidate()
            liveActivityUpdateTimer = nil
        }
    }

    // MARK: - Card Back View (Event Image)
    
    private var cardBackView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Event image with overlay
                ZStack(alignment: .bottom) {
                    KFImage(URL(string: ticketWithEvent.event.imageUrl))
                        .resizable()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    
                    // Gradient overlay for text readability
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Event name overlay
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ticketWithEvent.event.name.uppercased())
                            .font(.custom("Helvetica", size: 24).weight(.bold))
                            .kerning(-1)
                            .foregroundColor(.white)
                        
                        Text(ticketWithEvent.event.venue.uppercased())
                            .font(.custom("Helvetica", size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.vertical, 32)
    }

    // MARK: - Simple Ticket View (Front - Modified to look like a vertical business card)

    private var simpleTicketView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Event Details Section (Left-Aligned Stack)
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

            
            // QR Code Section
            VStack(spacing: 12) {
                if appState.burnerManager.hasCompletedSetup {
                    // QR Code (non-interactive) - use pre-generated image if available
                    if let qrImage = qrCodeImage {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 300, height: 300)
                            .padding(5)
                            .background(.white)
                    } else {
                        // Fallback to original QRCodeView while generating
                        QRCodeView(
                            data: qrCodeData,
                            size: 300,
                            backgroundColor: .black,
                            foregroundColor: .white
                        )
                        .padding(5)
                        .background(.white)
                    }
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
            .padding(.top, 30)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }


    private var qrCodeData: String {
        return ticketWithEvent.ticket.qrCode ?? "INVALID_TICKET"
    }
    
    // Generate QR code asynchronously to avoid main thread blocking
    private func generateQRCode(from string: String, size: CGFloat) async -> UIImage? {
        return await Task.detached(priority: .userInitiated) {
            let data = string.data(using: .utf8)
            guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
            
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel")
            
            guard let ciImage = filter.outputImage else { return nil }
            
            let scale = size / ciImage.extent.width
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let scaledImage = ciImage.transformed(by: transform)
            
            let context = CIContext()
            guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
            
            return UIImage(cgImage: cgImage)
        }.value
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
            startTime: Calendar.current.date(byAdding: .hour, value: 1, to: Date())!,
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
