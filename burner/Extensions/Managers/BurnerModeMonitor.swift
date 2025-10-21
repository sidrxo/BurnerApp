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
            print("❌ BurnerModeMonitor: No user logged in, can't monitor burner mode")
            return
        }
        
        print("✅ BurnerModeMonitor: Starting to monitor tickets for user: \(userId)")
        
        // Stop any existing listener first
        stopMonitoring()
        
        // Listen to user's tickets in real-time
        ticketListener = db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "used") // Listen for scanned tickets
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ BurnerModeMonitor: Error monitoring tickets: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ BurnerModeMonitor: No documents in snapshot")
                    return
                }
                
                print("🔍 BurnerModeMonitor: Found \(documents.count) used tickets")
                
                Task { @MainActor in
                    await self.checkForTodayScannedTickets(documents: documents)
                }
            }
    }
    
    // MARK: - Check for Today's Scanned Tickets
    private func checkForTodayScannedTickets(documents: [QueryDocumentSnapshot]) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        print("🔍 BurnerModeMonitor: Checking \(documents.count) tickets against today's date: \(today)")
        
        for document in documents {
            let data = document.data()
            
            // Debug: Print ticket ID and status
            print("🎫 Checking ticket: \(document.documentID)")
            print("   Status: \(data["status"] as? String ?? "unknown")")
            
            guard let startTime = (data["startTime"] as? Timestamp)?.dateValue() else {
                print("⚠️ BurnerModeMonitor: No startTime in ticket \(document.documentID)")
                continue
            }
            
            // Check if event is today
            let eventDay = calendar.startOfDay(for: startTime)
            guard eventDay == today else {
                print("📅 Ticket \(document.documentID): Event date \(eventDay) is not today \(today)")
                continue
            }
            
            print("✅ Ticket \(document.documentID): Event is today!")
            
            // Check if ticket was scanned (has usedAt field)
            guard let usedAt = (data["usedAt"] as? Timestamp)?.dateValue() else {
                print("⚠️ BurnerModeMonitor: Ticket \(document.documentID) doesn't have usedAt timestamp")
                continue
            }
            
            // Check if ticket was scanned today
            let scannedDay = calendar.startOfDay(for: usedAt)
            guard scannedDay == today else {
                print("⚠️ Ticket \(document.documentID): Was scanned on \(scannedDay), not today \(today)")
                continue
            }
            
            print("✅✅ MATCH FOUND: Ticket \(document.documentID)")
            print("   - Event is today: \(eventDay)")
            print("   - Scanned today: \(scannedDay)")
            print("🔥 Attempting to enable Burner Mode...")
            
            // Event is today and ticket was scanned - enable Burner Mode!
            await enableBurnerMode()
            return
        }
        
        print("ℹ️ BurnerModeMonitor: No matching tickets found for today")
    }
    
    // MARK: - Enable Burner Mode
    private func enableBurnerMode() async {
        print("🔥 BurnerModeMonitor: enableBurnerMode called")
        
        // Check if setup is valid
        guard burnerManager.isSetupValid else {
            print("⚠️ BurnerModeMonitor: Burner Mode not set up properly, cannot enable")
            print("   - Categories selected: \(burnerManager.selectedApps.categoryTokens.count)")
            print("   - Minimum required: \(burnerManager.minimumCategoriesRequired)")
            print("   - Apps selected: \(burnerManager.selectedApps.applicationTokens.count)")
            return
        }
        
        print("✅ BurnerModeMonitor: Burner Mode setup is valid")
        print("   - Categories: \(burnerManager.selectedApps.categoryTokens.count)")
        print("   - Apps to keep available: \(burnerManager.selectedApps.applicationTokens.count)")
        
        // Check if already enabled
        if UserDefaults.standard.bool(forKey: "burnerModeEnabled") {
            print("ℹ️ BurnerModeMonitor: Burner Mode already enabled")
            return
        }
        
        print("🚀 BurnerModeMonitor: Enabling Burner Mode...")
        
        // Enable Burner Mode
        burnerManager.enable()
        shouldEnableBurnerMode = true
        
        print("🔥 BurnerModeMonitor: Burner Mode automatically enabled for scanned event")
        print("   - UserDefaults key 'burnerModeEnabled' set to: \(UserDefaults.standard.bool(forKey: "burnerModeEnabled"))")
        
        // Show notification to user
        NotificationCenter.default.post(
            name: NSNotification.Name("BurnerModeAutoEnabled"),
            object: nil
        )
        
        print("📢 BurnerModeMonitor: Notification posted to user")
    }
    
    // MARK: - Stop Monitoring
    func stopMonitoring() {
        print("🛑 BurnerModeMonitor: Stopping monitoring")
        ticketListener?.remove()
        ticketListener = nil
    }
    
    // MARK: - Manual Check (for testing or force refresh)
    func checkNow() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ BurnerModeMonitor: No user logged in for manual check")
            return
        }
        
        print("🔍 BurnerModeMonitor: Manual check triggered for user: \(userId)")
        
        do {
            let snapshot = try await db.collection("tickets")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: "used")
                .getDocuments()
            
            print("📊 BurnerModeMonitor: Manual check found \(snapshot.documents.count) used tickets")
            
            await checkForTodayScannedTickets(documents: snapshot.documents)
        } catch {
            print("❌ BurnerModeMonitor: Error during manual check: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Monitor Status (for debugging)
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
        status += "- Categories Selected: \(burnerManager.selectedApps.categoryTokens.count)/\(burnerManager.minimumCategoriesRequired)\n"
        status += "- Apps Allowed: \(burnerManager.selectedApps.applicationTokens.count)"
        
        return status
    }
}
