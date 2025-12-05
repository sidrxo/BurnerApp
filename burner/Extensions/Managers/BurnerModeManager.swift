import Swift
import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine
import UserNotifications

@MainActor
class BurnerModeManager: ObservableObject {
    @Published var selectedApps = FamilyActivitySelection() {
        didSet {
            saveSelectedApps()
            checkSetupCompliance()
        }
    }
    @Published var isSetupValid = false
    @Published var setupError: String?
    @Published var isAuthorized = false
    @Published var hasCompletedSetup: Bool = false
    @Published var isLocked: Bool = false
    
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private var authorizationCancellable: AnyCancellable?

    // App Group for sharing data with extension - lazy to avoid init warnings
    // Note: CFPrefsPlistSource warning is a known iOS system behavior and is harmless
    private lazy var appGroupDefaults: UserDefaults? = {
        guard let defaults = UserDefaults(suiteName: "group.com.gas.Burner") else {
            print("⚠️ Unable to initialize app group defaults")
            return nil
        }
        return defaults
    }()

    // NFC Manager for unlock functionality
    let nfcManager = NFCUnlockManager()

    let minimumCategoriesRequired = 8

    init() {
        loadSelectedApps()
        loadHasCompletedSetup()
        setupAuthorizationMonitoring()
        checkSetupCompliance()
        requestNotificationPermissions()
    }

    private func loadHasCompletedSetup() {
        hasCompletedSetup = UserDefaults.standard.bool(forKey: "hasCompletedBurnerSetup")
    }
    
