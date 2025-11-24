//
//  NavigationCoordinatorView.swift
//  burner
//
//  Created by Claude on 2025-11-05.
//

import SwiftUI
import Combine

// MARK: - Navigation Coordinator View

struct NavigationCoordinatorView<Content: View>: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @ViewBuilder let content: Content

    var body: some View {
        content
            .sheet(item: sheetBinding) { modal in
                modalView(for: modal)
            }
            .fullScreenCover(item: fullScreenBinding) { modal in
                modalView(for: modal)
            }
            .overlay(alignment: .top) {
                if let alert = coordinator.activeAlert {
                    ToastAlertView(
                        title: alert.title,
                        message: alert.message,
                        icon: alert.icon,
                        iconColor: alert.iconColor
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1001)
                    .padding(.top, 50)
                    .onTapGesture {
                        coordinator.dismissAlert()
                    }
                }
            }
    }

    // MARK: - Bindings

    private var sheetBinding: Binding<ModalPresentation?> {
        Binding(
            get: {
                guard let modal = coordinator.activeModal, !modal.isFullScreen else {
                    return nil
                }
                return modal
            },
            set: { newValue in
                if newValue == nil {
                    coordinator.dismissModal()
                }
            }
        )
    }

    private var fullScreenBinding: Binding<ModalPresentation?> {
        Binding(
            get: {
                guard let modal = coordinator.activeModal, modal.isFullScreen else {
                    return nil
                }
                return modal
            },
            set: { newValue in
                if newValue == nil {
                    coordinator.dismissModal()
                }
            }
        )
    }

    // MARK: - Modal View Builder

    @ViewBuilder
    private func modalView(for modal: ModalPresentation) -> some View {
        switch modal {
        case .SetLocation:
            // Present your new modal. Adjust init/props to match your SetLocationModal.swift
            SetLocationModal()
        case .signIn:
            SignInSheetView(showingSignIn: Binding(
                get: { true },
                set: { newValue in
                    if !newValue {
                        coordinator.dismissModal()
                    }
                }
            ))

        case .burnerSetup:
            BurnerModeSetupView(burnerManager: appState.burnerManager)

        case .ticketPurchase(let event):
            TicketPurchaseView(
                event: event,
                viewModel: appState.eventViewModel
            )

        case .ticketDetail(let ticket):
            TicketDetailDestination(ticket: ticket)

        case .shareSheet(let items):
            ActivityViewController(activityItems: items)

        case .passwordlessAuth:
            PasswordlessAuthView(showingSignIn: Binding(
                get: { true },
                set: { newValue in
                    if !newValue {
                        coordinator.dismissModal()
                    }
                }
            ))

        case .fullScreenQRCode(let ticket):
            FullScreenQRCodeView(
                ticketWithEvent: TicketWithEventData(
                    ticket: ticket,
                    event: createPlaceholderEvent(from: ticket)
                ),
                qrCodeData: ticket.qrCode ?? ""
            )
        }
    }
}

// MARK: - Activity View Controller (Share Sheet)

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Navigation Destination View Builder

struct NavigationDestinationBuilder: View {
    let destination: NavigationDestination
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        Group {
            switch destination {
            // Event Navigation
            case .eventDetail(let event):
                EventDetailView(event: event, namespace: heroNamespace)

            case .eventById(let eventId):
                EventDetailDestination(eventId: eventId)

            case .filteredEvents(let sectionDestination):
                FilteredEventsView(title: sectionDestination.title, events: sectionDestination.events)

            // Ticket Navigation
            case .ticketDetail(let ticket):
                TicketDetailDestination(ticket: ticket)

            case .ticketById(let ticketId):
                TicketDetailByIdDestination(ticketId: ticketId)

            case .ticketPurchase(let event):
                TicketPurchaseDestination(event: event)

            case .transferTicket(let ticket):
                TransferTicketDestination(ticket: ticket)

            case .transferTicketsList:
                TransferTicketsListView()

            // Settings Navigation
            case .accountDetails:
                AccountDetailsView()

            case .bookmarks:
                BookmarksView()

            case .paymentSettings:
                PaymentSettingsView()

            case .scanner:
                ScannerView()

            case .support:
                SupportView()

            case .debugMenu:
                DebugMenuView(appState: appState, burnerManager: appState.burnerManager)
            }
        }
        // REMOVED: Manual tab bar management - let MainTabView handle it
        // The tab bar visibility is now controlled by the path count in MainTabView
    }
}

// MARK: - Ticket Purchase Destination Wrapper

struct TicketPurchaseDestination: View {
    let event: Event
    @EnvironmentObject var eventViewModel: EventViewModel

    var body: some View {
        TicketPurchaseView(
            event: event,
            viewModel: eventViewModel
        )
    }
}

// MARK: - Ticket Detail Destination Wrapper

struct TicketDetailDestination: View {
    let ticket: Ticket

    @EnvironmentObject var eventViewModel: EventViewModel

    var body: some View {
        Group {
            if let event = eventViewModel.events.first(where: { $0.id == ticket.eventId }) {
                TicketDetailView(ticketWithEvent: TicketWithEventData(ticket: ticket, event: event))
            } else {
                TicketDetailView(ticketWithEvent: TicketWithEventData(
                    ticket: ticket,
                    event: createPlaceholderEvent(from: ticket)
                ))
            }
        }
    }
}

// MARK: - Ticket Detail By ID Destination Wrapper

struct TicketDetailByIdDestination: View {
    let ticketId: String

    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel

    var body: some View {
        Group {
            if let ticket = ticketsViewModel.tickets.first(where: { $0.id == ticketId }) {
                if let event = eventViewModel.events.first(where: { $0.id == ticket.eventId }) {
                    TicketDetailView(ticketWithEvent: TicketWithEventData(ticket: ticket, event: event))
                } else {
                    TicketDetailView(ticketWithEvent: TicketWithEventData(
                        ticket: ticket,
                        event: createPlaceholderEvent(from: ticket)
                    ))
                }
            } else {
                // Ticket not found
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("Ticket Not Found")
                            .foregroundColor(.white)
                            .font(.headline)
                        Text("The ticket you're looking for doesn't exist or has been removed.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// MARK: - Transfer Ticket Destination Wrapper

struct TransferTicketDestination: View {
    let ticket: Ticket

    @EnvironmentObject var eventViewModel: EventViewModel

    var body: some View {
        Group {
            if let event = eventViewModel.events.first(where: { $0.id == ticket.eventId }) {
                TransferTicketView(ticketWithEvent: TicketWithEventData(ticket: ticket, event: event))
            } else {
                TransferTicketView(ticketWithEvent: TicketWithEventData(
                    ticket: ticket,
                    event: createPlaceholderEvent(from: ticket)
                ))
            }
        }
    }
}

// MARK: - Helper Functions

/// Creates a placeholder Event from a Ticket when the full event data is not available
private func createPlaceholderEvent(from ticket: Ticket) -> Event {
    Event(
        id: ticket.eventId,
        name: ticket.eventName,
        venue: ticket.venue,
        startTime: ticket.startTime,
        price: ticket.totalPrice,
        maxTickets: 100,
        ticketsSold: 0,
        imageUrl: "",
        isFeatured: false,
        description: nil
    )
}

// MARK: - Toast Alert View

struct ToastAlertView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .appSectionHeader()
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appBody()
                    .foregroundColor(.white)

                Text(message)
                    .appSecondary()
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding(16)
        .background(Color(white: 0.15))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 10, y: 5)
        .padding(.horizontal, 20)
    }
}
