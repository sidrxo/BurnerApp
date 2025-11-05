import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import FamilyControls

@MainActor
class BurnerModeMonitor: ObservableObject {
    @Published var shouldEnableBurnerMode = false
    
    private let db = Firestore.firestore()
    private var ticketListener: ListenerRegistration?
    private let burnerManager: BurnerModeManager
    
    init(burnerManager: BurnerModeManager) {
        self.burnerManager = burnerManager
        // Don't start monitoring in init - wait for user to sign in
    }
    
    deinit {
        // Can't call @MainActor methods in deinit, so remove listener directly
        ticketListener?.remove()
        ticketListener = nil
    }
    
    // MARK: - Start Monitoring
    func startMonitoring() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ BurnerModeMonitor: No user logged in")
            return
        }

        print("✅ BurnerModeMonitor: Started monitoring")

        // Stop any existing listener first
        stopMonitoring()

        // Listen to user's tickets in real-time
        ticketListener = db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "used")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ BurnerModeMonitor: Error - \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                Task { @MainActor in
                    await self.checkForTodayScannedTickets(documents: documents)
                }
            }
    }
    
    // MARK: - Check for Today's Scanned Tickets
    private func checkForTodayScannedTickets(documents: [QueryDocumentSnapshot]) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for document in documents {
            let data = document.data()

            guard let startTime = (data["startTime"] as? Timestamp)?.dateValue(),
                  let usedAt = (data["usedAt"] as? Timestamp)?.dateValue() else {
                continue
            }

            let eventDay = calendar.startOfDay(for: startTime)
            let scannedDay = calendar.startOfDay(for: usedAt)

            guard eventDay == today && scannedDay == today else {
                continue
            }

            print("✅ BurnerModeMonitor: Event scanned today, enabling Burner Mode")
            await enableBurnerMode()
            return
        }
    }
    
    // MARK: - Enable Burner Mode
    private func enableBurnerMode() async {
        guard burnerManager.isSetupValid else {
            print("❌ BurnerModeMonitor: Setup invalid")
            return
        }

        guard !UserDefaults.standard.bool(forKey: "burnerModeEnabled") else {
            return
        }

        do {
            try await burnerManager.enable()
            shouldEnableBurnerMode = true

            print("✅ BurnerModeMonitor: Burner Mode enabled")

            NotificationCenter.default.post(
                name: NSNotification.Name("BurnerModeAutoEnabled"),
                object: nil
            )
        } catch BurnerModeError.notAuthorized {
            print("❌ BurnerModeMonitor: Not authorized")
        } catch BurnerModeError.invalidSetup(let message) {
            print("❌ BurnerModeMonitor: \(message)")
        } catch {
            print("❌ BurnerModeMonitor: \(error)")
        }
    }
    
    // MARK: - Stop Monitoring
    func stopMonitoring() {
        ticketListener?.remove()
        ticketListener = nil
    }

    // MARK: - Manual Check
    func checkNow() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ BurnerModeMonitor: No user logged in")
            return
        }

        do {
            let snapshot = try await db.collection("tickets")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: "used")
                .getDocuments()

            await checkForTodayScannedTickets(documents: snapshot.documents)
        } catch {
            print("❌ BurnerModeMonitor: \(error.localizedDescription)")
        }
    }

    // MARK: - Get Monitor Status
    func getMonitorStatus() -> String {
        guard Auth.auth().currentUser != nil else {
            return "❌ No user logged in"
        }

        let isListening = ticketListener != nil
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
}
