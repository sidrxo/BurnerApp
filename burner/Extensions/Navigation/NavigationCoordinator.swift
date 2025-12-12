import SwiftUI
import Combine


enum AppTab: Int, CaseIterable {
    case explore = 0
    case search = 1
    case bookmarks = 2
    case tickets = 3

    var title: String {
        switch self {
        case .explore: return "Explore"
        case .search: return "Search"
        case .bookmarks: return "Saves"
        case .tickets: return "Tickets"
        }
    }

    var icon: String {
        switch self {
        case .explore: return "house.fill"
        case .search: return "magnifyingglass"
        case .bookmarks: return "heart.fill"
        case .tickets: return "ticket.fill"
        }
    }
}

// MARK: - Navigation Destinations

enum NavigationDestination: Hashable {
    case eventDetail(String)
    case eventById(String)
    case filteredEvents(EventSectionDestination)

    // Ticket Navigation
    case ticketDetail(TicketWithEventData)
    case ticketById(String)
    case ticketPurchase(Event)  
    case transferTicket(Ticket)
    case transferTicketsList

    // Settings Navigation
    case settings
    case accountDetails
    case bookmarks
    case paymentSettings
    case scanner
    case notifications
    case support
    case debugMenu

    func hash(into hasher: inout Hasher) {
        switch self {
        case .eventDetail(let eventId):  // ✅ CHANGED: Now uses eventId
            hasher.combine("eventDetail")
            hasher.combine(eventId)
        case .eventById(let id):
            hasher.combine("eventById")
            hasher.combine(id)
        case .filteredEvents(let destination):
            hasher.combine("filteredEvents")
            hasher.combine(destination.title)
        case .ticketDetail(let ticketWithEvent):
            hasher.combine("ticketDetail")
            hasher.combine(ticketWithEvent.ticket.id)
        case .ticketById(let id):
            hasher.combine("ticketById")
            hasher.combine(id)
        case .ticketPurchase(let event):
            hasher.combine("ticketPurchase")
            hasher.combine(event.id)
        case .transferTicket(let ticket):
            hasher.combine("transferTicket")
            hasher.combine(ticket.id)
        case .transferTicketsList:
            hasher.combine("transferTicketsList")
        case .settings:
            hasher.combine("settings")
        case .accountDetails:
            hasher.combine("accountDetails")
        case .bookmarks:
            hasher.combine("bookmarks")
        case .paymentSettings:
            hasher.combine("paymentSettings")
        case .scanner:
            hasher.combine("scanner")
        case .notifications:
            hasher.combine("notifications")
        case .support:
            hasher.combine("support")
        case .debugMenu:
            hasher.combine("debugMenu")
        }
    }

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.eventDetail(let lId), .eventDetail(let rId)):  // ✅ CHANGED: Compare IDs
            return lId == rId
        case (.eventById(let lId), .eventById(let rId)):
            return lId == rId
        // ✅ NEW: Allow eventDetail and eventById to be equal if same ID
        case (.eventDetail(let id1), .eventById(let id2)),
             (.eventById(let id1), .eventDetail(let id2)):
            return id1 == id2
        case (.filteredEvents(let lDest), .filteredEvents(let rDest)):
            return lDest == rDest
        case (.ticketDetail(let lTicketWithEvent), .ticketDetail(let rTicketWithEvent)):
            return lTicketWithEvent.ticket.id == rTicketWithEvent.ticket.id
        case (.ticketById(let lId), .ticketById(let rId)):
            return lId == rId
        case (.ticketPurchase(let lEvent), .ticketPurchase(let rEvent)):
            return lEvent.id == rEvent.id
        case (.transferTicket(let lTicket), .transferTicket(let rTicket)):
            return lTicket.id == rTicket.id
        case (.transferTicketsList, .transferTicketsList):
            return true
        case (.settings, .settings):
            return true
        case (.accountDetails, .accountDetails):
            return true
        case (.bookmarks, .bookmarks):
            return true
        case (.paymentSettings, .paymentSettings):
            return true
        case (.scanner, .scanner):
            return true
        case (.notifications, .notifications):
            return true
        case (.support, .support):
            return true
        case (.debugMenu, .debugMenu):
            return true
        default:
            return false
        }
    }
}

// MARK: - Modal Presentations

enum ModalPresentation: Identifiable {
    case signIn
    case burnerSetup
    case ticketPurchase(Event)
    case transferTicket(TicketWithEventData)
    case shareSheet(items: [Any])
    case passwordlessAuth
    case SetLocation

    var id: String {
        switch self {
        case .signIn: return "signIn"
        case .burnerSetup: return "burnerSetup"
        case .ticketPurchase(let event): return "ticketPurchase-\(event.id ?? "")"
        case .transferTicket(let ticketWithEvent): return "transferTicket-\(ticketWithEvent.ticket.id ?? "")"
        case .shareSheet: return "shareSheet"
        case .passwordlessAuth: return "passwordlessAuth"
        case .SetLocation: return "SetLocation"
        }
    }

    var isFullScreen: Bool {
        switch self {
        case .burnerSetup, .passwordlessAuth, .ticketPurchase:
            return true
        case .signIn, .SetLocation, .transferTicket:
            return false
        default:
            return false
        }
    }
}

// MARK: - Alert Presentation

