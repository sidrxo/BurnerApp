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
        }
    }
    @Published var setupError: String?
    @Published var isLocked: Bool = false
    @Published var burnerSetupCompleted: Bool = false

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

    private lazy var appGroupDefaults: UserDefaults? = {
        guard let defaults = UserDefaults(suiteName: "group.com.gas.Burner") else {
            print("âš ï¸ Unable to initialize app group defaults")
            return nil
        }
        return defaults
    }()

    let nfcManager = NFCUnlockManager()
    let minimumCategoriesRequired = 8

    var isAuthorized: Bool {
        AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    var hasCompletedSetup: Bool {
        burnerSetupCompleted
    }

    var isSetupValid: Bool {
        isAuthorized && selectedApps.categoryTokens.count >= minimumCategoriesRequired
    }

    init() {
        loadSelectedApps()
        loadBurnerSetupState()
    }
    
    private func loadBurnerSetupState() {
        burnerSetupCompleted = UserDefaults.standard.bool(forKey: "burnerSetupCompleted")
    }

    func hasAllCategoriesSelected() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        return categoryCount >= minimumCategoriesRequired
    }

    func getSetupValidationMessage() -> String {
        if !isAuthorized {
            return "âš ï¸ Screen Time permission required"
        }

        if isSetupValid {
            return "âœ“ Ready for Block-All Mode"
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
        if let data = appGroupDefaults?.data(forKey: "selectedApps") ?? UserDefaults.standard.data(forKey: "selectedApps"),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
    }

    private func saveSelectedApps() {
        if let data = try? JSONEncoder().encode(selectedApps) {
            appGroupDefaults?.set(data, forKey: "selectedApps")
            UserDefaults.standard.set(data, forKey: "selectedApps")
        }
    }
    
    func completeSetup() {
        burnerSetupCompleted = true
        UserDefaults.standard.set(true, forKey: "burnerSetupCompleted")
    }
    
    func setBurnerSetupCompleted(_ completed: Bool) {
        burnerSetupCompleted = completed
        UserDefaults.standard.set(completed, forKey: "burnerSetupCompleted")
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

        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)

        let eventEndTime = await calculateEventEndTime(appState: appState)

        UserDefaults.standard.set(eventEndTime, forKey: "burnerModeEventEndTime")
        appGroupDefaults?.set(eventEndTime, forKey: "burnerModeEventEndTime")
        UserDefaults.standard.set(false, forKey: "burnerModeTerminalShown")

        scheduleEventEndNotification(endTime: eventEndTime)

        store.application.denyAppRemoval = true

        if selectedApps.applicationTokens.isEmpty {
            store.shield.applicationCategories = .all()
        } else {
            store.shield.applicationCategories = .all(except: selectedApps.applicationTokens)
        }

        try startDeviceActivityMonitoring(endTime: eventEndTime)

        appGroupDefaults?.set(true, forKey: "burnerModeEnabled")
        UserDefaults.standard.set(true, forKey: "burnerModeEnabled")

        if !isLocked {
            isLocked = true
            objectWillChange.send()
        }
    }

    private func calculateEventEndTime(appState: AppState) async -> Date {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 3600)

        let recentScannedTicket = appState.ticketsViewModel.tickets.first { ticket in
            guard ticket.status == "used",
                  let usedAt = ticket.usedAt else {
                return false
            }
            return usedAt >= twentyFourHoursAgo
        }

        if let ticket = recentScannedTicket {
            do {
                let event = try await appState.eventViewModel.fetchEvent(byId: ticket.eventId)

                if let endTime = event.endTime {
                    let calendar = Calendar.current
                    let timeZone = calendar.timeZone
                    let components = calendar.dateComponents(in: timeZone, from: endTime)
                    if let adjustedEndTime = calendar.date(from: components) {
                        return adjustedEndTime
                    } else {
                        return endTime
                    }
                } else {
                    return ticket.startTime.addingTimeInterval(4 * 3600)
                }
            } catch {
                return ticket.startTime.addingTimeInterval(4 * 3600)
            }
        } else {
            return Date().addingTimeInterval(4 * 3600)
        }
    }

    private func startDeviceActivityMonitoring(endTime: Date) throws {
        let calendar = Calendar.current
        let now = Date()

        let startComponents = calendar.dateComponents([.hour, .minute], from: now)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )

        let activityName = DeviceActivityName("burner.protection")

        do {
            try center.startMonitoring(activityName, during: schedule)
            print("âœ“ Device Activity monitoring started until \(endTime)")
        } catch {
            print("âš ï¸ Error starting Device Activity monitoring: \(error.localizedDescription)")
            throw error
        }
    }

    private func scheduleEventEndNotification(endTime: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Event Ended"
        content.body = "Your event has ended and Burner Mode has been automatically disabled. Welcome back! ðŸŽ‰"
        content.sound = .default
        content.badge = 1

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: "burner-mode-event-ended",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("âš ï¸ Error scheduling event end notification: \(error.localizedDescription)")
            } else {
                print("âœ“ Event end notification scheduled for \(endTime)")
            }
        }
    }

    func checkAndScheduleEventDayReminder(tickets: [Ticket]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let todayTickets = tickets.filter { ticket in
            let ticketDate = calendar.startOfDay(for: ticket.startTime)
            return ticketDate == today && ticket.status == "confirmed"
        }

        guard !todayTickets.isEmpty else {
            return
        }

        let lastReminderDate = UserDefaults.standard.object(forKey: "lastBurnerSetupReminderDate") as? Date
        if let lastDate = lastReminderDate,
            calendar.isDate(lastDate, inSameDayAs: today) {
            return
        }

        scheduleBurnerSetupReminder(eventCount: todayTickets.count)

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

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let identifier = "burner-setup-reminder-\(dateFormatter.string(from: Date()))"

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("âš ï¸ Error scheduling burner setup reminder: \(error.localizedDescription)")
            } else {
                print("âœ“ Burner setup reminder scheduled")
            }
        }
    }

    func scheduleTestNotification(delay: TimeInterval = 10) {
        let content = UNMutableNotificationContent()
        content.title = "Event Ended"
        content.body = "Your event has ended and Burner Mode has been automatically disabled. Welcome back! ðŸŽ‰"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        let request = UNNotificationRequest(
            identifier: "burner-mode-test-notification",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("âš ï¸ Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("âœ“ Test notification scheduled for \(Int(delay)) seconds from now")
            }
        }
    }

    func scheduleTestBurnerSetupReminder() {
        scheduleBurnerSetupReminder(eventCount: 1)
        print("âœ“ Test burner setup reminder sent")
    }

    private func cancelEventEndNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["burner-mode-event-ended"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["burner-mode-event-ended"])
    }

    func disable() {
        // Clear burner setup and lock state immediately
        setBurnerSetupCompleted(false)

        cancelEventEndNotification()

        let activityName = DeviceActivityName("burner.protection")
        center.stopMonitoring([activityName])

        store.clearAllSettings()

        appGroupDefaults?.set(false, forKey: "burnerModeEnabled")
        UserDefaults.standard.set(false, forKey: "burnerModeEnabled")

        UserDefaults.standard.removeObject(forKey: "burnerModeEventEndTime")
        appGroupDefaults?.removeObject(forKey: "burnerModeEventEndTime")
        UserDefaults.standard.removeObject(forKey: "burnerModeTerminalShown")

        if isLocked {
            isLocked = false
            objectWillChange.send()
        }
    }

    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        appGroupDefaults?.removeObject(forKey: "selectedApps")
        UserDefaults.standard.removeObject(forKey: "selectedApps")
    }

    func unlockWithNFC() {
        guard isLocked else { return }
        disable()
    }
}

enum BurnerModeError: Error {
    case notAuthorized
    case invalidSetup(String)
}
