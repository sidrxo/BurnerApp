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
                resetAppToFirstInstall()
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
    }

    // MARK: - Original Functions

    private func resetAppToFirstInstall() {
        Task {
            // Sign out from Supabase
            try? await SupabaseManager.shared.client.auth.signOut()

            await MainActor.run {
                // Clear all UserDefaults
                let defaults = UserDefaults.standard
                defaults.removeObject(forKey: "hasLaunchedBefore")
                defaults.removeObject(forKey: "hasShownLaunchVideo")
                defaults.removeObject(forKey: "pendingEmailForSignIn")
                defaults.removeObject(forKey: "burnerSetupCompleted")
                defaults.removeObject(forKey: "selectedApps")
                defaults.removeObject(forKey: "burnerModeEventEndTime")
                defaults.removeObject(forKey: "burnerModeTerminalShown")
                defaults.removeObject(forKey: "burnerModeEnabled")
                defaults.removeObject(forKey: "lastBurnerSetupReminderDate")
                defaults.removeObject(forKey: "hasCompletedOnboarding")
                defaults.removeObject(forKey: "savedLocation")
                defaults.removeObject(forKey: "selectedEventId_scanner")
                defaults.synchronize()

                // Reset AppState variables
                appState.handleManualSignOut()
                appState.showingBurnerLockScreen = false
                appState.burnerSetupCompleted = false

                // Reset onboarding
                appState.onboardingManager.resetOnboarding()

                // Clear location
                appState.userLocationManager.clearLocation()

                // Disable burner mode if active
                burnerManager.disable()

                // Exit app
                exit(0)
            }
        }
    }

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
