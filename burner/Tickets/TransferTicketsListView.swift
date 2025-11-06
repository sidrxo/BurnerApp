import SwiftUI

struct TransferTicketsListView: View {
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var eventViewModel: EventViewModel

    private var ticketsWithEvents: [TicketWithEventData] {
        var result: [TicketWithEventData] = []
        for ticket in ticketsViewModel.tickets {
            // Only show confirmed tickets
            guard ticket.status == "confirmed" else { continue }

            if let event = eventViewModel.events.first(where: { $0.id == ticket.eventId }) {
                result.append(TicketWithEventData(ticket: ticket, event: event))
            } else {
                // Create a placeholder event if event data is missing
                let placeholderEvent = Event(
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
                var eventWithId = placeholderEvent
                eventWithId.id = ticket.eventId
                result.append(TicketWithEventData(ticket: ticket, event: eventWithId))
            }
        }
        return result.sorted {
            ($0.event.startTime ?? Date.distantFuture) < ($1.event.startTime ?? Date.distantFuture)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderSection(title: "Transfer Tickets")
                .padding(.horizontal, 20)
                .padding(.top, 20)

            if ticketsViewModel.isLoading && ticketsViewModel.tickets.isEmpty {
                loadingView
            } else if ticketsWithEvents.isEmpty {
                emptyStateView
            } else {
                ticketsList
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            Text("Loading tickets...")
                .appBody()
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ticket")
                .appHero()
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Tickets to Transfer")
                    .appSectionHeader()
                    .foregroundColor(.white)

                Text("You don't have any tickets that can be transferred")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .padding(.bottom, 100)
    }

    private var ticketsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(ticketsWithEvents, id: \.id) { ticketWithEvent in
                    NavigationLink(destination: TransferTicketView(ticketWithEvent: ticketWithEvent)) {
                        EventRow(
                            ticketWithEvent: ticketWithEvent,
                            isPast: false,
                            onCancel: {}
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 100)
        }
        .background(Color.black)
    }
}
