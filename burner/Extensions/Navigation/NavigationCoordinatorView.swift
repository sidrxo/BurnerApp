import SwiftUI
import Combine

struct NavigationCoordinatorView<Content: View>: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @ViewBuilder let content: Content
    
    @Namespace private var ticketsHeroNamespace

    var body: some View {
        content
            .sheet(item: sheetBinding) { modal in
                modalView(for: modal)
                    .onDisappear {
                        // Handle sheet-specific completion if needed
                    }
            }
            .fullScreenCover(item: fullScreenBinding) { modal in
                modalView(for: modal)
                    .environment(\.heroNamespace, ticketsHeroNamespace)
                    .onDisappear {
                        if case .burnerSetup(let onCompletion) = modal {
                            onCompletion()
                        }
                    }
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
            .overlay {
                if let customAlert = coordinator.activeCustomAlert {
                    CustomAlertView(
                        title: customAlert.title,
                        description: customAlert.message,
                        primaryAction: {
                            customAlert.primaryAction()
                            coordinator.dismissCustomAlert()
                        },
                        primaryActionTitle: customAlert.primaryButtonTitle,
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1002)
                }
            }
    }

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

    @ViewBuilder
    private func modalView(for modal: ModalPresentation) -> some View {
        switch modal {
        case .SetLocation:
            SetLocationModal()
        case .signIn:
            SignInSheetView(
                showingSignIn: Binding(
                    get: { true },
                    set: { newValue in
                        if !newValue {
                            coordinator.dismissModal()
                        }
                    }
                ),
                isOnboarding: false
            )
            
        case .burnerSetup:
            BurnerModeSetupView(
                burnerManager: appState.burnerManager,
                onSkip: {
                    coordinator.dismissModal()
                }
            )

        case .ticketPurchase:
            EmptyView()
            
        case .transferTicket(let ticketWithEvent):
            NavigationView {
                TransferTicketView(ticketWithEvent: ticketWithEvent)
            }

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
        }
    }
}

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

struct NavigationDestinationBuilder: View {
    let destination: NavigationDestination
    @EnvironmentObject var coordinator: NavigationCoordinator
    @EnvironmentObject var appState: AppState
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        Group {
            switch destination {
            case .eventDetail(let eventId):
                EventDetailDestination(eventId: eventId)
                
            case .eventById(let eventId):
                EventDetailDestination(eventId: eventId)

            case .filteredEvents(let sectionDestination):
                FilteredEventsView(title: sectionDestination.title, events: sectionDestination.events)

            case .ticketDetail(let ticketWithEvent, let shouldAnimate):
                TicketDetailView(
                    ticketId: ticketWithEvent.ticket.ticketId ?? "",
                    eventId: ticketWithEvent.ticket.eventId,
                    shouldAnimateFlip: shouldAnimate
                )

            case .ticketById(let ticketId):
                TicketDetailByIdDestination(ticketId: ticketId)

            case .ticketPurchase(let event):
                TicketPurchaseDestination(event: event)

            case .transferTicket(let ticket):
                TransferTicketDestination(ticket: ticket)

            case .transferTicketsList:
                TransferTicketsListView()

            case .settings:
                SettingsView()

            case .accountDetails:
                AccountDetailsView()

            case .bookmarks:
                BookmarksView()

            case .paymentSettings:
                PaymentSettingsView()

            case .scanner:
                ScannerView()
                    .environmentObject(appState)
                    .environmentObject(appState.ticketsViewModel)
                    .environmentObject(appState.eventViewModel)

            case .notifications:
                NotificationsSettingsView()

            case .support:
                SupportView()

            case .debugMenu:
                DebugMenuView(appState: appState, burnerManager: appState.burnerManager)
            }
        }
    }
}

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

struct TicketDetailDestination: View {
    let ticket: Ticket

    @EnvironmentObject var eventViewModel: EventViewModel
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        TicketDetailView(
            ticketId: ticket.ticketId ?? "",
            eventId: ticket.eventId,
            shouldAnimateFlip: false
        )
    }
}

struct TicketDetailByIdDestination: View {
    let ticketId: String

    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel
    @Environment(\.heroNamespace) private var heroNamespace

    var body: some View {
        Group {
            if let ticket = ticketsViewModel.tickets.first(where: { $0.id == ticketId }) {
                TicketDetailView(
                    ticketId: ticket.ticketId ?? "",
                    eventId: ticket.eventId,
                    shouldAnimateFlip: false
                )
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "ticket.fill")
                            .appFont(size: 48)
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

private func createPlaceholderEvent(from ticket: Ticket) -> Event {
    Event(
        id: ticket.eventId,
        name: ticket.eventName,
        venue: ticket.venue,
        startTime: ticket.startTime,
        price: ticket.totalPrice ?? 0.0,
        maxTickets: 100,
        ticketsSold: 0,
        imageUrl: "",
        isFeatured: false,
        description: nil
    )
}

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
