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

    // Use environment objects instead of creating new instances
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState

    @State private var userHasTicket = false
    @State private var showingSignInAlert = false // ✅ NEW
    @State private var showingMapsSheet = false
    @State private var isDescriptionExpanded = false
    @State private var needsReadMore = false // NEW: Track if text actually needs expansion
    @State private var scrollOffset: CGFloat = 0
    
    // Get screen height for responsive sizing
    private let screenHeight = UIScreen.main.bounds.height
    
    // Calculate responsive hero height based on screen size
    private var heroHeight: CGFloat {
        // Use 50% of screen height to show more of the image, with min/max bounds
        let calculatedHeight = screenHeight * 0.50
        return max(350, min(calculatedHeight, 550))
    }

    // Calculate progressive blur based on scroll offset
    private var blurRadius: CGFloat {
        // Start blurring after 50 points of scroll, max blur at 200 points
        let progress = min(max(scrollOffset - 50, 0) / 150, 1.0)
        return progress * 20 // Max blur radius of 20
    }

    // Calculate blur overlay opacity
    private var blurOverlayOpacity: Double {
        let progress = min(max(scrollOffset - 50, 0) / 150, 1.0)
        return Double(progress) * 0.6
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
            // If no end time, check if event started more than 6 hours ago
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
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Scroll offset tracker
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: -scrollGeometry.frame(in: .named("scroll")).minY
                                )
                        }
                        .frame(height: 0)
                        .onAppear {
                            scrollOffset = 0
                        }

                        // Hero Image Section - Extends under navigation bar
                        ZStack {
                            // Base image with matched geometry effect
                            Group {
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
                                    .frame(width: geometry.size.width, height: heroHeight)
                                    .clipped()
                            }
                            .if(namespace != nil && event.id != nil) { view in
                                view.matchedGeometryEffect(id: "heroImage-\(event.id!)", in: namespace!)
                            }
                            .overlay(
                                // Progressive Blur Overlay (top to bottom fade) - responds to scroll
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(stops: [
                                                .init(color: Color.white.opacity(0.15), location: 0.0),
                                                .init(color: Color.clear, location: 0.3)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .blur(radius: 20)
                                    .opacity(blurOverlayOpacity)
                            )

                            // Gradient overlay that darkens the bottom
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.clear,
                                    Color.clear,
                                    Color.black.opacity(0.6),
                                    Color.black.opacity(0.9)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: geometry.size.width, height: heroHeight)
                            
                            // Event info overlay - positioned at bottom
                            VStack {
                                   Spacer()
                                   
                                   HStack {
                                       VStack(alignment: .leading, spacing: 12) {
                                           Text(event.name)
                                               .appHero()
                                               .foregroundColor(.white)
                                               .multilineTextAlignment(.leading)
                                               .fixedSize(horizontal: false, vertical: true)
                                       }
                                       
                                       Spacer()
                                   }
                                   .padding(.horizontal, 20)
                                   .padding(.bottom, 20)
                            }
                        }
                        .frame(height: heroHeight)
                        .padding(.bottom, 30)
                        
                        // Content Section - More compact spacing
                        VStack(spacing: 16) {
                           
                            // Description - more compact with read more
                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .appBody()
                                        .foregroundColor(.white)

                                    VStack(alignment: .leading, spacing: 2) { // REDUCED: spacing from 4 to 2
                                        Text(description)
                                            .appBody()
                                            .foregroundColor(.gray)
                                            .lineSpacing(2)
                                            .lineLimit(isDescriptionExpanded ? nil : 6)
                                            .background(
                                                // NEW: Detect if text actually needs expansion
                                                GeometryReader { textGeometry in
                                                    Color.clear
                                                        .onAppear {
                                                            // Calculate if text is truncated
                                                            let textSize = description.boundingRect(
                                                                with: CGSize(
                                                                    width: textGeometry.size.width,
                                                                    height: .greatestFiniteMagnitude
                                                                ),
                                                                options: .usesLineFragmentOrigin,
                                                                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
                                                                context: nil
                                                            )
                                                            // If text height exceeds 6 lines, show read more
                                                            let lineHeight: CGFloat = 20 // Approximate line height
                                                            let maxHeight = lineHeight * 6
                                                            needsReadMore = textSize.height > maxHeight
                                                        }
                                                }
                                            )
                                            .animation(.easeInOut, value: isDescriptionExpanded)

                                        // NEW: Only show if text actually needs expansion
                                        if needsReadMore {
                                            Button(action: {
                                                withAnimation {
                                                    isDescriptionExpanded.toggle()
                                                }
                                            }) {
                                                Text(isDescriptionExpanded ? "Read Less" : "Read More")
                                                    .appCaption()
                                                    .foregroundColor(.gray) // CHANGED: from blue to gray
                                                    .padding(.top, 2) // REDUCED: padding from 4 to 2
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 8)
                            }
                            
                            // Event details - more compact
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

                                    // Genre/Tag row - non-clickable
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

                            // Map Section
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

                            // Save and Share buttons side by side (icons only)
                            HStack(spacing: 12) {
                                // Save/Bookmark button
                                Button(action: {
                                    // Check if user is authenticated
                                    if Auth.auth().currentUser == nil {
                                        // Show sign-in alert if not authenticated
                                        showingSignInAlert = true
                                    } else {
                                        // Toggle bookmark if authenticated
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

                                // Share button
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
                            
                            // Bottom spacing for floating button
                            Spacer(minLength: 100)
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        // Remove the gradient from here
                        
                        // UPDATED: Get Ticket Button - matching sign-in sheet style
                        Button(action: {
                            if userHasTicket {
                                // Do nothing when user has a ticket
                            } else if availableTickets > 0 {
                                // Check if user is authenticated
                                if Auth.auth().currentUser == nil {
                                    // ✅ Show custom alert instead of toast
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
                        .padding(.top, 40)  // ✅ Add top padding to create space for gradient

                    }
                    .background(
                        // Apply gradient as the background instead
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
                
                // ✅ NEW: Sign In Alert
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
            // Refresh ticket status when tickets list changes
            checkUserTicketStatus()
        }
        .onChange(of: event.ticketsSold) { _, _ in
            // Refresh when tickets sold changes
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

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
