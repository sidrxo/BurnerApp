import SwiftUI
import Supabase

struct DebugMenuView: View {
    @ObservedObject var appState: AppState
    let burnerManager: BurnerModeManager
    @AppStorage("useWalletView") private var useWalletView = true
    @State private var showBurnerError = false
    @State private var burnerErrorMessage = ""
    @State private var showResetConfirmation = false
    @State private var showNotificationScheduled = false
    
    // MARK: - New State for Presentation
    @State private var showBurnerModeSetup = false
    @State private var showOnboardingFlow = false
    @State private var showLoadingSuccess = false
    @State private var isLoadingSuccess = true
    
    // MARK: - Ticket Debug States
    @State private var showTicketDebug = false
    @State private var ticketDebugInfo: [String] = []
    @State private var isLoadingDebug = false

    // Three states: no event, before event starts, during event
    enum EventState {
        case noEvent
        case beforeEvent
        case duringEvent
    }
    @State private var eventState: EventState = .noEvent
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderSection(title: "Debug Menu", includeTopPadding: false, includeHorizontalPadding: false)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - TICKET DEBUG SECTION (NEW)
                    MenuSection(title: "TICKET DEBUG") {
                        Button(action: {
                            runTicketDiagnostic()
                        }) {
                            MenuItemContent(
                                title: "Run Ticket Diagnostic",
                                subtitle: isLoadingDebug ? "Running..." : "Check why tickets aren't showing"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isLoadingDebug)
                        
                        Button(action: {
                            showTicketDebug.toggle()
                        }) {
                            MenuItemContent(
                                title: showTicketDebug ? "Hide Debug Log" : "Show Debug Log",
                                subtitle: "\(ticketDebugInfo.count) log entries"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(ticketDebugInfo.isEmpty)
                        
                        Button(action: {
                            createTestTicket()
                        }) {
                            MenuItemContent(
                                title: "Create Test Ticket",
                                subtitle: "Add a ticket to database for current user"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isLoadingDebug)
                    }
                    
                    // Show debug log if toggled
                    if showTicketDebug && !ticketDebugInfo.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(ticketDebugInfo.indices, id: \.self) { index in
                                Text(ticketDebugInfo[index])
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(
                                        ticketDebugInfo[index].contains("❌") ? .red :
                                        ticketDebugInfo[index].contains("✅") ? .green :
                                        ticketDebugInfo[index].contains("⚠️") ? .orange :
                                        .gray
                                    )
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    MenuSection(title: "APP DATA") {
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            MenuItemContent(
                                title: "Reset App to First Install",
                                subtitle: "Clear all data and settings"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            if appState.isSimulatingEmptyFirestore {
                                appState.disableEmptyFirestoreSimulation()
                            } else {
                                appState.enableEmptyFirestoreSimulation()
                            }
                        }) {
                            MenuItemContent(
                                title: appState.isSimulatingEmptyFirestore ? "Restore Data" : "Simulate Empty Data",
                                subtitle: appState.isSimulatingEmptyFirestore
                                    ? "Resume live events, tickets, and venues"
                                    : "Show empty states with no events, tickets, or venues"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    MenuSection(title: "BURNER MODE") {
                        Button(action: {
                            toggleBurnerMode()
                        }) {
                            MenuItemContent(
                                title: appState.showingBurnerLockScreen ? "Disable Burner Mode (Toggle)" : "Enable Burner Mode (Toggle)",
                                subtitle: appState.showingBurnerLockScreen ? "Currently active" : "Test Burner Mode"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            burnerManager.disable()
                            appState.showingBurnerLockScreen = false
                        }) {
                            MenuItemContent(
                                title: "Force Disable Burner Mode",
                                subtitle: "Instantly removes all Screen Time restrictions"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!appState.showingBurnerLockScreen)
                        
                        Button(action: {
                            burnerManager.scheduleTestNotification(delay: 10)
                            showNotificationScheduled = true
                        }) {
                            MenuItemContent(
                                title: "Test Event End Notification",
                                subtitle: "Sends 'Event Ended' notification in 10 seconds"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            burnerManager.scheduleTestBurnerSetupReminder()
                            showNotificationScheduled = true
                        }) {
                            MenuItemContent(
                                title: "Test Burner Setup Reminder",
                                subtitle: "Sends 'Complete Burner Mode Setup' notification"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    MenuSection(title: "ONBOARDING & FLOWS") {
                        Button(action: {
                            appState.onboardingManager.resetOnboarding()
                            showOnboardingFlow = true
                        }) {
                            MenuItemContent(
                                title: "Show Onboarding Flow",
                                subtitle: "Shows Sign-In then Burner Setup flow"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            showBurnerModeSetup = true
                        }) {
                            MenuItemContent(
                                title: "Show Burner Mode Setup",
                                subtitle: "Directly launch the 6-step setup guide"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    MenuSection(title: "UI COMPONENTS") {
                        Button(action: {
                            isLoadingSuccess = true
                            showLoadingSuccess = true
                        }) {
                            MenuItemContent(
                                title: "Show Loading Success Animation",
                                subtitle: "Test spinner → circle fill → checkmark"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    MenuSection(title: "LIVE ACTIVITY") {
                        Button(action: {
                            cycleEventState()
                        }) {
                            MenuItemContent(
                                title: eventStateTitle,
                                subtitle: eventStateSubtitle
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Burner Mode Error", isPresented: $showBurnerError) {
            Button("OK") { }
        } message: {
            Text(burnerErrorMessage)
        }
        .alert("Reset App?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
            }
        } message: {
            Text("This will clear all app data, sign you out, and reset the app to its first install state. This action cannot be undone.")
        }
        .alert("Notification Scheduled", isPresented: $showNotificationScheduled) {
            Button("OK") { }
        } message: {
            Text("The notification will appear in 10 seconds.")
        }
        .fullScreenCover(isPresented: $showOnboardingFlow) {
            OnboardingFlowView()
                .environmentObject(appState.onboardingManager)
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showBurnerModeSetup) {
            BurnerModeSetupView(
                burnerManager: burnerManager,
                onSkip: { showBurnerModeSetup = false }
            )
        }
        .fullScreenCover(isPresented: $showLoadingSuccess) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    LoadingSuccessView(
                        isLoading: $isLoadingSuccess
                    )
                    
                    Button(action: {
                        if isLoadingSuccess {
                            isLoadingSuccess = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                showLoadingSuccess = false
                            }
                        } else {
                            isLoadingSuccess = true
                        }
                    }) {
                        Text(isLoadingSuccess ? "Complete Loading" : "Loading...")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(!isLoadingSuccess)
                    
                    Button(action: {
                        showLoadingSuccess = false
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Ticket Diagnostic Functions
    
    private func log(_ message: String) {
        DispatchQueue.main.async {
            ticketDebugInfo.append(message)
            print("🔍 TICKET DEBUG: \(message)")
        }
    }
    
    private func runTicketDiagnostic() {
        ticketDebugInfo = []
        isLoadingDebug = true
        showTicketDebug = true
        
        Task {
            let client = SupabaseManager.shared.client
            let authService = appState.authService // Reference AppState's service
            
            log("=== AUTH & TICKET DIAGNOSTIC STARTED ===")
            log("")
            
            // ==========================================================
            // 1. CHECK APPSTATE & SUPABASE SESSION SYNC
            // ==========================================================
            log("1️⃣ CHECKING AUTH SYNC...")
            
            // A. Check AppState's observed user
            let appStateUser = authService.currentUser
            if appStateUser != nil {
                log("✅ AppState User: Present (\(appStateUser?.id.uuidString.prefix(8) ?? "N/A")...)")
            } else {
                log("❌ AppState User: NIL. (TicketsViewModel won't fetch data.)")
            }
            
            // B. Check Supabase SDK's session
            do {
                let session = try await client.auth.session
                log("✅ Supabase Session: Active")
                log("   User ID: \(session.user.id.uuidString)")
                log("   Email: \(session.user.email ?? "N/A")")
                
                // C. Check for ID mismatch (rare, but possible)
                if appStateUser?.id.uuidString != session.user.id.uuidString {
                    log("⚠️ ID MISMATCH: AppState and Supabase SDK IDs differ.")
                }
                
                log("")
                
                let userId = session.user.id.uuidString
                
                // ==========================================================
                // 2. CHECK USER PROFILE IN DB
                // ==========================================================
                log("2️⃣ CHECKING USER PROFILE...")
                do {
                    let userProfile = try await authService.getUserProfile()
                    if let profile = userProfile {
                        log("✅ Profile Fetched. Role: \(profile.role)")
                        log("   Display Name: \(profile.displayName)")
                    } else {
                        log("❌ Profile NOT Found. This might cause downstream issues.")
                    }
                } catch {
                    log("❌ Profile Fetch FAILED: \(error.localizedDescription)")
                }
                
                log("")
                
                // 3. Check table exists and count ALL tickets
                log("3️⃣ CHECKING TICKETS TABLE...")
                do {
                    // Try to fetch ALL tickets (ignoring userId)
                    let response = try await client
                        .from("tickets")
                        .select("*", head: true, count: .exact)
                        .execute()
                    
                    let totalCount = response.count ?? 0
                    log("✅ Tickets table exists")
                    log("   Total tickets in DB: \(totalCount)")
                    
                    if totalCount == 0 {
                        log("❌ DATABASE IS EMPTY!")
                        log("   No tickets exist at all")
                        log("   → Use 'Create Test Ticket' button")
                        log("")
                    } else {
                        log("")
                        
                        // 4. Fetch sample ticket to check structure
                        log("4️⃣ CHECKING TICKET STRUCTURE...")
                        struct TicketRaw: Codable {
                            let id: String?
                            let userId: String?
                            let user_id: String?
                            let eventName: String?
                            let event_name: String?
                            
                            enum CodingKeys: String, CodingKey {
                                case id
                                case userId
                                case user_id
                                case eventName
                                case event_name
                            }
                        }
                        
                        let sample: [TicketRaw] = try await client
                            .from("tickets")
                            .select()
                            .limit(1)
                            .execute()
                            .value
                        
                        if let first = sample.first {
                            if first.userId != nil {
                                log("✅ Using camelCase (userId)")
                            } else if first.user_id != nil {
                                log("⚠️ Using snake_case (user_id)")
                                log("   → Your Ticket model needs CodingKeys!")
                            }
                            
                            if first.eventName != nil {
                                log("✅ Using camelCase (eventName)")
                            } else if first.event_name != nil {
                                log("⚠️ Using snake_case (event_name)")
                            }
                        }
                        log("")
                        
                        // 5. Check tickets for current user
                        log("5️⃣ CHECKING YOUR TICKETS...")
                        let userResponse = try await client
                            .from("tickets")
                            .select("*", head: true, count: .exact)
                            .eq("userId", value: userId)
                            .execute()
                        
                        let userTicketCount = userResponse.count ?? 0
                        log("   Tickets for your user: \(userTicketCount)")
                        
                        if userTicketCount == 0 {
                            log("❌ YOU HAVE NO TICKETS!")
                            log("   Other users have tickets, but not you")
                            log("   → Use 'Create Test Ticket' button")
                        } else {
                            log("✅ You have \(userTicketCount) ticket(s)")
                            log("")
                            
                            // 6. Try to actually fetch them (Deserialization check)
                            log("6️⃣ FETCHING YOUR TICKETS...")
                            do {
                                let tickets: [Ticket] = try await client
                                    .from("tickets")
                                    .select()
                                    .eq("userId", value: userId)
                                    .execute()
                                    .value
                                
                                log("✅ Successfully fetched!")
                                log("   Count: \(tickets.count)")
                                
                                for (i, ticket) in tickets.prefix(3).enumerated() {
                                    log("   [\(i+1)] \(ticket.eventName)")
                                    log("       Status: \(ticket.status)")
                                }
                                log("")
                                
                                // 7. Check TicketsViewModel
                                log("7️⃣ CHECKING VIEW MODEL...")
                                log("   VM tickets count: \(appState.ticketsViewModel.tickets.count)")
                                log("   VM is loading: \(appState.ticketsViewModel.isLoading)")
                                
                                if appState.ticketsViewModel.tickets.isEmpty && !tickets.isEmpty {
                                    log("❌ FOUND THE PROBLEM!")
                                    log("   Database has tickets, but ViewModel is empty")
                                    log("   → Try calling fetchUserTickets()")
                                    log("")
                                    
                                    // Try to force refresh
                                    log("8️⃣ FORCING REFRESH...")
                                    await MainActor.run {
                                        appState.ticketsViewModel.fetchUserTickets()
                                    }
                                    
                                    // Wait a bit
                                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                                    
                                    await MainActor.run {
                                        log("   After refresh: \(appState.ticketsViewModel.tickets.count) tickets")
                                        if appState.ticketsViewModel.tickets.isEmpty {
                                            log("❌ Still empty! Check observeUserTickets()")
                                        } else {
                                            log("✅ FIXED! Tickets now visible")
                                        }
                                    }
                                }
                                
                            } catch {
                                log("❌ Failed to fetch tickets")
                                log("   Error: \(error.localizedDescription)")
                                log("   → Check Ticket model CodingKeys")
                            }
                        }
                    }
                    
                } catch {
                    log("❌ Can't access tickets table")
                    log("   Error: \(error.localizedDescription)")
                }
                
            } catch {
                log("❌ Not authenticated")
                log("   Error: \(error.localizedDescription)")
            }
            
            log("")
            log("=== DIAGNOSTIC COMPLETE ===")
            
            await MainActor.run {
                isLoadingDebug = false
            }
        }
    }
    
    private func createTestTicket() {
        isLoadingDebug = true
        ticketDebugInfo = []
        showTicketDebug = true
        
        Task {
            let client = SupabaseManager.shared.client
            
            log("=== CREATING TEST TICKET ===")
            
            do {
                // Get current user
                let session = try await client.auth.session
                let userId = session.user.id.uuidString
                log("✅ User ID: \(userId)")
                
                // Get an event (or create fake ID)
                log("📋 Fetching an event...")
                let events: [Event] = try await client
                    .from("events")
                    .select()
                    .limit(1)
                    .execute()
                    .value
                
                let eventId: String
                let eventName: String
                let venue: String
                let startTime: Date
                
                if let event = events.first {
                    eventId = event.id ?? UUID().uuidString
                    eventName = event.name
                    venue = event.venue
                    startTime = event.startTime ?? Date().addingTimeInterval(86400 * 7)
                    log("✅ Using real event: \(eventName)")
                } else {
                    eventId = UUID().uuidString
                    eventName = "Test Event"
                    venue = "Test Venue"
                    startTime = Date().addingTimeInterval(86400 * 7)
                    log("⚠️ No events found, using fake data")
                }
                
                // Create ticket
                log("🎫 Creating ticket...")
                
                struct TicketInsert: Encodable {
                    let id: String
                    let userId: String
                    let eventId: String
                    let ticketNumber: String
                    let eventName: String
                    let venue: String
                    let startTime: Date
                    let totalPrice: Double
                    let purchaseDate: Date
                    let status: String
                    let qrCode: String
                }
                
                let ticket = TicketInsert(
                    id: UUID().uuidString,
                    userId: userId,
                    eventId: eventId,
                    ticketNumber: "DEBUG-\(Int.random(in: 1000...9999))",
                    eventName: eventName,
                    venue: venue,
                    startTime: startTime,
                    totalPrice: 25.00,
                    purchaseDate: Date(),
                    status: "confirmed",
                    qrCode: "DEBUG-QR-\(UUID().uuidString)"
                )
                
                try await client
                    .from("tickets")
                    .insert(ticket)
                    .execute()
                
                log("✅ TICKET CREATED!")
                log("   Event: \(eventName)")
                log("   Venue: \(venue)")
                log("")
                
                // Refresh ViewModel
                log("🔄 Refreshing tickets...")
                await MainActor.run {
                    appState.ticketsViewModel.fetchUserTickets()
                }
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    log("✅ ViewModel now has \(appState.ticketsViewModel.tickets.count) ticket(s)")
                    log("")
                    log("=== SUCCESS ===")
                    log("Check your Tickets tab!")
                }
                
            } catch {
                log("❌ Failed to create ticket")
                log("   Error: \(error.localizedDescription)")
            }
            
            await MainActor.run {
                isLoadingDebug = false
            }
        }
    }
    
    // MARK: - Original Functions
    
    private var eventStateTitle: String {
        switch eventState {
        case .noEvent:
            return "Create Event Later Today"
        case .beforeEvent:
            return "Start Event Now"
        case .duringEvent:
            return "Clear Debug Event"
        }
    }
    
    private var eventStateSubtitle: String {
        switch eventState {
        case .noEvent:
            return "Shows event time before start"
        case .beforeEvent:
            return "Event time shown with event info"
        case .duringEvent:
            return "Event in progress with progress bar"
        }
    }

    private func toggleBurnerMode() {
        if appState.showingBurnerLockScreen {
            burnerManager.disable()
            appState.showingBurnerLockScreen = false
        } else {
            if burnerManager.isSetupValid {
                Task {
                    do {
                        try await burnerManager.enable(appState: appState)
                        await MainActor.run {
                            appState.showingBurnerLockScreen = true
                        }
                    } catch BurnerModeError.notAuthorized {
                        await MainActor.run {
                            burnerErrorMessage = "Screen Time authorization required"
                            showBurnerError = true
                        }
                    } catch BurnerModeError.invalidSetup(let message) {
                        await MainActor.run {
                            burnerErrorMessage = message
                            showBurnerError = true
                        }
                    } catch {
                        await MainActor.run {
                            burnerErrorMessage = "Unexpected error: \(error.localizedDescription)"
                            showBurnerError = true
                        }
                    }
                }
            } else {
                burnerErrorMessage = "Burner mode setup not valid"
                showBurnerError = true
            }
        }
    }
    
    private func cycleEventState() {
        switch eventState {
        case .noEvent:
            appState.simulateEventBeforeStart()
            eventState = .beforeEvent
            
        case .beforeEvent:
            appState.clearDebugEventToday()
            appState.simulateEventDuringEvent()
            eventState = .duringEvent
            
        case .duringEvent:
            appState.clearDebugEventToday()
            eventState = .noEvent
        }
    }
}
