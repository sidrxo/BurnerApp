import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit
import MapKit
import CoreLocation

struct EventDetailView: View {
    // CHANGE 1: Store event ID instead of event object
    let eventId: String
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
    @State private var mapReady = false
    @State private var interactionEnabled = false
    @State private var dismissalEnabled = false

    private let screenHeight = UIScreen.main.bounds.height

    private var heroHeight: CGFloat {
        let calculatedHeight = screenHeight * 0.50
        return max(350, min(calculatedHeight, 550))
    }
    
    // CHANGE 2: Compute event from eventViewModel (live updates!)
    private var event: Event? {
        eventViewModel.events.first { $0.id == eventId }
    }

    var availableTickets: Int {
        guard let event = event else { return 0 }
        return max(0, event.maxTickets - event.ticketsSold)
    }

    private var isBookmarked: Bool {
        bookmarkManager.isBookmarked(eventId)
    }

    private var userTicket: Ticket? {
        ticketsViewModel.tickets.first { $0.eventId == eventId }
    }

    private var hasEventStarted: Bool {
        guard let event = event, let startTime = event.startTime else { return false }
        return Date() >= startTime
    }

    private var isEventPast: Bool {
        guard let event = event else { return false }
        
        if let endTime = event.endTime {
            return Date() > endTime
        }
        
        guard let startTime = event.startTime else { return false }
        let sixHoursAfterStart = Calendar.current.date(byAdding: .hour, value: 6, to: startTime) ?? startTime
        return Date() > sixHoursAfterStart
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

    private var buttonStatus: (style: BurnerButton.Style, color: Color?) {
        if availableTickets > 0 && !isEventPast && !hasEventStarted && !userHasTicket {
            return (.primary, nil)
        } else if availableTickets == 0 && !isEventPast && !hasEventStarted {
            return (.dimmed, .red)
        } else if userHasTicket && !isEventPast && !hasEventStarted {
            return (.dimmed, .white)
        } else {
            return (.dimmed, .gray)
        }
    }

    private var isButtonDisabled: Bool {
        isEventPast || hasEventStarted || userHasTicket || availableTickets == 0
    }

    private var headerDateString: String {
        guard let event = event, let startTime = event.startTime else { return "TBA" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E d MMM"
        let datePart = dateFormatter.string(from: startTime)

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let timePart = timeFormatter.string(from: startTime)

        return "\(datePart) at \(timePart)"
    }

    var body: some View {
        Group {
            if let event = event {
                eventDetailContent(event: event)
            } else {
                // Show loading state if event not found in viewModel
                loadingView
            }
        }
        .navigationBarHidden(true)
        .if(namespace != nil) { view in
            view.navigationTransition(.zoom(sourceID: "heroImage-\(eventId)", in: namespace!))
        }
        .interactiveDismissDisabled(!dismissalEnabled)
        .sheet(isPresented: $showingMapsSheet) {
            if let event = event, let coordinates = event.coordinates {
                MapsOptionsSheet(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude,
                    venueName: event.venue
                )
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                
                Text("Loading event...")
                    .appBody()
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Event Detail Content
    @ViewBuilder
    private func eventDetailContent(event: Event) -> some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    ZStack(alignment: .top) {
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
                                .zIndex(100)

                            VStack(spacing: 0) {
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
                                            Image(systemName: isBookmarked ? "heart.fill" : "heart")
                                                .appSectionHeader()
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(IconButton(size: 60, backgroundColor: Color.white.opacity(0.1), cornerRadius: 10))

                                        Button(action: {
                                            coordinator.shareEvent(event)
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                                .appSectionHeader()
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(IconButton(size: 60, backgroundColor: Color.white.opacity(0.1), cornerRadius: 10))
                                    }

                                        Menu {
                                            Button(action: {
                                                coordinator.shareEvent(event)
                                            }) {
                                                Label("Share Event", systemImage: "square.and.arrow.up")
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(width: 48, height: 48)
                                                Image(systemName: "ellipsis")
                                                    .foregroundColor(.white)
                                                    .font(.appIcon)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)

                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)

                                    Text(headerDateString)
                                        .appSecondary()
                                        .foregroundColor(.gray)

                                    Text("•")
                                        .appSecondary()
                                        .foregroundColor(.gray.opacity(0.5))

                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)

                                    Text(event.venue)
                                        .appSecondary()
                                        .foregroundColor(.gray)

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 18)

                                VStack(spacing: 14) {
                                    EventDetailRow(
                                        icon: "clock.fill",
                                        title: "Time",
                                        value: formatTimeRange(event: event)
                                    )

                                    EventDetailRow(
                                        icon: "mappin.circle.fill",
                                        title: "Location",
                                        value: event.venue
                                    )

                                    EventDetailRow(
                                        icon: "ticket.fill",
                                        title: "Tickets Available",
                                        value: "\(availableTickets) / \(event.maxTickets)"
                                    )

                                    EventDetailRow(
                                        icon: "dollarsign.circle.fill",
                                        title: "Price",
                                        value: event.price != nil ? "$\(String(format: "%.2f", event.price))" : "FREE"
                                    )
                                }
                                .padding(.horizontal, 20)

                                if let description = event.description, !description.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("About")
                                            .appSectionHeader()
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                        Text(description)
                                            .appBody()
                                            .foregroundColor(.gray)
                                            .lineLimit(isDescriptionExpanded ? nil : 6)
                                            .background(
                                                GeometryReader { proxy in
                                                    Color.clear.onAppear {
                                                        let size = proxy.size
                                                        let lineHeight: CGFloat = 22
                                                        let lines = Int(size.height / lineHeight)
                                                        needsReadMore = lines > 6
                                                    }
                                                }
                                            )

                                        if needsReadMore {
                                            Button(action: {
                                                withAnimation {
                                                    isDescriptionExpanded.toggle()
                                                }
                                            }) {
                                                Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                                    .appSecondary()
                                                    .foregroundColor(.white)
                                                    .padding(.top, 4)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                }

                                if let coordinates = event.coordinates {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Location")
                                            .appSectionHeader()
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal, 20)

                                        if mapReady {
                                            EventMapView(
                                                coordinate: CLLocationCoordinate2D(
                                                    latitude: coordinates.latitude,
                                                    longitude: coordinates.longitude
                                                ),
                                                venueName: event.venue
                                            )
                                            .frame(height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .padding(.horizontal, 20)
                                            .onTapGesture {
                                                showingMapsSheet = true
                                            }
                                            .transition(.opacity)
                                        } else {
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
                            .opacity(didAppear ? 1 : 0)
                            .offset(y: didAppear ? 0 : 40)
                            .zIndex(1)
                        }
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        CloseButton(action: {
                            dismiss()
                        }, isDark: true)
                        .padding(.top, 80)
                        .padding(.trailing, 30)
                        .opacity(didAppear ? 1 : 0)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)

                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        BurnerButton(
                            buttonText,
                            style: buttonStatus.style,
                            maxWidth: .infinity,
                            customColor: buttonStatus.color
                        ) {
                            if userHasTicket {
                                // already have ticket
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
        .allowsHitTesting(interactionEnabled)
        .interactiveDismissDisabled(!dismissalEnabled)
        .onAppear {
            checkUserTicketStatus()
            
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                didAppear = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                interactionEnabled = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismissalEnabled = true
                withAnimation {
                    mapReady = true
                }
            }
        }
        .onChange(of: ticketsViewModel.tickets.count) { _, _ in
            checkUserTicketStatus()
        }
        // CHANGE 3: Watch for changes to the event in the viewModel
        .onChange(of: eventViewModel.events.first(where: { $0.id == eventId })?.ticketsSold) { _, _ in
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
        eventViewModel.checkUserTicketStatus(for: eventId) { hasTicket in
            DispatchQueue.main.async {
                self.userHasTicket = hasTicket
            }
        }
    }

    private func formatTimeRange(event: Event) -> String {
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
