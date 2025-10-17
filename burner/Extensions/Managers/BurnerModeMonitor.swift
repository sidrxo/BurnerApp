import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

@MainActor
class BurnerModeMonitor: ObservableObject {
    @Published var shouldEnableBurnerMode = false
    
    private let db = Firestore.firestore()
    private var ticketListener: ListenerRegistration?
    private let burnerManager: BurnerModeManager
    
    init(burnerManager: BurnerModeManager) {
        self.burnerManager = burnerManager
        startMonitoring()
    }
    
    deinit {
        // Can't call @MainActor methods in deinit, so remove listener directly
        ticketListener?.remove()
        ticketListener = nil
    }
    
    // MARK: - Start Monitoring
    func startMonitoring() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No user logged in, can't monitor burner mode")
            return
        }
        
        // Listen to user's tickets in real-time
        ticketListener = db.collection("tickets")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "used") // Listen for scanned tickets
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error monitoring tickets: \(error.localizedDescription)")
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
            guard let data = document.data() as? [String: Any],
                  let eventDate = (data["eventDate"] as? Timestamp)?.dateValue(),
                  let usedAt = (data["usedAt"] as? Timestamp)?.dateValue() else {
                continue
            }
            
            // Check if event is today
            let eventDay = calendar.startOfDay(for: eventDate)
            guard eventDay == today else { continue }
            
            // Check if ticket was scanned today
            let scannedDay = calendar.startOfDay(for: usedAt)
            guard scannedDay == today else { continue }
            
            // Event is today and ticket was scanned - enable Burner Mode!
            print("✅ Scanned ticket detected for today's event - enabling Burner Mode")
            await enableBurnerMode()
            return
        }
    }
    
    // MARK: - Enable Burner Mode
    private func enableBurnerMode() async {
        // Check if setup is valid
        guard burnerManager.isSetupValid else {
            print("⚠️ Burner Mode not set up properly, cannot enable")
            return
        }
        
        // Check if already enabled
        if UserDefaults.standard.bool(forKey: "burnerModeEnabled") {
            print("ℹ️ Burner Mode already enabled")
            return
        }
        
        // Enable Burner Mode
        burnerManager.enable()
        shouldEnableBurnerMode = true
        
        print("🔥 Burner Mode automatically enabled for scanned event")
        
        // Show notification to user
        NotificationCenter.default.post(
            name: NSNotification.Name("BurnerModeAutoEnabled"),
            object: nil
        )
    }
    
    // MARK: - Stop Monitoring
    func stopMonitoring() {
        ticketListener?.remove()
        ticketListener = nil
    }
    
    // MARK: - Manual Check (for testing or force refresh)
    func checkNow() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("tickets")
                .whereField("userId", isEqualTo: userId)
                .whereField("status", isEqualTo: "used")
                .getDocuments()
            
            await checkForTodayScannedTickets(documents: snapshot.documents)
        } catch {
            print("❌ Error checking tickets: \(error.localizedDescription)")
        }
    }
}