struct AlertPresentation: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String
    let iconColor: Color

    static func success(title: String, message: String) -> AlertPresentation {
        AlertPresentation(title: title, message: message, icon: "checkmark.circle.fill", iconColor: .green)
    }

    static func error(title: String, message: String) -> AlertPresentation {
        AlertPresentation(title: title, message: message, icon: "xmark.circle.fill", iconColor: .red)
    }

    static func warning(title: String, message: String) -> AlertPresentation {
        AlertPresentation(title: title, message: message, icon: "exclamationmark.triangle.fill", iconColor: .orange)
    }

    static func info(title: String, message: String) -> AlertPresentation {
        AlertPresentation(title: title, message: message, icon: "info.circle.fill", iconColor: .blue)
    }
}

// MARK: - Navigation Coordinator

@MainActor
class NavigationCoordinator: ObservableObject {
    // MARK: - Tab Navigation
    @Published var selectedTab: AppTab = .explore
    @Published var shouldHideTabBar: Bool = false

    // MARK: - Navigation Paths (one per tab)
    @Published var explorePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var ticketsPath = NavigationPath()
    @Published var bookmarksPath = NavigationPath()

    // MARK: - Modal Presentations
    @Published var activeModal: ModalPresentation?
    @Published var activeAlert: AlertPresentation?

    // MARK: - Deep Linking
    @Published var pendingDeepLink: String?

    // MARK: - Shared State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Tab Navigation Methods

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func hideTabBar() {
        shouldHideTabBar = true
    }

    func showTabBar() {
        shouldHideTabBar = false
    }

    // MARK: - Navigation Methods

    func navigate(to destination: NavigationDestination, in tab: AppTab? = nil) {
        if let tab = tab {
            selectTab(tab)
        }

        switch selectedTab {
        case .explore:
            explorePath.append(destination)
        case .search:
            searchPath.append(destination)
        case .tickets:
            ticketsPath.append(destination)
        case .bookmarks:
            bookmarksPath.append(destination)
        }
    }

    func popToRoot(in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab

        switch targetTab {
        case .explore:
            if !explorePath.isEmpty { explorePath.removeLast(explorePath.count) }
        case .search:
            if !searchPath.isEmpty { searchPath.removeLast(searchPath.count) }
        case .tickets:
            if !ticketsPath.isEmpty { ticketsPath.removeLast(ticketsPath.count) }
        case .bookmarks:
            if !bookmarksPath.isEmpty { bookmarksPath.removeLast(bookmarksPath.count) }
        }
    }

    func pop(in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab

        switch targetTab {
        case .explore:
            if !explorePath.isEmpty { explorePath.removeLast() }
        case .search:
            if !searchPath.isEmpty { searchPath.removeLast() }
        case .tickets:
            if !ticketsPath.isEmpty { ticketsPath.removeLast() }
        case .bookmarks:
            if !bookmarksPath.isEmpty { bookmarksPath.removeLast() }
        }
    }

    // MARK: - Modal Methods

    func present(_ modal: ModalPresentation) {
        activeModal = modal
    }

    func dismissModal() {
        activeModal = nil
    }

    // MARK: - Alert Methods

    func showAlert(_ alert: AlertPresentation) {
        activeAlert = alert
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.activeAlert?.id == alert.id {
                self?.activeAlert = nil
            }
        }
    }

    func showSuccess(title: String, message: String) {
        showAlert(.success(title: title, message: message))
    }

    func showError(title: String, message: String) {
        showAlert(.error(title: title, message: message))
    }

    func showWarning(title: String, message: String) {
        showAlert(.warning(title: title, message: message))
    }

    func showInfo(title: String, message: String) {
        showAlert(.info(title: title, message: message))
    }

    func dismissAlert() {
        activeAlert = nil
    }

    // MARK: - Deep Linking

    func handleDeepLink(eventId: String) {
        selectTab(.explore)
        if !explorePath.isEmpty {
            explorePath.removeLast(explorePath.count)
        }
        pendingDeepLink = eventId
        // ✅ CHANGED: Use eventDetail instead of eventById (now they're the same)
        navigate(to: .eventDetail(eventId), in: .explore)
    }

    func handleTicketDeepLink(ticketId: String) {
        selectTab(.tickets)
        if !ticketsPath.isEmpty {
            ticketsPath.removeLast(ticketsPath.count)
        }
        navigate(to: .ticketById(ticketId), in: .tickets)
    }

    // MARK: - Convenience Methods

    func showSignIn() {
        present(.signIn)
    }

    func showBurnerSetup() {
        present(.burnerSetup)
    }

    func purchaseTicket(for event: Event) {
        present(.ticketPurchase(event))
    }

    func viewTicketDetail(_ ticket: Ticket, ticketWithEvent: TicketWithEventData) {
        navigate(to: .ticketDetail(ticketWithEvent))
    }

    func shareEvent(_ event: Event) {
        let items: [Any] = [
            "Check out this event: \(event.name)",
            URL(string: "burner://event/\(event.id ?? "")") as Any
        ].compactMap { $0 }
        present(.shareSheet(items: items))
    }

    // MARK: - Reset

    func resetAllNavigation() {
        explorePath = NavigationPath()
        searchPath = NavigationPath()
        ticketsPath = NavigationPath()
        bookmarksPath = NavigationPath()
        activeModal = nil
        activeAlert = nil
        selectedTab = .explore
        shouldHideTabBar = false
    }
}

