import SwiftUI
import Kingfisher
import Shared

// MARK: - Local Date Extension
extension Shared.Event {
    var dateObject: Date {
        guard let start = self.startTime else { return Date() }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: start) ?? Date()
    }
}

// MARK: - Alert Preference Key
struct BookmarkAlertPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

// MARK: - Unified Event Row Component
struct EventRow: View {
    let event: Shared.Event
    let ticket: Shared.Ticket?
    let bookmarkManager: BookmarkManager?
    let configuration: Configuration
    let onCancel: (() -> Void)?
    let distanceText: String?
    @Binding var showingSignInAlert: Bool
    var namespace: Namespace.ID?

    init(
        event: Shared.Event,
        ticket: Shared.Ticket? = nil,
        bookmarkManager: BookmarkManager? = nil,
        configuration: Configuration = .eventList,
        onCancel: (() -> Void)? = nil,
        distanceText: String? = nil,
        showingSignInAlert: Binding<Bool> = .constant(false),
        namespace: Namespace.ID? = nil
    ) {
        self.event = event
        self.ticket = ticket
        self.bookmarkManager = bookmarkManager
        self.configuration = configuration
        self.onCancel = onCancel
        self.distanceText = distanceText
        self._showingSignInAlert = showingSignInAlert
        self.namespace = namespace
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            eventImage
            
            // Event Details
            eventDetails
            
            Spacer()
            
            // Right side content
            rightSideContent
        }
        .padding(.horizontal, configuration.horizontalPadding)
        .padding(.vertical, configuration.verticalPadding)
        .background(configuration.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
    }
    
    private var eventImage: some View {
        Group {
            if !event.imageUrl.isEmpty, let url = URL(string: event.imageUrl) {
                KFImage(url)
                    .placeholder { ImagePlaceholder(size: 60, cornerRadius: 8) }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .if(namespace != nil && event.id != nil) { view in
                        view.matchedTransitionSource(id: "heroImage-\(event.id ?? "")", in: namespace!) { source in
                            source.clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
            } else {
                ImagePlaceholder(size: 60, cornerRadius: 8)
            }
        }
    }
    
    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.name)
                .appBody()
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            HStack {
                if configuration.showVenue {
                    Text(event.venue)
                        .appSecondary()
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Spacer()
                if let distance = distanceText {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill").appFont(size: 10).foregroundColor(.gray)
                        Text(distance).appCaption().foregroundColor(.gray)
                    }
                }
            }
            
            if configuration.showDetailedDate {
                Text(event.dateObject.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .appSecondary().foregroundColor(.gray)
            } else {
                Text(event.dateObject.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .appSecondary().foregroundColor(.gray)
            }
            
            if let ticket = ticket, ticket.status == "cancelled" {
                HStack(spacing: 8) {
                    Text("Cancelled").appCaption().padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.red.opacity(0.2)).foregroundColor(.red).clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private var rightSideContent: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if configuration.showBookmark, let bookmarkManager = bookmarkManager {
                BookmarkButton(
                    event: event,
                    bookmarkManager: bookmarkManager,
                    size: configuration.bookmarkSize,
                    showingSignInAlert: $showingSignInAlert
                )
            }
            if let ticket = ticket {
                if ticket.status == "confirmed" || ticket.status == "used" {
                    Image(systemName: "qrcode").font(.appIcon).foregroundColor(event.isPast ? .gray : .white)
                }
            }
        }
    }
}

// MARK: - Configuration
extension EventRow {
    struct Configuration {
        let showBookmark: Bool
        let showPrice: Bool
        let showVenue: Bool
        let showDetailedDate: Bool
        let bookmarkSize: CGFloat
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        let backgroundColor: Color
        let cornerRadius: CGFloat
        
        static let eventList = Configuration(showBookmark: true, showPrice: true, showVenue: true, showDetailedDate: false, bookmarkSize: 18, horizontalPadding: 14, verticalPadding: 8, backgroundColor: Color.clear, cornerRadius: 0)
        static let ticketRow = Configuration(showBookmark: false, showPrice: false, showVenue: true, showDetailedDate: true, bookmarkSize: 16, horizontalPadding: 20, verticalPadding: 12, backgroundColor: Color.clear, cornerRadius: 0)
        static let ticketRowWithBookmark = Configuration(showBookmark: true, showPrice: false, showVenue: true, showDetailedDate: true, bookmarkSize: 16, horizontalPadding: 20, verticalPadding: 12, backgroundColor: Color.clear, cornerRadius: 0)
    }
}

// MARK: - Convenience Initializers
extension EventRow {
    init(event: Shared.Event, bookmarkManager: BookmarkManager, showingSignInAlert: Binding<Bool> = .constant(false), namespace: Namespace.ID? = nil) {
        self.init(event: event, ticket: nil, bookmarkManager: bookmarkManager, configuration: .eventList, onCancel: nil, distanceText: nil, showingSignInAlert: showingSignInAlert, namespace: namespace)
    }
    init(ticketWithEvent: TicketWithEventData, isPast: Bool, onCancel: @escaping () -> Void) {
        self.init(event: ticketWithEvent.event, ticket: ticketWithEvent.ticket, bookmarkManager: nil, configuration: .ticketRow, onCancel: onCancel, distanceText: nil, showingSignInAlert: .constant(false), namespace: nil)
    }
    init(ticketWithEvent: TicketWithEventData, isPast: Bool, bookmarkManager: BookmarkManager, onCancel: @escaping () -> Void) {
        self.init(event: ticketWithEvent.event, ticket: ticketWithEvent.ticket, bookmarkManager: bookmarkManager, configuration: .ticketRowWithBookmark, onCancel: onCancel, distanceText: nil, showingSignInAlert: .constant(false), namespace: nil)
    }
}

// MARK: - Bookmark Button
struct BookmarkButton: View {
    let event: Shared.Event
    @ObservedObject var bookmarkManager: BookmarkManager
    let size: CGFloat
    @EnvironmentObject var appState: AppState
    @Binding var showingSignInAlert: Bool

    init(event: Shared.Event, bookmarkManager: BookmarkManager, size: CGFloat = 18, showingSignInAlert: Binding<Bool>) {
        self.event = event
        self.bookmarkManager = bookmarkManager
        self.size = size
        self._showingSignInAlert = showingSignInAlert
    }

    var body: some View {
        Button(action: {
            if appState.authService.getCurrentUserId() == nil {
                withAnimation { showingSignInAlert = true }
            } else {
                if !isToggling { bookmarkManager.toggleBookmark(for: event) }
            }
        }) {
            ZStack {
                if isToggling {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Image(systemName: isBookmarked ? "heart.fill" : "heart")
                        .font(.appIcon)
                        .foregroundColor(isBookmarked ? .white : .gray)
                        .scaleEffect(isBookmarked ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isBookmarked)
                }
            }
        }
        .disabled(isToggling)
        .opacity(isToggling ? 0.6 : 1.0)
    }

    private var isBookmarked: Bool {
        guard let id = event.id else { return false }
        return bookmarkManager.isBookmarked(id)
    }

    private var isToggling: Bool {
        guard let id = event.id else { return false }
        return bookmarkManager.isTogglingBookmark[id] ?? false
    }
}
