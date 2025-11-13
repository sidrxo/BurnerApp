import SwiftUI

struct DebugMenuView: View {
    @ObservedObject var appState: AppState
    let burnerManager: BurnerModeManager
    @AppStorage("useWalletView") private var useWalletView = true
    @State private var showBurnerError = false
    @State private var burnerErrorMessage = ""
    @State private var showResetConfirmation = false
    
    // Three states: no event, before event starts, during event
    enum EventState {
        case noEvent
        case beforeEvent
        case duringEvent
    }
    @State private var eventState: EventState = .noEvent
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderSection(title: "Debug Menu")
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

                        Button(action: {
                            if appState.isSimulatingEmptyFirestore {
                                appState.disableEmptyFirestoreSimulation()
                            } else {
                                appState.enableEmptyFirestoreSimulation()
                            }
                        }) {
                            MenuItemContent(
                                title: appState.isSimulatingEmptyFirestore ? "Restore Firestore Data" : "Simulate Empty Firestore",
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
                                title: appState.showingBurnerLockScreen ? "Disable Burner Mode" : "Enable Burner Mode",
                                subtitle: appState.showingBurnerLockScreen ? "Currently active" : "Test Burner Mode"
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

    private func resetAppToFirstInstall() {
        Task {
            // Sign out the user if signed in
            if appState.authService.currentUser != nil {
                try? appState.authService.signOut()
            }

            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }

            // Disable burner mode if enabled
            if appState.showingBurnerLockScreen {
                burnerManager.disable()
                await MainActor.run {
                    appState.showingBurnerLockScreen = false
                }
            }

            // Reset user location
            await MainActor.run {
                appState.userLocationManager.resetLocation()
            }

            // Reset navigation
            await MainActor.run {
                appState.navigationCoordinator.resetAllNavigation()
                appState.navigationCoordinator.selectTab(.home)
            }
            
            // Clear debug event if active
            if eventState != .noEvent {
                appState.clearDebugEventToday()
                eventState = .noEvent
            }
        }
    }

    private func toggleBurnerMode() {
        if appState.showingBurnerLockScreen {
            // Disable burner mode
            burnerManager.disable()
            appState.showingBurnerLockScreen = false
        } else {
            // Enable burner mode if setup is valid
            if burnerManager.isSetupValid {
                // Create a Task to handle the async call
                Task {
                    do {
                        try await burnerManager.enable()
                        // Update UI on main thread
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
                // Could show setup sheet here if needed
                burnerErrorMessage = "Burner mode setup not valid"
                showBurnerError = true
            }
        }
    }
    
    private func cycleEventState() {
        switch eventState {
        case .noEvent:
            // Create event that hasn't started yet (2 hours from now)
            appState.simulateEventBeforeStart()
            eventState = .beforeEvent
            
        case .beforeEvent:
            // Clear previous and create event that's already started
            appState.clearDebugEventToday()
            appState.simulateEventDuringEvent()
            eventState = .duringEvent
            
        case .duringEvent:
            // Clear the event
            appState.clearDebugEventToday()
            eventState = .noEvent
        }
    }
}
