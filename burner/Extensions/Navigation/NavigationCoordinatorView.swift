import SwiftUI
import Shared

struct NavigationCoordinatorView: View {
    @StateObject var coordinator = NavigationCoordinator()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            // Main Tab View is the root
            MainTabView()
                .navigationDestination(for: Destination.self) { destination in
                    buildView(for: destination)
                }
        }
        .environmentObject(coordinator)
    }
    
    @ViewBuilder
    func buildView(for destination: Destination) -> some View {
        switch destination {
        case .eventDetail(let event):
            EventDetailView(event: event)
                .environmentObject(appState.eventViewModel)
                .environmentObject(appState.ticketsViewModel)
            
        case .ticketDetail(let data, _):
            TicketDetailView(ticket: data.ticket, event: data.event)
            
        case .ticketPurchase(let event):
            TicketPurchaseView(event: event, viewModel: appState.eventViewModel)
            
        case .scanner:
            ScannerView()
            
        case .admin:
            Text("Admin View Placeholder") // Replace with AdminView if available
            
        case .settings:
            SettingsView()
        }
    }
}
