import SwiftUI
import Kingfisher

// MARK: - Unified Event Row Component
struct UnifiedEventRow: View {
    let event: Event
    let ticket: Ticket?
    let bookmarkManager: BookmarkManager?
    let configuration: Configuration
    let onCancel: (() -> Void)?
    
    init(
        event: Event,
        ticket: Ticket? = nil,
        bookmarkManager: BookmarkManager? = nil,
        configuration: Configuration = .eventList,
        onCancel: (() -> Void)? = nil
    ) {
        self.event = event
        self.ticket = ticket
        self.bookmarkManager = bookmarkManager
        self.configuration = configuration
        self.onCancel = onCancel
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            eventImage
            
            // Event Details
            eventDetails
            
            Spacer()
            
            // Right side content (bookmark, QR code, status)
            rightSideContent
        }
        .padding(.horizontal, configuration.horizontalPadding)
        .padding(.vertical, configuration.verticalPadding)
        .background(configuration.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: configuration.cornerRadius))
        .contextMenu {
            contextMenuContent
        }
    }
    
    // MARK: - Event Image
    private var eventImage: some View {
        Group {
            if let url = URL(string: event.imageUrl), !event.imageUrl.isEmpty {
                KFImage(url)
                    .placeholder {
                        imagePlaceholder
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                imagePlaceholder
            }
        }
    }
    
    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: "music.note")
                    .font(.appIcon)
                    .foregroundColor(.gray)
            )
    }
    
    // MARK: - Event Details
    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.name)
                .appBody()
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if configuration.showVenue {
                Text(event.venue)
                    .appSecondary()
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            // Date formatting based on configuration
            if configuration.showDetailedDate {
                HStack(spacing: 4) {
                    Text(event.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .appSecondary()
                        .foregroundColor(.gray)
                }
            } else {
                Text(event.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .appSecondary()
                    .foregroundColor(.gray)
            }
            
            // Status badges for tickets
            statusBadges
            
            // Price (only for event list)
        
        }
    }
    
    // MARK: - Status Badges
    private var statusBadges: some View {
        HStack(spacing: 8) {
            if let ticket = ticket {
                if ticket.status == "cancelled" {
                    Text("Cancelled")
                        .appCaption()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else if isPastEvent {
                    Text("Past Event")
                        .appCaption()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
    
    // MARK: - Right Side Content
    private var rightSideContent: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Bookmark button
            if configuration.showBookmark, let bookmarkManager = bookmarkManager {
                BookmarkButton(
                    event: event,
                    bookmarkManager: bookmarkManager,
                    size: configuration.bookmarkSize
                )
            }
            
            // QR code or status for tickets
            if let ticket = ticket {
                if !isPastEvent && ticket.status == "confirmed" {
                    Image(systemName: "qrcode")
                        .font(.appIcon)
                        .foregroundColor(.white)
                } else if isPastEvent {
                    Text("Attended")
                        .appCaption()
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private var contextMenuContent: some View {
        if let ticket = ticket,
           !isPastEvent && ticket.status == "confirmed",
           let onCancel = onCancel {
            Button("Cancel Ticket", role: .destructive) {
                onCancel()
            }
        }
    }
    
    // MARK: - Helper Properties
    private var isPastEvent: Bool {
        let calendar = Calendar.current
        let nextDay6AM = calendar.dateInterval(of: .day, for: event.date)?.end ?? event.date
        let nextDay6AMDate = calendar.date(byAdding: .hour, value: 6, to: nextDay6AM) ?? event.date
        return Date() > nextDay6AMDate
    }
}

// MARK: - Configuration
extension UnifiedEventRow {
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
        
        // Predefined configurations
        static let eventList = Configuration(
            showBookmark: true,
            showPrice: true,
            showVenue: true,
            showDetailedDate: false,
            bookmarkSize: 18,
            horizontalPadding: 20,
            verticalPadding: 12,
            backgroundColor: Color.clear,
            cornerRadius: 0
        )
        
        static let ticketRow = Configuration(
            showBookmark: false,
            showPrice: false,
            showVenue: true,
            showDetailedDate: true,
            bookmarkSize: 16,
            horizontalPadding: 16,
            verticalPadding: 12,
            backgroundColor: Color.gray.opacity(0.1),
            cornerRadius: 12
        )
        
        static let ticketRowWithBookmark = Configuration(
            showBookmark: true,
            showPrice: false,
            showVenue: true,
            showDetailedDate: true,
            bookmarkSize: 16,
            horizontalPadding: 16,
            verticalPadding: 12,
            backgroundColor: Color.gray.opacity(0.1),
            cornerRadius: 12
        )
    }
}

// MARK: - Convenience Initializers
extension UnifiedEventRow {
    // For event lists (Explore/Home views)
    init(event: Event, bookmarkManager: BookmarkManager) {
        self.init(
            event: event,
            ticket: nil,
            bookmarkManager: bookmarkManager,
            configuration: .eventList,
            onCancel: nil
        )
    }
    
    // For ticket rows
    init(ticketWithEvent: TicketWithEventData, isPast: Bool, onCancel: @escaping () -> Void) {
        self.init(
            event: ticketWithEvent.event,
            ticket: ticketWithEvent.ticket,
            bookmarkManager: nil,
            configuration: .ticketRow,
            onCancel: onCancel
        )
    }
    
    // For ticket rows with bookmark
    init(ticketWithEvent: TicketWithEventData, isPast: Bool, bookmarkManager: BookmarkManager, onCancel: @escaping () -> Void) {
        self.init(
            event: ticketWithEvent.event,
            ticket: ticketWithEvent.ticket,
            bookmarkManager: bookmarkManager,
            configuration: .ticketRowWithBookmark,
            onCancel: onCancel
        )
    }
}

// MARK: - Bookmark Button Component
struct BookmarkButton: View {
    let event: Event
    @ObservedObject var bookmarkManager: BookmarkManager
    let size: CGFloat
    
    init(event: Event, bookmarkManager: BookmarkManager, size: CGFloat = 18) {
        self.event = event
        self.bookmarkManager = bookmarkManager
        self.size = size
    }
    
    var body: some View {
        Button(action: {
            Task {
                await bookmarkManager.toggleBookmark(for: event)
            }
        }) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.appIcon)
                .foregroundColor(isBookmarked ? .white : .gray)
                .scaleEffect(isBookmarked ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isBookmarked)
        }
    }
    
    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }
}

// MARK: - Supporting Types
struct TicketWithEventData: Codable, Identifiable {
    let ticket: Ticket
    let event: Event
    var id: String {
        ticket.id ?? UUID().uuidString
    }
}
