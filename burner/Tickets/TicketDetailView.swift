import SwiftUI
import Kingfisher
import ActivityKit
import Combine
import FamilyControls

struct TicketDetailView: View {
    let ticketId: String  // Just store the ID, look up current data from ViewModel
    let eventId: String
    var shouldAnimateFlip: Bool = false  // Control flip animation

    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showBurnerSetup = false
    @State private var liveActivityUpdateTimer: Timer?
    @State private var flipped = false  // FIXED: Start with front side (false) by default
    @State private var qrCodeImage: UIImage? = nil

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    // Computed property to get current ticket data from ViewModel (reactive)
    private var currentTicket: Ticket? {
        appState.ticketsViewModel.tickets.first { $0.ticketId == ticketId }
    }

    // Computed property to get current event data
    private var currentEvent: Event? {
        appState.eventViewModel.events.first { $0.id == eventId }
    }

    // Fallback combined data for compatibility
    private var ticketWithEvent: TicketWithEventData? {
        guard let ticket = currentTicket, let event = currentEvent else { return nil }
        return TicketWithEventData(ticket: ticket, event: event)
    }

    private var shouldShowQRCode: Bool {
        appState.burnerManager.burnerSetupCompleted && appState.burnerManager.isAuthorized
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: [.bottom, .top])

            if let ticket = currentTicket, let event = currentEvent {
                VStack(spacing: 24) {
                    ZStack {
                        cardBackView(event: event)
                            .opacity(flipped ? 1 : 0)
                            .rotation3DEffect(
                                flipped ? Angle(degrees: 0) : Angle(degrees: -180),
                                axis: (x: 0, y: 1, z: 0)
                            )

                        simpleTicketView(ticket: ticket, event: event)
                            .opacity(flipped ? 0 : 1)
                            .rotation3DEffect(
                                flipped ? Angle(degrees: 180) : Angle(degrees: 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                    }
                    .frame(height: 550)
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(EmptyView())
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .background(NavigationControllerConfigurator())
        .fullScreenCover(isPresented: $showBurnerSetup) {
            BurnerModeSetupView(
                burnerManager: appState.burnerManager,
                onSkip: {
                    showBurnerSetup = false
                }
            )
        }
        .onAppear {
            appState.syncBurnerModeAuthorization()

            if shouldShowQRCode, let ticket = currentTicket {
                Task {
                    qrCodeImage = await generateQRCode(from: qrCodeData(for: ticket), size: 300)
                }
            }

            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
            updateLiveActivityIfNeeded()

            liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                updateLiveActivityIfNeeded()
            }

            // FIXED: Only animate flip if explicitly requested (after purchase)
            if shouldAnimateFlip {
                // Start with back side for animation
                flipped = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        flipped = false
                    }
                }
            }
            // If shouldAnimateFlip is false, flipped stays false (front side shows immediately)
        }
        .onDisappear {
            liveActivityUpdateTimer?.invalidate()
            liveActivityUpdateTimer = nil
        }
        .onChange(of: appState.burnerManager.burnerSetupCompleted) { oldValue, newValue in
            if newValue && !oldValue && appState.burnerManager.isAuthorized, let ticket = currentTicket {
                Task {
                    qrCodeImage = await generateQRCode(from: qrCodeData(for: ticket), size: 300)
                }
            }
        }
        .onChange(of: appState.burnerManager.isAuthorized) { oldValue, newValue in
            if newValue && !oldValue && appState.burnerManager.burnerSetupCompleted, let ticket = currentTicket {
                Task {
                    qrCodeImage = await generateQRCode(from: qrCodeData(for: ticket), size: 300)
                }
            } else if !newValue {
                qrCodeImage = nil
            }
        }
    }

    @ViewBuilder
    private func cardBackView(event: Event) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    KFImage(URL(string: event.imageUrl))
                        .resizable()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView().tint(.white))
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.vertical, 32)
    }

    @ViewBuilder
    private func simpleTicketView(ticket: Ticket, event: Event) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                CloseButton(action: {
                    coordinator.pop()
                }, isDark: true)
                .padding(.top, 8)
                .padding(.trailing, 22)
            }

            Spacer().frame(height: 12)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name.uppercased())
                        .appFont(size: 20, weight: .bold)
                        .kerning(-1.5)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .padding(.trailing, 40)

                    Text(event.venue.uppercased())
                        .appCard()
                        .foregroundColor(.black)

                    Text("\(formatDateDay(event.startTime ?? Date())) \(formatDateMonth(event.startTime ?? Date())) \(formatDateYear(event.startTime ?? Date()))")
                        .appCard()
                        .foregroundColor(.black)

                    Text(formatTime(event.startTime ?? Date()))
                        .appCard()
                        .foregroundColor(.black)

                    Text(ticket.status.uppercased())
                        .appCard()
                        .foregroundColor(.black)

                    Text(ticket.ticketNumber ?? "N/A")
                        .appCard()
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)

            VStack(spacing: 10) {
                ZStack {
                    if shouldShowQRCode {
                        if let qrImage = qrCodeImage {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 330, height: 330)
                                .background(.white)
                        } else {
                            QRCodeView(
                                data: qrCodeData(for: ticket),
                                size: 330
                            )
                            .background(.white)
                        }
                    } else {
                        Group {
                            if let qrImage = qrCodeImage {
                                Image(uiImage: qrImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 330, height: 330)
                            } else {
                                QRCodeView(
                                    data: qrCodeData(for: ticket),
                                    size: 330
                                )
                            }
                        }
                        .blur(radius: 20)
                        .background(.white)

                        Button(action: {
                            showBurnerSetup = true
                        }) {
                            Text("COMPLETE SETUP")
                                .appMonospaced(size: 16, weight: .bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(width: 330, height: 330)
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

    private func qrCodeData(for ticket: Ticket) -> String {
        return ticket.qrCode ?? "INVALID_TICKET"
    }

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

    private var shouldShowLiveActivityInfo: Bool {
        guard let ticket = currentTicket, let event = currentEvent else { return false }
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(event.startTime ?? Date(), inSameDayAs: now)
        let isTomorrow = calendar.isDate(event.startTime ?? Date(), inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)

        return (isToday || isTomorrow) && ticket.status == "confirmed"
    }

    private var isEventToday: Bool {
        guard let event = currentEvent else { return false }
        return Calendar.current.isDate(event.startTime ?? Date(), inSameDayAs: Date())
    }

    private func autoStartLiveActivityForEventDay() {
        guard let ticket = currentTicket, let event = currentEvent else { return }
        guard isEventToday && ticket.status == "confirmed" else {
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
            activity.attributes.eventName == event.name &&
            Calendar.current.isDate(activity.attributes.startTime, inSameDayAs: event.startTime ?? Date())
        }

        if existingActivity != nil {
            hasStartedLiveActivity = true
            return
        }

        if let ticketWithEvent = ticketWithEvent {
            TicketLiveActivityManager.startLiveActivity(for: ticketWithEvent)
        }
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
        guard let event = currentEvent else { return }
        guard #available(iOS 16.1, *) else { return }

        let hasActiveActivity = Activity<TicketActivityAttributes>.activities.contains { activity in
            activity.attributes.eventName == event.name &&
            Calendar.current.isDate(activity.attributes.startTime, inSameDayAs: event.startTime ?? Date())
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            isLiveActivityActive = hasActiveActivity
        }
    }
}

struct NavigationControllerConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let navigationController = uiViewController.navigationController {
                navigationController.interactivePopGestureRecognizer?.isEnabled = true
                navigationController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
}
