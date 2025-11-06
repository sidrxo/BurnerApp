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
        case .signIn:
            SignInSheetView(showingSignIn: .constant(true))

        case .burnerSetup:
            BurnerModeSetupView(burnerManager: appState.burnerManager)

        case .ticketPurchase(let event, let detent):
            TicketPurchaseDestination(event: event, initialDetent: detent)
                .presentationDetents([detent, .height(320), .height(400)])

        case .ticketDetail(let ticket):
            TicketDetailDestination(ticket: ticket)

        case .shareSheet(let items):
            ActivityViewController(activityItems: items)

        case .cardInput:
            Text("Card Input View") // Placeholder

        case .savedCards:
            Text("Saved Cards View") // Placeholder

        case .passwordlessAuth:
            PasswordlessAuthView(showingSignIn: .constant(true))

        case .addPaymentMethod:
            Text("Add Payment Method") // Placeholder

        case .manualTicketEntry:
            Text("Manual Ticket Entry") // Placeholder

        case .fullScreenQRCode(let ticket):
            // Use the FullScreenQRCodeView from TicketDetailView.swift
            // Create a TicketWithEventData wrapper with a placeholder event
            FullScreenQRCodeView(
                ticketWithEvent: TicketWithEventData(
                    ticket: ticket,
                    event: Event(
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

    var body: some View {
        Group {
            switch destination {
            // Event Navigation
            case .eventDetail(let event):
                EventDetailView(event: event)

            case .eventById(let eventId):
                EventDetailDestination(eventId: eventId)

            case .filteredEvents(let sectionDestination):
                FilteredEventsView(title: sectionDestination.title, events: sectionDestination.events)

            // Ticket Navigation
            case .ticketDetail(let ticket):
                TicketDetailDestination(ticket: ticket)

            case .ticketPurchase(let event):
                TicketPurchaseDestination(event: event, initialDetent: .height(240))

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
                #if DEBUG
                DebugMenuView(appState: appState, burnerManager: appState.burnerManager)
                #else
                EmptyView()
                #endif
            }
        }
        .task {
            // Use task instead of onAppear for better lifecycle management
            coordinator.hideTabBar()
        }
        .onDisappear {
            // Ensure tab bar is shown when leaving any detail view
            Task { @MainActor in
                coordinator.showTabBar()
            }
        }
    }
}

// MARK: - Ticket Purchase Destination Wrapper

struct TicketPurchaseDestination: View {
    let event: Event
    let initialDetent: PresentationDetent

    @EnvironmentObject var eventViewModel: EventViewModel
    @State private var selectedDetent: PresentationDetent

    init(event: Event, initialDetent: PresentationDetent) {
        self.event = event
        self.initialDetent = initialDetent
        _selectedDetent = State(initialValue: initialDetent)
    }

    var body: some View {
        TicketPurchaseView(
            event: event,
            viewModel: eventViewModel,
            selectedDetent: $selectedDetent
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
                // Create placeholder event if event data is missing
                TicketDetailView(ticketWithEvent: TicketWithEventData(
                    ticket: ticket,
                    event: Event(
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
                ))
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
                // Create placeholder event if event data is missing
                TransferTicketView(ticketWithEvent: TicketWithEventData(
                    ticket: ticket,
                    event: Event(
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
                ))
            }
        }
    }
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
                .font(.system(size: 24))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 13))
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
