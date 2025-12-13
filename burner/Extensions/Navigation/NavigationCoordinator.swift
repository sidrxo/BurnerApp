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

enum NavigationDestination: Hashable {
    case eventDetail(String)
    case eventById(String)
    case filteredEvents(EventSectionDestination)

    case ticketDetail(TicketWithEventData)
    case ticketById(String)
    case ticketPurchase(Event)
    case transferTicket(Ticket)
    case transferTicketsList

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
        case .eventDetail(let eventId):
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
        case (.eventDetail(let lId), .eventDetail(let rId)):
            return lId == rId
        case (.eventById(let lId), .eventById(let rId)):
            return lId == rId
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
        case .burnerSetup, .passwordlessAuth:
            return true
        case .signIn, .SetLocation, .transferTicket, .ticketPurchase, .shareSheet:
            return false
        }
    }
}

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

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: AppTab = .explore
    @Published var shouldHideTabBar: Bool = false

    @Published var explorePath = NavigationPath()
    @Published var searchPath = NavigationPath()
    @Published var ticketsPath = NavigationPath()
    @Published var bookmarksPath = NavigationPath()

    @Published var activeModal: ModalPresentation?
    @Published var activeAlert: AlertPresentation?

    @Published var pendingDeepLink: String?

    private var cancellables = Set<AnyCancellable>()

    func selectTab(_ tab: AppTab) {
        selectedTab = tab
    }

    func hideTabBar() {
        shouldHideTabBar = true
    }

    func showTabBar() {
        shouldHideTabBar = false
    }

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

    func present(_ modal: ModalPresentation) {
        activeModal = modal
    }

    func dismissModal() {
        activeModal = nil
    }

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

    func handleDeepLink(eventId: String) {
        selectTab(.explore)
        if !explorePath.isEmpty {
            explorePath.removeLast(explorePath.count)
        }
        pendingDeepLink = eventId
        navigate(to: .eventDetail(eventId), in: .explore)
    }

    func handleTicketDeepLink(ticketId: String) {
        selectTab(.tickets)
        if !ticketsPath.isEmpty {
            ticketsPath.removeLast(ticketsPath.count)
        }
        navigate(to: .ticketById(ticketId), in: .tickets)
    }

    func showSignIn() {
        present(.signIn)
    }

    func showBurnerSetup() {
        present(.burnerSetup)
    }

    // UPDATED: Push to the Explore path to avoid tab switch
    func purchaseTicket(for event: Event) {
        navigate(to: .ticketPurchase(event), in: .explore)
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
