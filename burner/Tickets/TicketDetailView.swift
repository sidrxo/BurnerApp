import SwiftUI
import Kingfisher
import ActivityKit
import FirebaseFunctions
import Combine
import FamilyControls

struct TicketDetailView: View {
    let ticketWithEvent: TicketWithEventData

    @State private var hasStartedLiveActivity = false
    @State private var isLiveActivityActive = false
    @State private var showTransferSuccess = false
    @State private var showBurnerSetup = false
    @State private var liveActivityUpdateTimer: Timer?
    @State private var flipped = true
    @State private var qrCodeImage: UIImage? = nil

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @Environment(\.dismiss) private var dismiss

    private var shouldShowQRCode: Bool {
        appState.burnerManager.burnerSetupCompleted && appState.burnerManager.isAuthorized
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea(edges: [.bottom, .top])

            VStack(spacing: 24) {
                ZStack {
                    cardBackView
                        .opacity(flipped ? 1 : 0)
                        .rotation3DEffect(
                            flipped ? Angle(degrees: 0) : Angle(degrees: -180),
                            axis: (x: 0, y: 1, z: 0)
                        )

                    ScreenshotProtect {
                        simpleTicketView
                    }
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

            if showTransferSuccess {
                CustomAlertView(
                    title: "Transfer Successful",
                    description: "Ticket has been transferred successfully! ",
                    primaryAction: { showTransferSuccess = false },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
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

            if shouldShowQRCode {
                Task {
                    qrCodeImage = await generateQRCode(from: qrCodeData, size: 300)
                }
            }

            autoStartLiveActivityForEventDay()
            checkLiveActivityStatus()
            updateLiveActivityIfNeeded()

            liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                updateLiveActivityIfNeeded()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    flipped = false
                }
            }
        }
        .onDisappear {
            liveActivityUpdateTimer?.invalidate()
            liveActivityUpdateTimer = nil
        }
        .onChange(of: appState.burnerManager.burnerSetupCompleted) { oldValue, newValue in
            if newValue && !oldValue && appState.burnerManager.isAuthorized {
                Task {
                    qrCodeImage = await generateQRCode(from: qrCodeData, size: 300)
                }
            }
        }
        .onChange(of: appState.burnerManager.isAuthorized) { oldValue, newValue in
            if newValue && !oldValue && appState.burnerManager.burnerSetupCompleted {
                Task {
                    qrCodeImage = await generateQRCode(from: qrCodeData, size: 300)
                }
            } else if !newValue {
                qrCodeImage = nil
            }
        }
    }

    private var cardBackView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    KFImage(URL(string: ticketWithEvent.event.imageUrl))
                        .resizable()
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(ProgressView().tint(.white))
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()

                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text(ticketWithEvent.event.name.uppercased())
                            .appSectionHeader()
                            .kerning(-1)
                            .foregroundColor(.white)

                        Text(ticketWithEvent.event.venue.uppercased())
                            .appSecondary()
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

    private var simpleTicketView: some View {
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
                    Text(ticketWithEvent.event.name.uppercased())
                        .appFont(size: 20, weight: .bold)
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
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)

            VStack(spacing: 10) {
                ZStack {
                    if shouldShowQRCode {
                        if let qrImage = qrCodeImage {
                            Image(uiImage: qrImage)
                                .resizable()
                                .interpolation(.none)
                                .frame(width: 320, height: 320)
                                .background(.white)
                        } else {
                            QRCodeView(
                                data: qrCodeData,
                                size: 320
                            )
                            .background(.white)
                        }
                    } else {
                        Group {
                            if let qrImage = qrCodeImage {
                                Image(uiImage: qrImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 320, height: 320)
                            } else {
                                QRCodeView(
                                    data: qrCodeData,
                                    size: 320
                                )
                            }
                        }
                        .blur(radius: 20)
                        .background(.white)

                        Button(action: {
                            showBurnerSetup = true
                        }) {
                            Text("COMPLETE SETUP")
                                .appFont(size: 15, weight: .bold)
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
                .frame(width: 320, height: 320)

                if shouldShowQRCode && ticketWithEvent.ticket.status == "confirmed" {
                    Button(action: {
                        if ticketWithEvent.ticket.id != nil {
                            coordinator.navigate(to: .transferTicket(ticketWithEvent.ticket))
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text("TRANSFER TICKET")
                                .appSecondary(weight: .bold)
                                .foregroundColor(.black)

                            Image(systemName: "arrow.up.forward")
                                .appSecondary(weight: .bold)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top, 2)
                    .buttonStyle(PlainButtonStyle())
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
        let calendar = Calendar.current
        let now = Date()
        let isToday = calendar.isDate(ticketWithEvent.event.startTime ?? Date(), inSameDayAs: now)
        let isTomorrow = calendar.isDate(ticketWithEvent.event.startTime ?? Date(), inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now)

        return (isToday || isTomorrow) && ticketWithEvent.ticket.status == "confirmed"
    }

    private var isEventToday: Bool {
        Calendar.current.isDate(ticketWithEvent.event.startTime ?? Date(), inSameDayAs: Date())
    }

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
