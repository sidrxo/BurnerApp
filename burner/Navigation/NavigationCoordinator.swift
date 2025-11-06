//
//  NavigationCoordinator.swift
//  burner
//
//  Created by Claude on 2025-11-05.
//

import SwiftUI
import Combine

// MARK: - Tab Selection

enum AppTab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case tickets = 2
    case settings = 3

    var title: String {
        switch self {
        case .home: return "Home"
        case .explore: return "Explore"
        case .tickets: return "Tickets"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .tickets: return "ticket.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Navigation Destinations

enum NavigationDestination: Hashable {
    // Event Navigation
    case eventDetail(Event)
    case eventById(String)
    case filteredEvents(EventSectionDestination)

    // Ticket Navigation
    case ticketDetail(Ticket)
    case ticketPurchase(Event)
    case transferTicket(Ticket)
    case transferTicketsList

    // Settings Navigation
    case accountDetails
    case bookmarks
    case paymentSettings
    case scanner
    case support
    case debugMenu

    func hash(into hasher: inout Hasher) {
        switch self {
        case .eventDetail(let event):
            hasher.combine("eventDetail")
            hasher.combine(event.id)
        case .eventById(let id):
            hasher.combine("eventById")
            hasher.combine(id)
        case .filteredEvents(let destination):
            hasher.combine("filteredEvents")
            hasher.combine(destination.title)
        case .ticketDetail(let ticket):
            hasher.combine("ticketDetail")
            hasher.combine(ticket.id)
        case .ticketPurchase(let event):
            hasher.combine("ticketPurchase")
            hasher.combine(event.id)
        case .transferTicket(let ticket):
            hasher.combine("transferTicket")
            hasher.combine(ticket.id)
        case .transferTicketsList:
            hasher.combine("transferTicketsList")
        case .accountDetails:
            hasher.combine("accountDetails")
        case .bookmarks:
            hasher.combine("bookmarks")
        case .paymentSettings:
            hasher.combine("paymentSettings")
        case .scanner:
            hasher.combine("scanner")
        case .support:
            hasher.combine("support")
        case .debugMenu:
            hasher.combine("debugMenu")
        }
    }

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

// MARK: - Modal Presentations

enum ModalPresentation: Identifiable {
    case signIn
    case burnerSetup
    case ticketPurchase(Event, detent: PresentationDetent = .height(240))
    case ticketDetail(Ticket)
    case shareSheet(items: [Any])
    case cardInput
    case savedCards
    case passwordlessAuth
    case addPaymentMethod
    case manualTicketEntry
    case fullScreenQRCode(Ticket)

    var id: String {
        switch self {
        case .signIn: return "signIn"
        case .burnerSetup: return "burnerSetup"
        case .ticketPurchase(let event, _): return "ticketPurchase-\(event.id ?? "")"
        case .ticketDetail(let ticket): return "ticketDetail-\(ticket.id ?? "")"
        case .shareSheet: return "shareSheet"
        case .cardInput: return "cardInput"
        case .savedCards: return "savedCards"
        case .passwordlessAuth: return "passwordlessAuth"
        case .addPaymentMethod: return "addPaymentMethod"
        case .manualTicketEntry: return "manualTicketEntry"
        case .fullScreenQRCode(let ticket): return "fullScreenQRCode-\(ticket.id ?? "")"
        }
    }

    var isFullScreen: Bool {
        switch self {
        case .signIn, .burnerSetup, .ticketDetail, .fullScreenQRCode, .passwordlessAuth:
            return true
        default:
            return false
        }
    }

    var detent: PresentationDetent? {
        switch self {
        case .ticketPurchase(_, let detent):
            return detent
        default:
            return nil
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
    @Published var selectedTab: AppTab = .home
    @Published var shouldHideTabBar: Bool = false

    // MARK: - Navigation Paths (one per tab)
    @Published var homePath = NavigationPath()
    @Published var explorePath = NavigationPath()
    @Published var ticketsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()

    // MARK: - Modal Presentations
    @Published var activeModal: ModalPresentation?
    @Published var activeAlert: AlertPresentation?

    // MARK: - Deep Linking
    @Published var pendingDeepLink: String?
    @Published var shouldFocusSearchBar: Bool = false

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
        // Switch to the specified tab if provided
        if let tab = tab {
            selectedTab = tab
        }

        // Add to the appropriate navigation path
        switch selectedTab {
        case .home:
            homePath.append(destination)
        case .explore:
            explorePath.append(destination)
        case .tickets:
            ticketsPath.append(destination)
        case .settings:
            settingsPath.append(destination)
        }
    }

    func popToRoot(in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab

        switch targetTab {
        case .home:
            homePath.removeLast(homePath.count)
        case .explore:
            explorePath.removeLast(explorePath.count)
        case .tickets:
            ticketsPath.removeLast(ticketsPath.count)
        case .settings:
            settingsPath.removeLast(settingsPath.count)
        }
    }

    func pop(in tab: AppTab? = nil) {
        let targetTab = tab ?? selectedTab

        switch targetTab {
        case .home:
            if !homePath.isEmpty { homePath.removeLast() }
        case .explore:
            if !explorePath.isEmpty { explorePath.removeLast() }
        case .tickets:
            if !ticketsPath.isEmpty { ticketsPath.removeLast() }
        case .settings:
            if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }

    // MARK: - Modal Methods

    func present(_ modal: ModalPresentation) {
        activeModal = modal
    }

    func dismissModal() {
        activeModal = nil
    }

    func updatePurchaseSheetDetent(_ detent: PresentationDetent, for event: Event) {
        if case .ticketPurchase(let currentEvent, _) = activeModal, currentEvent.id == event.id {
            activeModal = .ticketPurchase(event, detent: detent)
        }
    }

    // MARK: - Alert Methods

    func showAlert(_ alert: AlertPresentation) {
        activeAlert = alert

        // Auto-dismiss after 3 seconds
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
        // Switch to explore tab
        selectedTab = .explore

        // Clear any existing navigation
        explorePath.removeLast(explorePath.count)

        // Set pending deep link (will be picked up by ExploreView)
        pendingDeepLink = eventId

        // Small delay to ensure state is stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.navigate(to: .eventById(eventId), in: .explore)
        }
    }

    func focusSearchBar() {
        selectedTab = .explore
        shouldFocusSearchBar = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.shouldFocusSearchBar = false
        }
    }

    // MARK: - Convenience Methods for Common Flows

    func showSignIn() {
        present(.signIn)
    }

    func showBurnerSetup() {
        present(.burnerSetup)
    }

    func purchaseTicket(for event: Event) {
        present(.ticketPurchase(event))
    }

    func viewTicketDetail(_ ticket: Ticket) {
        present(.ticketDetail(ticket))
    }

    func shareEvent(_ event: Event) {
        let items: [Any] = [
            "Check out this event: \(event.name)",
            URL(string: "burner://event/\(event.id ?? "")") as Any
        ].compactMap { $0 }
        present(.shareSheet(items: items))
    }

    func showFullScreenQRCode(for ticket: Ticket) {
        present(.fullScreenQRCode(ticket))
    }

    // MARK: - Reset

    func resetAllNavigation() {
        homePath = NavigationPath()
        explorePath = NavigationPath()
        ticketsPath = NavigationPath()
        settingsPath = NavigationPath()
        activeModal = nil
        activeAlert = nil
        selectedTab = .home
        shouldHideTabBar = false
    }
}
