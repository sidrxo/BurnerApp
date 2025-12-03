import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit
import MapKit
import CoreLocation



struct EventDetailView: View {
    let event: Event // Event must conform to Identifiable and contain all required properties
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
    
    // MARK: - Animation & Performance State
    @State private var didAppear = false
    @State private var mapReady = false       // Lazy load map
    @State private var interactionEnabled = false // Lock interaction during transition
    @State private var dismissalEnabled = false  // Lock dismissal separately from interaction

    private let screenHeight = UIScreen.main.bounds.height

    private var heroHeight: CGFloat {
        let calculatedHeight = screenHeight * 0.50
        return max(350, min(calculatedHeight, 550))
    }

    // Assumes Event has maxTickets and ticketsSold properties
    var availableTickets: Int {
        max(0, event.maxTickets - event.ticketsSold)
    }

    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }

    // Assumes Ticket has eventId property
    private var userTicket: Ticket? {
        guard let eventId = event.id else { return nil }
        return ticketsViewModel.tickets.first { $0.eventId == eventId }
    }

    // Assumes Event has startTime property
    private var hasEventStarted: Bool {
        guard let startTime = event.startTime else { return false }
        return Date() >= startTime
    }

    // Assumes Event has startTime and endTime properties
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

    // Determine the style and custom color based on status
    private var buttonStatus: (style: BurnerButton.Style, color: Color?) {
        if availableTickets > 0 && !isEventPast && !hasEventStarted && !userHasTicket {
            // Active 'GET TICKET' state (Primary is solid white background)
            return (.primary, nil)
        } else if availableTickets == 0 && !isEventPast && !hasEventStarted {
            // 'SOLD OUT' state (Dimmed, Red outline/text)
            return (.dimmed, .red)
        } else if userHasTicket && !isEventPast && !hasEventStarted {
            // 'TICKET PURCHASED' state (Dimmed, White outline/text)
            return (.dimmed, .white)
        } else {
            // Default inactive/past state (Dimmed, Gray outline/text)
            return (.dimmed, .gray)
        }
    }

    private var isButtonDisabled: Bool {
        isEventPast || hasEventStarted || userHasTicket || availableTickets == 0
    }

    // Assumes Event has startTime property
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
                        // PERFORMANCE: Heavy blurred background delayed until appearance
                        if didAppear {
                            KFImage(URL(string: event.imageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width,
                                       height: heroHeight * 0.9)
                                .clipped()
                                .blur(radius: 40)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                        
                        VStack(spacing: 0) {
                            // Hero card (Anchor for Zoom Transition)
                            KFImage(URL(string: event.imageUrl))
                                .placeholder {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .appHero() // Custom View Extension
                                                .foregroundColor(.gray)
                                        )
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: max(0, geometry.size.width - 32),
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
                                .zIndex(100) // Keep image on top of text for transition

                            // Content Container
                            VStack(spacing: 0) {
                                HStack(alignment: .center, spacing: 12) {
                                    Text(event.name)
                                        .appHero() // Custom View Extension
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
                                            Image(systemName: isBookmarked ? "heart.fill" : "heart")
                                                .appSectionHeader() // Custom View Extension
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(IconButton(size: 60, backgroundColor: Color.white.opacity(0.1), cornerRadius: 10))

                                        Button(action: {
                                            coordinator.shareEvent(event)
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .appSectionHeader() // Custom View Extension
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(IconButton(size: 60, backgroundColor: Color.white.opacity(0.1), cornerRadius: 10))
                                    }
                                }
                                .padding(.bottom, 24)
                                .padding(.horizontal, 20)


                                // Content Section
                                VStack(spacing: 16) {
                                    if let description = event.description, !description.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("About")
                                                .appBody() // Custom View Extension
                                                .foregroundColor(.white)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(description)
                                                    .appBody() // Custom View Extension
                                                    .foregroundColor(.gray)
                                                    .lineSpacing(2)
                                                    .lineLimit(isDescriptionExpanded ? nil : 6)
                                                    .background(
                                                        GeometryReader { textGeometry in
                                                            Color.clear
                                                                .onAppear {
                                                                    // The text size calculation relies on UIKit/Font details
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
                                                            .appCaption() // Custom View Extension
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
                                            .appBody() // Custom View Extension
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

                                    // Map section - PERFORMANCE: Lazy Loaded
                                    if let coordinates = event.coordinates {
                                        if mapReady {
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
                                            .transition(.opacity)
                                        } else {
                                            // Lightweight placeholder
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white.opacity(0.05))
                                                .frame(height: 200)
                                                .padding(.horizontal, 20)
                                                .padding(.top, 8)
                                        }
                                    }
                                    Spacer(minLength: 100)
                                }
                            }
                            // Visual: Initially hidden, slides up and fades in
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: didAppear ? 0 : 40)
                            .zIndex(1) // Keep content below image layer
                        }
                    }
                }

                // Close button
                VStack {
                    HStack {
                        Spacer()
                        CloseButton(action: { // Custom View
                            dismiss()
                        }, isDark: true)
                        .padding(.top, 80)
                        .padding(.trailing, 30)
                        .opacity(didAppear ? 1 : 0)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)


                // Bottom ticket button
                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        BurnerButton(
                            buttonText,
                            style: buttonStatus.style,
                            maxWidth: .infinity,
                            customColor: buttonStatus.color // Pass color for .dimmed style
                        ) {
                            if userHasTicket {
                                // already have ticket - do nothing or show ticket
                            } else if availableTickets > 0 {
                                if Auth.auth().currentUser == nil {
                                    showingSignInAlert = true
                                } else {
                                    coordinator.purchaseTicket(for: event)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isButtonDisabled)
                        // Opacity control is handled inside the DimmedOutlineButtonStyle
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
                    .opacity(didAppear ? 1 : 0)
                    .offset(y: didAppear ? 0 : 50)
                }

                if showingSignInAlert {
                    CustomAlertView( // Custom View
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
        .if(namespace != nil && event.id != nil) { view in // Custom View Extension
            view.navigationTransition(.zoom(sourceID: "heroImage-\(event.id!)", in: namespace!)) // Custom Transition
        }
        .interactiveDismissDisabled(!dismissalEnabled)
        .sheet(isPresented: $showingMapsSheet) {
            if let coordinates = event.coordinates {
                MapsOptionsSheet( // Custom View
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude,
                    venueName: event.venue
                )
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            }
        }
        // PERFORMANCE: Freeze interaction during entrance transition
        .allowsHitTesting(interactionEnabled)
        .interactiveDismissDisabled(!dismissalEnabled)
        .onAppear {
            checkUserTicketStatus()
            
            // 1. Trigger Visual Animations (Text/Buttons fade in)
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                didAppear = true
            }
            
            // 2. Quick interaction unlock (0.2s) - user can scroll and interact
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                interactionEnabled = true
            }
            
            // 3. Delayed dismissal unlock (0.6s) - prevents accidental back navigation during transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismissalEnabled = true
                // Also load map after user can interact
                withAnimation {
                    mapReady = true
                }
            }
        }
        // Assumes TicketsViewModel publishes changes to tickets
        .onChange(of: ticketsViewModel.tickets.count) { _, _ in
            checkUserTicketStatus()
        }
        // Assumes Event is observable or updates trigger a view refresh
        .onChange(of: event.ticketsSold) { _, _ in
            checkUserTicketStatus()
        }
        // Assumes EventViewModel publishes error/success messages
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

        // Assumes EventViewModel has this method
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

    // Unused, but kept for completeness
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

    // Unused, but kept for completeness
    private func generateShareURL() -> URL {
        guard let eventId = event.id else {
            return URL(string: "burner://events")!
        }
        return URL(string: "burner://event/\(eventId)")!
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
                .font(.appIcon) // Custom Font Extension
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .appSecondary() // Custom View Extension
                    .foregroundColor(.gray)

                Text(value)
                    .appBody() // Custom View Extension
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
