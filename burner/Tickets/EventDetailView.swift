import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit
import MapKit
import UIKit

struct EventDetailView: View {
    let event: Event
    var source: EventSource? = nil
    var namespace: Namespace.ID?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState

    @State private var userHasTicket = false
    @State private var showingSignInAlert = false
    @State private var showingMapsSheet = false
    @State private var isDescriptionExpanded = false
    @State private var needsReadMore = false
    @State private var scrollOffset: CGFloat = 0
    
    // Simplified hero height calculation
    private var heroHeight: CGFloat {
        UIScreen.main.bounds.height * 0.5 // 50% of screen height
    }

    // Helper to determine the correct hero ID based on source
    private func heroImageId(for source: EventSource) -> String {
        switch source {
        case .featuredCard:
            return "heroImage-featured-\(event.id ?? "")"
        case .listRow:
            return "heroImage-row-\(event.id ?? "")"
        }
    }

    var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }

    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }

    private var userTicket: Ticket? {
        guard let eventId = event.id else { return nil }
        return ticketsViewModel.tickets.first { $0.eventId == eventId }
    }

    // Check if event has started
    private var hasEventStarted: Bool {
        guard let startTime = event.startTime else { return false }
        return Date() >= startTime
    }

    // Check if event is past (event ended)
    private var isEventPast: Bool {
        guard let endTime = event.endTime else {
            guard let startTime = event.startTime else { return false }
            let sixHoursAfterStart = Calendar.current.date(byAdding: .hour, value: 6, to: startTime) ?? startTime
            return Date() > sixHoursAfterStart
        }
        return Date() > endTime
    }

    var buttonText: String {
        if isEventPast {
            return "EVENT PAST"
        } else if hasEventStarted {
            return "EVENT STARTED"
        } else if userHasTicket {
            return "TICKET PURCHASED"
        } else if availableTickets > 0 {
            return "GET TICKET"
        } else {
            return "SOLD OUT"
        }
    }

    var buttonColor: Color {
        if isEventPast || hasEventStarted {
            return .gray
        } else if userHasTicket {
            return .gray
        } else if availableTickets > 0 {
            return .white
        } else {
            return .red
        }
    }

    var buttonTextColor: Color {
        if isEventPast || hasEventStarted {
            return .white
        } else if userHasTicket {
            return .white
        } else if availableTickets > 0 {
            return .black
        } else {
            return .white
        }
    }

    var isButtonDisabled: Bool {
        isEventPast || hasEventStarted || userHasTicket || availableTickets == 0
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("detailScroll")).minY
                        )
                }
                .frame(height: 0)

                heroHeader

                detailContent
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
            .coordinateSpace(name: "detailScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = max(0, -value)
            }

            heroTopBar

            if showingSignInAlert {
                CustomAlertView(
                    title: "Sign In Required",
                    description: "You need to be signed in to purchase tickets.",
                    cancelAction: {
                        showingSignInAlert = false
                    },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showingSignInAlert = false
                        coordinator.showSignIn()
                    },
                    primaryActionTitle: "Sign In",
                    primaryActionColor: .white,
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1002)
            }
        }
        .safeAreaInset(edge: .bottom) {
            purchaseButtonArea
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingMapsSheet) {
            if let coordinates = event.coordinates {
                MapsOptionsSheet(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude,
                    venueName: event.venue
                )
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            coordinator.hideTabBar()
            checkUserTicketStatus()
        }
        .onDisappear {
            coordinator.showTabBar()
        }
        .onChange(of: ticketsViewModel.tickets.count) { _, _ in
            checkUserTicketStatus()
        }
        .onChange(of: event.ticketsSold) { _, _ in
            checkUserTicketStatus()
        }
        .onReceive(eventViewModel.$errorMessage) { errorMessage in
            if let errorMessage = errorMessage {
                coordinator.showError(title: "Error", message: errorMessage)
                eventViewModel.clearMessages()
            }
        }
        .onReceive(eventViewModel.$successMessage) { successMessage in
            if let successMessage = successMessage {
                coordinator.showSuccess(title: "Success", message: successMessage)
                eventViewModel.clearMessages()
                checkUserTicketStatus()
            }
        }
    }
    
    // MARK: - Hero Header
    private var heroHeader: some View {
        GeometryReader { geometry in
            let minY = geometry.frame(in: .named("detailScroll")).minY
            let pullDownOffset = max(0, minY)
            let width = geometry.size.width

            ZStack(alignment: .bottomLeading) {
                heroImageView(width: width, pullDownOffset: pullDownOffset)

                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.85)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(event.name)
                        .appHero()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    if let startTime = event.startTime {
                        Text("\(startTime.formatted(.dateTime.weekday(.wide).day().month())) • \(event.venue)")
                            .appBody()
                            .foregroundColor(.white.opacity(0.85))
                    } else {
                        Text(event.venue)
                            .appBody()
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .frame(width: width, height: heroHeight + pullDownOffset)
            .offset(y: minY > 0 ? -minY : 0)
            .clipped()
        }
        .frame(height: heroHeight)
    }

    private func heroImageView(width: CGFloat, pullDownOffset: CGFloat) -> some View {
        Group {
            if let url = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                KFImage(url)
                    .placeholder {
                        Color.gray.opacity(0.3)
                            .overlay(
                                Image(systemName: "music.note")
                                    .appHero()
                                    .foregroundColor(.gray)
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: heroHeight + pullDownOffset)
                    .clipped()
            } else {
                Color.gray.opacity(0.3)
                    .overlay(
                        Image(systemName: "music.note")
                            .appHero()
                            .foregroundColor(.gray)
                    )
                    .frame(width: width, height: heroHeight + pullDownOffset)
            }
        }
        .modifier(HeroImageModifier(namespace: namespace, source: source, heroImageId: heroImageId))
    }

    // MARK: - Detail Content
    private var detailContent: some View {
        VStack(spacing: 16) {
            if let description = event.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .appBody()
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(description)
                            .appBody()
                            .foregroundColor(.gray)
                            .lineSpacing(2)
                            .lineLimit(isDescriptionExpanded ? nil : 6)
                            .background(
                                GeometryReader { textGeometry in
                                    Color.clear
                                        .onAppear {
                                            let textSize = description.boundingRect(
                                                with: CGSize(
                                                    width: textGeometry.size.width,
                                                    height: .greatestFiniteMagnitude
                                                ),
                                                options: .usesLineFragmentOrigin,
                                                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                                                context: nil
                                            )
                                            let lineHeight: CGFloat = 20
                                            let maxHeight = lineHeight * 6
                                            needsReadMore = textSize.height > maxHeight
                                        }
                                }
                            )
                            .animation(.easeInOut, value: isDescriptionExpanded)

                        if needsReadMore {
                            Button(action: {
                                withAnimation {
                                    isDescriptionExpanded.toggle()
                                }
                            }) {
                                Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                    .appCaption()
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            }

            VStack(spacing: 12) {
                Text("Event Details")
                    .appBody()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    EventDetailRow(
                        icon: "calendar",
                        title: "Date",
                        value: (event.startTime ?? Date()).formatted(.dateTime.weekday(.abbreviated).day().month().year())
                    )

                    EventDetailRow(
                        icon: "clock",
                        title: "Time",
                        value: formatTimeRange()
                    )

                    EventDetailRow(
                        icon: "location",
                        title: "Venue",
                        value: event.venue
                    )

                    EventDetailRow(
                        icon: "creditcard",
                        title: "Price",
                        value: "£\(String(format: "%.2f", event.price))"
                    )

                    if let tags = event.tags, !tags.isEmpty {
                        EventDetailRow(
                            icon: "tag",
                            title: "Genre",
                            value: tags.joined(separator: ", ")
                        )
                    }
                }
            }
            .padding(.horizontal, 20)

            if let coordinates = event.coordinates {
                Button(action: {
                    showingMapsSheet = true
                }) {
                    EventMapView(
                        coordinate: CLLocationCoordinate2D(
                            latitude: coordinates.latitude,
                            longitude: coordinates.longitude
                        ),
                        venueName: event.venue
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            HStack(spacing: 12) {
                Button(action: {
                    if Auth.auth().currentUser == nil {
                        showingSignInAlert = true
                    } else {
                        Task {
                            await bookmarkManager.toggleBookmark(for: event)
                        }
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .appCard()
                        .foregroundColor(.white)
                        .iconButtonStyle(
                            size: 60,
                            backgroundColor: Color.white.opacity(0.1),
                            cornerRadius: 12
                        )
                }

                Button(action: {
                    coordinator.shareEvent(event)
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .appCard()
                        .foregroundColor(.white)
                        .iconButtonStyle(
                            size: 60,
                            backgroundColor: Color.white.opacity(0.1),
                            cornerRadius: 12
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Top Bar
    private var heroTopBar: some View {
        let backgroundOpacity = min(max(scrollOffset / (heroHeight * 0.75), 0), 1)

        return HStack(spacing: 12) {
            HeroControlButton(systemName: "chevron.left") {
                dismiss()
            }

            Spacer()

            HeroControlButton(systemName: "square.and.arrow.up") {
                coordinator.shareEvent(event)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, topSafeAreaInset + 8)
        .padding(.bottom, 12)
        .background(
            Color.black.opacity(Double(backgroundOpacity))
                .ignoresSafeArea(edges: .top)
        )
    }

    private var topSafeAreaInset: CGFloat {
        UIApplication.shared.firstKeyWindow?.safeAreaInsets.top ?? 0
    }

    // MARK: - Purchase Button Area
    private var purchaseButtonArea: some View {
        VStack(spacing: 0) {
            Button(action: {
                if userHasTicket {
                    return
                } else if availableTickets > 0 {
                    if Auth.auth().currentUser == nil {
                        showingSignInAlert = true
                    } else {
                        coordinator.purchaseTicket(for: event)
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Text(buttonText)
                        .font(.appFont(size: 17))
                }
                .foregroundColor(buttonTextColor)
                .primaryButtonStyle(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    borderColor: Color.white.opacity(0.2)
                )
            }
            .disabled(isButtonDisabled)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.85),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func checkUserTicketStatus() {
        guard let eventId = event.id else { return }

        eventViewModel.checkUserTicketStatus(for: eventId) { hasTicket in
            DispatchQueue.main.async {
                self.userHasTicket = hasTicket
            }
        }
    }
    
    private func formatTimeRange() -> String {
        guard let startTime = event.startTime else {
            return "TBA"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let startTimeString = timeFormatter.string(from: startTime)
        
        if let endTime = event.endTime {
            let endTimeString = timeFormatter.string(from: endTime)
            return "\(startTimeString) - \(endTimeString)"
        } else {
            return startTimeString
        }
    }
}

// ... rest of the code remains the same (EventDetailRow, EventMapView, etc.)

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}


// MARK: - Event Detail Row - More compact
struct EventDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.appIcon)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appSecondary()
                    .foregroundColor(.gray)
                
                Text(value)
                    .appBody()
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Event Map View
struct EventMapView: View {
    let coordinate: CLLocationCoordinate2D
    let venueName: String
    
    @State private var region: MKCoordinateRegion

    init(coordinate: CLLocationCoordinate2D, venueName: String) {
        self.coordinate = coordinate
        self.venueName = venueName
        _region = State(initialValue: MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(position: .constant(.region(region)), interactionModes: []) {
            Marker(venueName, coordinate: coordinate)
        }
        .mapStyle(.standard)
    }
}

// MARK: - Maps Options Sheet
struct MapsOptionsSheet: View {
    let latitude: Double
    let longitude: Double
    let venueName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Open in Maps")
                .appBody()
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top, 30)
                .padding(.bottom, 16)

            VStack(spacing: 12) {
                Button(action: {
                    openInAppleMaps()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "map")
                            .appCard()
                        Text("Apple Maps")
                            .appBody()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appSecondary()
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    openInGoogleMaps()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .appCard()
                        Text("Google Maps")
                            .appBody()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appSecondary()
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.black)
    }

    private func openInAppleMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
        mapItem.name = venueName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func openInGoogleMaps() {
        if let url = URL(string: "comgooglemaps://?q=\(latitude),\(longitude)&center=\(latitude),\(longitude)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                // Fallback to web version if Google Maps app is not installed
                if let webUrl = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
}

// MARK: - Hero Image Modifier
struct HeroImageModifier: ViewModifier {
    let namespace: Namespace.ID?
    let source: EventSource?
    let heroImageId: (EventSource) -> String

    func body(content: Content) -> some View {
        if let namespace = namespace, let source = source {
            content.matchedGeometryEffect(
                id: heroImageId(source),
                in: namespace,
                isSource: false
            )
        } else {
            content
        }
    }
}

// MARK: - Hero Control Button
private struct HeroControlButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private extension UIApplication {
    var firstKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
