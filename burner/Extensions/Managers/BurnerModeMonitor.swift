import Foundation
import Supabase
import Combine
import FamilyControls

@MainActor
class BurnerModeMonitor: ObservableObject {
    @Published var shouldEnableBurnerMode = false
    
    private let appState: AppState
    private let client = SupabaseManager.shared.client
    private var subscriptionTask: Task<Void, Never>?
    private let burnerManager: BurnerModeManager
    
    init(appState: AppState, burnerManager: BurnerModeManager) {
        self.appState = appState
        self.burnerManager = burnerManager
        // Don't start monitoring in init - wait for user to sign in
    }
    
    deinit {
        subscriptionTask?.cancel()
        subscriptionTask = nil
    }
    
    // MARK: - Start Monitoring
    func startMonitoring() {
        Task {
            guard let userId = await getCurrentUserId() else {
                return
            }

            // Stop any existing monitoring first
            stopMonitoring()

            // Set up real-time subscription to tickets
            subscriptionTask = Task {
                let channel = await client.channel("tickets:\(userId)")
                
                await channel.onPostgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "tickets",
                    filter: "userId=eq.\(userId)"
                ) { [weak self] _ in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        await self.checkForTodayScannedTickets(userId: userId)
                    }
                }
                
                await channel.subscribe()
                
                // Keep the task alive
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
                
                await channel.unsubscribe()
            }
            
            // Also do an initial check
            await checkForTodayScannedTickets(userId: userId)
        }
    }
    
    // MARK: - Check for Today's Scanned Tickets
    private func checkForTodayScannedTickets(userId: String) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        do {
            let tickets: [Ticket] = try await client
                .from("tickets")
                .select()
                .eq("userId", value: userId)
                .eq("status", value: "used")
                .execute()
                .value

            for ticket in tickets {
                guard !Task.isCancelled else { return }
                
                guard let usedAt = ticket.usedAt else {
                    continue
                }

                let eventDay = calendar.startOfDay(for: ticket.startTime)
                let scannedDay = calendar.startOfDay(for: usedAt)

                // Check if both event and scan happened today
                guard eventDay == today && scannedDay == today else {
                    continue
                }

                await enableBurnerMode()
                return
            }
        } catch {
            // Handle errors silently
        }
    }
    
    // MARK: - Enable Burner Mode
    private func enableBurnerMode() async {
        guard burnerManager.isSetupValid else {
            return
        }

        guard !UserDefaults.standard.bool(forKey: "burnerModeEnabled") else {
            return
        }

        do {
            try await burnerManager.enable(appState: appState)
            shouldEnableBurnerMode = true

            NotificationCenter.default.post(
                name: NSNotification.Name("BurnerModeAutoEnabled"),
                object: nil
            )
        } catch BurnerModeError.notAuthorized {
        } catch BurnerModeError.invalidSetup {
        } catch {
        }
    }
    
    // MARK: - Stop Monitoring
    func stopMonitoring() {
        subscriptionTask?.cancel()
        subscriptionTask = nil
    }

    // MARK: - Manual Check
    func checkNow() async {
        guard let userId = await getCurrentUserId() else {
            return
        }

        await checkForTodayScannedTickets(userId: userId)
    }

    // MARK: - Get Monitor Status
    func getMonitorStatus() async -> String {
        guard await getCurrentUserId() != nil else {
            return "❌ No user logged in"
        }

        let isListening = subscriptionTask != nil
        let isSetupValid = burnerManager.isSetupValid
        let isEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")

        var status = "Monitor Status:\n"
        status += "- Listening: \(isListening ? "✅" : "❌")\n"
        status += "- Setup Valid: \(isSetupValid ? "✅" : "❌")\n"
        status += "- Currently Enabled: \(isEnabled ? "✅" : "❌")\n"
        status += "- Categories: \(burnerManager.selectedApps.categoryTokens.count)/\(burnerManager.minimumCategoriesRequired)\n"
        status += "- Apps: \(burnerManager.selectedApps.applicationTokens.count)"

        return status
    }
    
    // MARK: - Helper
    private func getCurrentUserId() async -> String? {
        // Get user ID from Supabase session
        guard let session = try? await client.auth.session else {
            return nil
        }
        return session.user.id.uuidString
    }
}