    private func setupAuthorizationMonitoring() {
        authorizationCancellable = AuthorizationCenter.shared.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isAuthorized = (status == .approved)
                self?.checkSetupCompliance()
            }
        
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    func hasAllCategoriesSelected() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        return categoryCount >= minimumCategoriesRequired
    }
   
    @discardableResult
    func checkSetupCompliance() -> Bool {
        guard isAuthorized else {
            setupError = "Screen Time permission required"
            isSetupValid = false
            return false
        }
        
        let categoryCount = selectedApps.categoryTokens.count
        
        if categoryCount < minimumCategoriesRequired {
            setupError = "Please select more categories."
            isSetupValid = false
            return false
        }
        
        setupError = nil
        isSetupValid = true
        return true
    }
    
    func getSetupValidationMessage() -> String {
        if !isAuthorized {
            return "⚠️ Screen Time permission required"
        }
        
        if isSetupValid {
            return "✓ Ready for Block-All Mode"
        } else {
            return setupError ?? "Setup incomplete"
        }
    }
    
    func getSelectedAppsDescription() -> String {
        if !isAuthorized {
            return "Enable Screen Time permissions to continue"
        }
        
        let appCount = selectedApps.applicationTokens.count
        let categoryCount = selectedApps.categoryTokens.count
        
        if hasAllCategoriesSelected() {
            return appCount > 0 ? "\(appCount) apps will stay available" : "All apps will be blocked"
        } else if categoryCount > 0 {
            return "\(categoryCount) categories selected - Need \(minimumCategoriesRequired) total"
        } else {
            return "Select \(minimumCategoriesRequired) categories to enable block-all mode"
        }
    }
    
    private func loadSelectedApps() {
        // Try app group first, fall back to standard UserDefaults
        if let data = appGroupDefaults?.data(forKey: "selectedApps") ?? UserDefaults.standard.data(forKey: "selectedApps"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
    }
    
    private func saveSelectedApps() {
        if let data = try? JSONEncoder().encode(selectedApps) {
            // Save to both locations
            appGroupDefaults?.set(data, forKey: "selectedApps")
            UserDefaults.standard.set(data, forKey: "selectedApps")
        }
    }

    // MARK: - Check Authorization
    func checkAuthorization() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        checkSetupCompliance()
    }

    // MARK: - Complete Setup
    func completeSetup() {
        hasCompletedSetup = true
        UserDefaults.standard.set(true, forKey: "hasCompletedBurnerSetup")

        // Cancel all pending setup reminder notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let setupReminderIDs = requests
                .filter { $0.identifier.starts(with: "setup-reminder-") }
                .map { $0.identifier }

            if !setupReminderIDs.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: setupReminderIDs)
            }
        }
    }

    // MARK: - Reset Setup
    func resetSetup() {
        hasCompletedSetup = false
        UserDefaults.standard.set(false, forKey: "hasCompletedBurnerSetup")
    }

    // MARK: - Notification Permissions
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Error requesting notification permissions: \(error.localizedDescription)")
            }
        }
    }

    func enable(appState: AppState) async throws {
        guard isAuthorized else {
            throw BurnerModeError.notAuthorized
        }
        
        guard isSetupValid else {
            throw BurnerModeError.invalidSetup("Must select at least \(minimumCategoriesRequired) categories first")
        }
        
        guard hasAllCategoriesSelected() else {
            throw BurnerModeError.invalidSetup("Not enough categories selected")
        }

        // Request authorization
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        
        // DETERMINE AND SET END TIME ONCE when enabling burner mode
        let eventEndTime = await calculateEventEndTime(appState: appState)
        
        // Save to both UserDefaults and App Group for Device Activity Extension access
        UserDefaults.standard.set(eventEndTime, forKey: "burnerModeEventEndTime")
        appGroupDefaults?.set(eventEndTime, forKey: "burnerModeEventEndTime")
        UserDefaults.standard.set(false, forKey: "burnerModeTerminalShown") // Reset terminal flag
        
        // Schedule notification for when event ends
        scheduleEventEndNotification(endTime: eventEndTime)
        
        // CRITICAL SECURITY MEASURES
        
        // 1. Block app removal (prevents uninstallation)
        store.application.denyAppRemoval = true
        
        // 2. Apply shields to apps
        if selectedApps.applicationTokens.isEmpty {
            store.shield.applicationCategories = .all()
        } else {
            store.shield.applicationCategories = .all(except: selectedApps.applicationTokens)
        }
        
        // 3. Start Device Activity monitoring with event end time
        try startDeviceActivityMonitoring(endTime: eventEndTime)

        // Save state to both UserDefaults locations
        appGroupDefaults?.set(true, forKey: "burnerModeEnabled")
        UserDefaults.standard.set(true, forKey: "burnerModeEnabled")

        // Update locked state
        isLocked = true
    }
    
    private func calculateEventEndTime(appState: AppState) async -> Date {
        // 24-HOUR ROLLING WINDOW: Find tickets scanned in last 24 hours
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 3600)
        
        let recentScannedTicket = appState.ticketsViewModel.tickets.first { ticket in
            guard ticket.status == "used",
                  let usedAt = ticket.usedAt else {
                return false
            }
            // Check if scanned within last 24 hours
            return usedAt >= twentyFourHoursAgo
        }
        
        // If we found a recent scanned ticket, fetch the event to get the end time
        if let ticket = recentScannedTicket {
            do {
                let event = try await appState.eventViewModel.fetchEvent(byId: ticket.eventId)
                
                if let endTime = event.endTime {
                    // Use actual event end time with timezone awareness
                    let calendar = Calendar.current
                    let timeZone = calendar.timeZone
                    let components = calendar.dateComponents(in: timeZone, from: endTime)
                    if let adjustedEndTime = calendar.date(from: components) {
                        return adjustedEndTime
                    } else {
                        return endTime
                    }
                } else {
                    // Fallback: Use start time + 4 hours if no end time
                    return ticket.startTime.addingTimeInterval(4 * 3600)
                }
            } catch {
                // If fetching event fails, use ticket start time + 4 hours as fallback
                return ticket.startTime.addingTimeInterval(4 * 3600)
            }
        } else {
            // If no recent scanned ticket found, use a default fallback
            return Date().addingTimeInterval(4 * 3600)
        }
    }
    
    private func startDeviceActivityMonitoring(endTime: Date) throws {
        // Calculate start and end time components for the Device Activity schedule
        let calendar = Calendar.current
        let now = Date()
        
        // Start time is now
        let startComponents = calendar.dateComponents([.hour, .minute], from: now)
        
        // End time is when the event ends
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        // Create a schedule that runs from now until the event ends
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false  // Don't repeat - one-time monitoring until event ends
        )
        
        let activityName = DeviceActivityName("burner.protection")
        
        do {
            try center.startMonitoring(activityName, during: schedule)
            print("✓ Device Activity monitoring started until \(endTime)")
        } catch {
            print("⚠️ Error starting Device Activity monitoring: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Schedule Event End Notification
    private func scheduleEventEndNotification(endTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Event Ended"
        content.body = "Your event has ended and Burner Mode has been automatically disabled. Welcome back! 🎉"
        content.sound = .default
        content.badge = 1
        
        // Create trigger for the event end time
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "burner-mode-event-ended",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Error scheduling event end notification: \(error.localizedDescription)")
            } else {
                print("✓ Event end notification scheduled for \(endTime)")
            }
        }
    }
    
    // MARK: - Event Day Burner Setup Reminder
    func checkAndScheduleEventDayReminder(tickets: [Ticket]) {
        guard !hasCompletedSetup else {
            // User has already completed setup, no need to remind
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if user has any tickets for today
        let todayTickets = tickets.filter { ticket in
            let ticketDate = calendar.startOfDay(for: ticket.startTime)
            return ticketDate == today && ticket.status == "confirmed"
        }

        guard !todayTickets.isEmpty else {
            // No tickets for today, no need to remind
            return
        }

        // Check if we've already sent a reminder today
        let lastReminderDate = UserDefaults.standard.object(forKey: "lastBurnerSetupReminderDate") as? Date
        if let lastDate = lastReminderDate,
           calendar.isDate(lastDate, inSameDayAs: today) {
            // Already sent reminder today
            return
        }

        // Schedule reminder notification
        scheduleBurnerSetupReminder(eventCount: todayTickets.count)

        // Save today's date to avoid duplicate reminders
        UserDefaults.standard.set(Date(), forKey: "lastBurnerSetupReminderDate")
    }

    private func scheduleBurnerSetupReminder(eventCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Complete Burner Mode Setup"
        content.body = eventCount == 1
            ? "You have an event today! Complete Burner Mode setup to access your ticket."
            : "You have \(eventCount) events today! Complete Burner Mode setup to access your tickets."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "BURNER_SETUP_REMINDER"

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create request with unique identifier for today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let identifier = "burner-setup-reminder-\(dateFormatter.string(from: Date()))"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Error scheduling burner setup reminder: \(error.localizedDescription)")
            } else {
                print("✓ Burner setup reminder scheduled")
            }
        }
    }

    // MARK: - Test Notification (Debug Only)
    func scheduleTestNotification(delay: TimeInterval = 10) {
        let content = UNMutableNotificationContent()
        content.title = "Event Ended"
        content.body = "Your event has ended and Burner Mode has been automatically disabled. Welcome back! 🎉"
        content.sound = .default
        content.badge = 1

        // Create trigger for X seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "burner-mode-test-notification",
            content: content,
            trigger: trigger
        )

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("✓ Test notification scheduled for \(Int(delay)) seconds from now")
            }
        }
    }

    // MARK: - Test Burner Setup Reminder (Debug Only)
    func scheduleTestBurnerSetupReminder() {
        scheduleBurnerSetupReminder(eventCount: 1)
        print("✓ Test burner setup reminder sent")
    }
    
    // MARK: - Cancel Event End Notification
    private func cancelEventEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["burner-mode-event-ended"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["burner-mode-event-ended"])
    }

    func disable() {
        guard isAuthorized else {
            return
        }

        // Cancel the event end notification
        cancelEventEndNotification()

        // Stop device activity monitoring
        let activityName = DeviceActivityName("burner.protection")
        center.stopMonitoring([activityName])

        // Clear all restrictions
        store.clearAllSettings()

        // Update state in both locations
        appGroupDefaults?.set(false, forKey: "burnerModeEnabled")
        UserDefaults.standard.set(false, forKey: "burnerModeEnabled")

        // Clean up end time and terminal flag
        UserDefaults.standard.removeObject(forKey: "burnerModeEventEndTime")
        appGroupDefaults?.removeObject(forKey: "burnerModeEventEndTime")
        UserDefaults.standard.removeObject(forKey: "burnerModeTerminalShown")

        // Update locked state
        isLocked = false
    }
    
    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        appGroupDefaults?.removeObject(forKey: "selectedApps")
        UserDefaults.standard.removeObject(forKey: "selectedApps")
    }
    
    // MARK: - NFC Unlock
    func unlockWithNFC() {
        guard isLocked else { return }
        disable()
    }
}

enum BurnerModeError: Error {
    case notAuthorized
    case invalidSetup(String)
}
