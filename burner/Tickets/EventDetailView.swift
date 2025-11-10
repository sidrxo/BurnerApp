import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFunctions
import Firebase
import PassKit
import MapKit

struct EventDetailView: View {
    let event: Event
    
    // Use environment objects instead of creating new instances
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState

    @State private var userHasTicket = false
    @State private var showingSignInAlert = false // ✅ NEW
    @State private var showingMapsSheet = false
    
    // Get screen height for responsive sizing
    private let screenHeight = UIScreen.main.bounds.height
    
    // Calculate responsive hero height based on screen size
    private var heroHeight: CGFloat {
        // Use 50% of screen height to show more of the image, with min/max bounds
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

    var buttonText: String {
        if userHasTicket {
            return "TICKET PURCHASED"
        } else if availableTickets > 0 {
            return "GET TICKET"
        } else {
            return "SOLD OUT"
        }
    }
    
    var buttonColor: Color {
        if userHasTicket {
            return .gray
        } else if availableTickets > 0 {
            return .white
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    var buttonTextColor: Color {
        if userHasTicket {
            return .white
        } else if availableTickets > 0 {
            return .black
        } else {
            return .white
        }
    }

    var isButtonDisabled: Bool {
        return availableTickets == 0 && !userHasTicket
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Image Section - Extends under navigation bar
                        ZStack {
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
                           
                            // Description - more compact
                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("About")
                                        .appBody()
                                        .foregroundColor(.white)

                                    Text(description)
                                        .appBody()
                                        .foregroundColor(.gray)
                                        .lineSpacing(2)
                                        .lineLimit(6)
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
                                        .font(.system(size: 22))
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
                                        .font(.system(size: 22))
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
                
                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        // Remove the gradient from here
                        
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
                            Text(buttonText)
                                .font(.appFont(size: 17))
                                .largeActionButtonStyle(
                                    backgroundColor: buttonColor,
                                    foregroundColor: buttonTextColor,
                                    height: 50,
                                    cornerRadius: 25
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
                        description: "Please sign in to continue.",
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
        .navigationBarBackButtonHidden(false)
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
                .padding(.top, 20)
                .padding(.bottom, 16)

            VStack(spacing: 12) {
                Button(action: {
                    openInAppleMaps()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "map")
                            .font(.system(size: 20))
                        Text("Apple Maps")
                            .appBody()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
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
                            .font(.system(size: 20))
                        Text("Google Maps")
                            .appBody()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
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

#Preview {
    NavigationStack {
        EventDetailView(event: Event(
            name: "fabric Presents: Nina Kraviz",
            venue: "fabric London",
            price: 25.0,
            maxTickets: 100,
            ticketsSold: 50,
            imageUrl: "https://placeholder.com/400x600",
            isFeatured: false,
            description: "The Russian techno queen returns to fabric with her hypnotic blend of acid and experimental electronic music."
        ))
        .environmentObject(AppState().bookmarkManager)
        .environmentObject(AppState().eventViewModel)
        .environmentObject(NavigationCoordinator())
    }
    .preferredColorScheme(.dark)
}
