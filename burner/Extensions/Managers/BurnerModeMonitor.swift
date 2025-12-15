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
        print("🔥 BurnerModeMonitor: Starting monitoring...")
        
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
                
                print("🎫 BurnerModeMonitor: Tickets changed, checking conditions...")
                
                Task { @MainActor in
                    await self.checkShouldMonitor()
                }
            }
    }
    
    // MARK: - Check if Should Monitor
    private func checkShouldMonitor() async {
        // Check if user has tickets for today's events
        let todayTickets = getTodaysEventTickets()
        
        print("📋 BurnerModeMonitor: Found \(todayTickets.count) tickets for today's events")
        
        if !todayTickets.isEmpty {
            // User has tickets for today - start real-time monitoring
            if !isMonitoring {
                print("✅ BurnerModeMonitor: User has tickets for today, starting real-time monitoring")
                await startRealtimeMonitoring()
            }
            
            // Also check if any tickets meet burner mode criteria
            await checkTicketsForBurnerMode(todayTickets)
        } else {
            // No tickets for today - stop monitoring
            if isMonitoring {
                print("ℹ️ BurnerModeMonitor: No tickets for today, stopping monitoring")
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
            print("❌ BurnerModeMonitor: No user ID for real-time monitoring")
            return
        }
        
        // Cancel any existing subscription
        subscriptionTask?.cancel()
        
        subscriptionTask = Task {
            let channel = await client.channel("burner-tickets:\(userId)")
            
            await channel.onPostgresChange(
                AnyAction.self,
                schema: "public",
                table: "tickets",
                filter: "user_id=eq.\(userId)"
            ) { [weak self] payload in
                guard let self = self else { return }
                
                print("🔔 BurnerModeMonitor: Real-time ticket change detected")
                
                Task { @MainActor in
                    // Re-check all conditions
                    await self.checkShouldMonitor()
                }
            }
            
            await channel.subscribe()
            
            await MainActor.run {
                self.isMonitoring = true
            }
            
            print("✅ BurnerModeMonitor: Real-time subscription active")
            
            // Keep the task alive
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            
            await channel.unsubscribe()
            
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
        print("🛑 BurnerModeMonitor: Real-time monitoring stopped")
    }
    
    // MARK: - Check Tickets for Burner Mode
    private func checkTicketsForBurnerMode(_ tickets: [Ticket]) async {
        let now = Date()
        
        print("🔍 BurnerModeMonitor: Checking \(tickets.count) tickets for burner mode criteria...")
        
        for ticket in tickets {
            // Skip if not scanned
            guard ticket.status == "used", let scannedAt = ticket.usedAt else {
                print("  ⏭️ Ticket \(ticket.ticketNumber ?? "unknown") - not scanned yet")
                continue
            }
            
            let eventStart = ticket.startTime
            
            print("  🎫 Ticket \(ticket.ticketNumber ?? "unknown"):")
            print("     - Scanned: \(scannedAt)")
            print("     - Event start: \(eventStart)")
            print("     - Current time: \(now)")
            
            // Check if event has started
            if now >= eventStart {
                print("     ✅ Event has started! Enabling burner mode...")
                await enableBurnerMode()
                return // Exit after enabling once
            } else {
                let timeUntilStart = eventStart.timeIntervalSince(now)
                let minutesUntilStart = Int(timeUntilStart / 60)
                print("     ⏳ Event starts in \(minutesUntilStart) minutes")
            }
        }
        
        print("ℹ️ BurnerModeMonitor: No tickets meet burner mode criteria yet")
    }
    
    // MARK: - Enable Burner Mode
    private func enableBurnerMode() async {
        // Check if already enabled
        guard !UserDefaults.standard.bool(forKey: "burnerModeEnabled") else {
            print("ℹ️ BurnerModeMonitor: Burner mode already enabled")
            return
        }
        
        // Check if setup is valid
        guard burnerManager.isSetupValid else {
            print("⚠️ BurnerModeMonitor: Burner mode setup not valid")
            print("   - Authorized: \(burnerManager.isAuthorized)")
            print("   - Categories: \(burnerManager.selectedApps.categoryTokens.count)/\(burnerManager.minimumCategoriesRequired)")
            return
        }

        print("🔥 BurnerModeMonitor: Enabling burner mode...")

        do {
            try await burnerManager.enable(appState: appState)
            shouldEnableBurnerMode = true

            NotificationCenter.default.post(
                name: NSNotification.Name("BurnerModeAutoEnabled"),
                object: nil
            )
            
            print("✅ BurnerModeMonitor: Burner mode enabled successfully")
        } catch BurnerModeError.notAuthorized {
            print("❌ BurnerModeMonitor: Not authorized for Screen Time")
        } catch BurnerModeError.invalidSetup(let reason) {
            print("❌ BurnerModeMonitor: Invalid setup - \(reason)")
        } catch {
            print("❌ BurnerModeMonitor: Error enabling burner mode: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Stop Monitoring
    func stopMonitoring() {
        stopRealtimeMonitoring()
        ticketsChangeCancellable?.cancel()
        ticketsChangeCancellable = nil
        print("🛑 BurnerModeMonitor: All monitoring stopped")
    }

    // MARK: - Manual Check
    func checkNow() async {
        print("🔄 BurnerModeMonitor: Manual check triggered")
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
