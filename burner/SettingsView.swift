import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls
import ManagedSettings
import Combine


struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var showingAppPicker = false
    @State private var showingBurnerSetup = false
    
    private let db = Firestore.firestore()
    
    // Use shared burner manager from AppState
    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }
    
    // Access role and scanner status from AppState
    private var userRole: String {
        appState.userRole
    }
    
    private var isScannerActive: Bool {
        appState.isScannerActive
    }
    
    // Check if burner mode needs setup
    private var needsBurnerSetup: Bool {
        !burnerManager.isSetup || !burnerManager.isAuthorized
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Only show header when signed in
                if currentUser != nil {
                    HeaderSection(title: "Settings")
                }
                
                if currentUser != nil {
                    ScrollView {
                        VStack(spacing: 0) {
                            // ACCOUNT Section
                            CustomMenuSection(title: "ACCOUNT") {
                                NavigationLink(destination: AccountDetailsView()) {
                                    CustomMenuItemContent(
                                        title: "Account Details",
                                        subtitle: currentUser?.email ?? "View Account"
                                    )
                                }
                                
                                NavigationLink(destination: BookmarksView()) {
                                    CustomMenuItemContent(
                                        title: "Bookmarks",
                                        subtitle: "Saved events"
                                    )
                                }
                                
                                NavigationLink(destination: PaymentSettingsView()) {
                                    CustomMenuItemContent(
                                        title: "Payment",
                                        subtitle: "Cards & billing"
                                    )
                                }
                                
                                NavigationLink(destination: TransferTicketsListView()) {
                                    CustomMenuItemContent(
                                        title: "Transfer Tickets",
                                        subtitle: "Transfer your ticket to another user"
                                    )
                                }
                                
                                // Scanner access for authorized roles
                                if (userRole == "scanner" && isScannerActive) ||
                                    userRole == "siteAdmin" ||
                                    userRole == "venueAdmin" ||
                                    userRole == "subAdmin" {
                                    NavigationLink(destination: ScannerView()) {
                                        CustomMenuItemContent(
                                            title: "Scanner",
                                            subtitle: "Scan QR codes"
                                        )
                                    }
                                }
                            }
                            
                            // APP Section
                            CustomMenuSection(title: "APP") {
                                // Show Setup Guide Button only when needed
                                if needsBurnerSetup {
                                    Button(action: {
                                        showingBurnerSetup = true
                                    }) {
                                        CustomMenuItemContent(
                                            title: "Setup Burner Mode",
                                            subtitle: burnerManager.isAuthorized
                                                ? "Configure app blocking"
                                                : "Screen Time permissions needed"
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                NavigationLink(destination: SupportView()) {
                                    CustomMenuItemContent(
                                        title: "Help & Support",
                                        subtitle: "Get help, terms, privacy"
                                    )
                                }
                            }
                            
                            // DEBUG Section
                            #if DEBUG
                            CustomMenuSection(title: "DEBUG") {
                                NavigationLink(
                                    destination: DebugMenuView(
                                        appState: appState,
                                        burnerManager: burnerManager
                                    )
                                ) {
                                    CustomMenuItemContent(
                                        title: "Debug Menu",
                                        subtitle: "Development tools"
                                    )
                                }
                            }
                            #endif
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .familyActivityPicker(
                        isPresented: $showingAppPicker,
                        selection: Binding(
                            get: { burnerManager.selectedApps },
                            set: { burnerManager.selectedApps = $0 }
                        )
                    )
                } else {
                    notSignedInSection
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentUser = Auth.auth().currentUser
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))) { _ in
            currentUser = nil
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn)
        }
        .fullScreenCover(isPresented: $showingBurnerSetup) {
            BurnerModeSetupView(burnerManager: burnerManager)
        }
    }
    
    // MARK: - Not signed in view
    private var notSignedInSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.crop.circle")
                .font(.appLargeIcon)
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Not Signed In")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Text("Sign in to access your settings")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingSignIn = true
            } label: {
                Text("Sign In")
                    .appBody()
                    .foregroundColor(.black)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Custom Menu Section
struct CustomMenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .appCaption()
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Custom Menu Item Content
struct CustomMenuItemContent: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appBody()
                    .foregroundColor(.white)
                Text(subtitle)
                    .appSecondary()
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .appCaption()
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Transfer Tickets List View
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
                        UnifiedEventRow(
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
