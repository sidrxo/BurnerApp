import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit
import MapKit

struct EventDetailView: View {
    let event: Event
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

    private let screenHeight = UIScreen.main.bounds.height

    private var heroHeight: CGFloat {
        let calculatedHeight = screenHeight * 0.50
        return max(350, min(calculatedHeight, 550))
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

    private var hasEventStarted: Bool {
        guard let startTime = event.startTime else { return false }
        return Date() >= startTime
    }

    private var isEventPast: Bool {
        guard let endTime = event.endTime else {
            guard let startTime = event.startTime else { return false }
            let sixHoursAfterStart = Calendar.current.date(byAdding: .hour, value: 6, to: startTime) ?? startTime
            return Date() > sixHoursAfterStart
        }
        return Date() > endTime
    }

    private var buttonText: String {
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

    private var buttonColor: Color {
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

    private var buttonTextColor: Color {
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

    private var isButtonDisabled: Bool {
        isEventPast || hasEventStarted || userHasTicket || availableTickets == 0
    }

    private var headerDateString: String {
        guard let startTime = event.startTime else { return "TBA" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E d MMM"
        let datePart = dateFormatter.string(from: startTime)

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timePart = timeFormatter.string(from: startTime)

        return "\(datePart) at \(timePart)"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base black background
                Color.black.ignoresSafeArea()

                // Scrollable content
                ScrollView {
                    ZStack(alignment: .top) {
                        // Image-based gradient background (scrolls with content)
                        KFImage(URL(string: event.imageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width,
                                   height: heroHeight * 0.9) // Increased from 0.7 to 0.9
                            .clipped()
                            .blur(radius: 40)
                            .allowsHitTesting(false)
                        
                        VStack(spacing: 0) {
                            // Hero card
                            KFImage(URL(string: event.imageUrl))
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .appHero()
                                                .foregroundColor(.gray)
                                        )
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: max(0, geometry.size.width - 32), // avoid negative width
                                    height: heroHeight
                                )
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .shadow(radius: 18, y: 10)
                                .padding(.top, 24)
                                .padding(.bottom, 28)

                            HStack(alignment: .center, spacing: 12) {
                                Text(event.name)
                                    .appHero()
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 10) {
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
                                            .appSectionHeader()
                                            .foregroundColor(.white)
                                            .iconButtonStyle(
                                                size: 60,
                                                backgroundColor: Color.white.opacity(0.1),
                                                cornerRadius: 10
                                            )
                                    }

                                    Button(action: {
                                        coordinator.shareEvent(event)
                                    }) {
                                        Image(systemName: "square.and.arrow.up")
                                            .appSectionHeader()
                                            .foregroundColor(.white)
                                            .iconButtonStyle(
                                                size: 60,
                                                backgroundColor: Color.white.opacity(0.1),
                                                cornerRadius: 10
                                            )
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                            .padding(.horizontal, 20)


                            // Content Section
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
                                    .padding(.bottom, 8)
                                }

                                // Event details
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

                                // Map section
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
                                Spacer(minLength: 100)
                            }
                        }
                    }
                }

                // Fixed close button on top-right — updated to use CloseButton
                VStack {
                    HStack {
                        Spacer()
                        CloseButtonDark {
                            dismiss()
                        }
                        .padding(.top, 80)
                        .padding(.trailing, 30)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)


                // Bottom ticket button
                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        Button(action: {
                            if userHasTicket {
                                // already have ticket
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
                        .padding(.bottom, 20)
                        .padding(.top, 40)
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.7),
                                Color.black
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                // Sign-in alert
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
        }
        .navigationBarHidden(true)
        .if(namespace != nil && event.id != nil) { view in
            view.navigationTransition(.zoom(sourceID: "heroImage-\(event.id!)", in: namespace!))
        }
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
            checkUserTicketStatus()
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

    private func generateShareText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = event.startTime.map { dateFormatter.string(from: $0) } ?? "TBA"

        return """
        Check out this event on Burner!

        \(event.name)
        \(event.venue)
        \(dateString)

        £\(String(format: "%.2f", event.price))
        """
    }

    private func generateShareURL() -> URL {
        guard let eventId = event.id else {
            return URL(string: "burner://events")!
        }
        return URL(string: "burner://event/\(eventId)")!
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Event Detail Row
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



