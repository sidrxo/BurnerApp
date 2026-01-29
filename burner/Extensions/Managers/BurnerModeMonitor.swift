import Foundation
import Supabase
import Combine
import FamilyControls

@MainActor
class BurnerModeMonitor: ObservableObject {
    @Published var shouldEnableBurnerMode = false
    @Published var isMonitoring = false
    
    private let appState: AppState
    private let client = SupabaseManager.shared.client
    private var subscriptionTask: Task<Void, Never>?
    private let burnerManager: BurnerModeManager
    private var ticketsChangeCancellable: AnyCancellable?
    
    init(appState: AppState, burnerManager: BurnerModeManager) {
        self.appState = appState
        self.burnerManager = burnerManager
    }
    
    deinit {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        ticketsChangeCancellable?.cancel()
    }
    
    // MARK: - Start Monitoring
    func startMonitoring() {
        // Stop any existing monitoring
        stopMonitoring()

        // Set up listener for ticket changes
        setupTicketChangeListener()

        // Do initial check
        Task {
            await checkShouldMonitor()
        }
    }
    
    // MARK: - Setup Ticket Change Listener
    private func setupTicketChangeListener() {
        // Listen to ticketsViewModel for any ticket changes
        ticketsChangeCancellable = appState.ticketsViewModel.$tickets
            .dropFirst() // Skip initial value
            .sink { [weak self] tickets in
                guard let self = self else { return }

                Task { @MainActor in
                    await self.checkShouldMonitor()
                }
            }
    }
    
    // MARK: - Check if Should Monitor
    private func checkShouldMonitor() async {
        // Check if user has tickets for today's events
        let todayTickets = getTodaysEventTickets()

        if !todayTickets.isEmpty {
            // User has tickets for today - start real-time monitoring
            if !isMonitoring {
                await startRealtimeMonitoring()
            }

            // Also check if any tickets meet burner mode criteria
            await checkTicketsForBurnerMode(todayTickets)
        } else {
            // No tickets for today - stop monitoring
            if isMonitoring {
                stopRealtimeMonitoring()
            }
        }
    }
    
    // MARK: - Get Today's Event Tickets
    private func getTodaysEventTickets() -> [Ticket] {
        let calendar = Calendar.current
        let now = Date()
        
        // Define "today's events" as:
        // - Events that started today OR yesterday (to handle past-midnight events)
        // - Events that haven't ended yet (end_time > now)
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!
        
        return appState.ticketsViewModel.tickets.filter { ticket in
            // Only consider confirmed tickets
            guard ticket.status == "confirmed" || ticket.status == "used" else {
                return false
            }
            
            let eventStart = ticket.startTime
            
            // Event started between yesterday and tomorrow
            guard eventStart >= yesterday && eventStart < tomorrow else {
                return false
            }
            
            // If event hasn't started yet, include it
            if eventStart > now {
                return true
            }
            
            // Event has started - check if it's still ongoing
            // Assume events last max 8 hours if no end time specified
            let eventEnd = calendar.date(byAdding: .hour, value: 8, to: eventStart)!
            return now < eventEnd
        }
    }
    
    // MARK: - Start Real-time Monitoring
    private func startRealtimeMonitoring() async {
        guard let userId = await getCurrentUserId() else {
            return
        }

        // Cancel any existing subscription
        subscriptionTask?.cancel()

        subscriptionTask = Task {
            let channelName = "burner-tickets-\(userId)-\(UUID().uuidString)"
            let channel = client.realtimeV2.channel(channelName)

            // Use typed filter syntax (matching TicketRepository pattern)
            let updateStream = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "tickets",
                filter: .eq("user_id", value: userId.lowercased())
            )

            do {
                try await channel.subscribeWithError()

                await MainActor.run {
                    self.isMonitoring = true
                }

                // Listen for updates using async iteration
                for await _ in updateStream {
                    guard !Task.isCancelled else { break }

                    await MainActor.run {
                        Task {
                            await self.checkShouldMonitor()
                        }
                    }
                }

                await channel.unsubscribe()
            } catch {
                // Handle subscription error silently
                print("Channel subscription error: \(error)")
            }

            await MainActor.run {
                self.isMonitoring = false
            }
        }
    }
    
    // MARK: - Stop Real-time Monitoring
    private func stopRealtimeMonitoring() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
        isMonitoring = false
    }
    
    // MARK: - Check Tickets for Burner Mode
    private func checkTicketsForBurnerMode(_ tickets: [Ticket]) async {
        let now = Date()

        for ticket in tickets {
            // Skip if not scanned
            guard ticket.status == "used", ticket.usedAt != nil else {
                continue
            }

            let eventStart = ticket.startTime

            // Check if event has started
            if now >= eventStart {
                await enableBurnerMode()
                return // Exit after enabling once
            }
        }
    }
    
    // MARK: - Enable Burner Mode
    private func enableBurnerMode() async {
        // Check if already enabled
        guard !UserDefaults.standard.bool(forKey: "burnerModeEnabled") else {
            return
        }

        // Check if setup is valid
        guard burnerManager.isSetupValid else {
            return
        }

        do {
            try await burnerManager.enable(appState: appState)
            shouldEnableBurnerMode = true

            NotificationCenter.default.post(
                name: NSNotification.Name("BurnerModeAutoEnabled"),
                object: nil
            )
        } catch {
            // Silent fail
        }
    }
    
    // MARK: - Stop Monitoring
    func stopMonitoring() {
        stopRealtimeMonitoring()
        ticketsChangeCancellable?.cancel()
        ticketsChangeCancellable = nil
    }

    // MARK: - Manual Check
    func checkNow() async {
        await checkShouldMonitor()
    }

    // MARK: - Get Monitor Status
    func getMonitorStatus() async -> String {
        guard let userId = await getCurrentUserId() else {
            return "❌ No user logged in"
        }

        let todayTickets = getTodaysEventTickets()
        let scannedTickets = todayTickets.filter { $0.status == "used" }
        let isSetupValid = burnerManager.isSetupValid
        let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")

        var status = "Monitor Status:\n"
        status += "- User ID: \(userId.prefix(8))...\n"
        status += "- Real-time Monitoring: \(isMonitoring ? "✅" : "❌")\n"
        status += "- Today's Tickets: \(todayTickets.count)\n"
        status += "- Scanned Tickets: \(scannedTickets.count)\n"
        status += "- Setup Valid: \(isSetupValid ? "✅" : "❌")\n"
        status += "- Burner Mode Active: \(isEnabled ? "✅" : "❌")\n"
        status += "- Categories: \(burnerManager.selectedApps.categoryTokens.count)/\(burnerManager.minimumCategoriesRequired)\n"
        status += "- Apps: \(burnerManager.selectedApps.applicationTokens.count)"

        return status
    }
    
    // MARK: - Helper
    private func getCurrentUserId() async -> String? {
        guard let session = try? await client.auth.session else {
            return nil
        }
        return session.user.id.uuidString
    }
}
