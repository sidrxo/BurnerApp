import SwiftUI
import FirebaseFirestore
import FirebaseAuth

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
    @State private var showLoadingSuccess = false
    @State private var isLoadingSuccess = true

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
                        // 1. TOGGLE Button (Existing)
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
                        
                        // 2. DEDICATED DISABLE Button (NEW)
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
                        .disabled(!appState.showingBurnerLockScreen) // Disable if already off
                        
                        // 3. Test Event End Notification Button (Existing)
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

                        // 4. Test Burner Setup Reminder Button (NEW)
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

                    // MARK: - New Menu Section for Flows
                    MenuSection(title: "ONBOARDING & FLOWS") {
                        Button(action: {
                            // ✅ FIX: Use the main AppState's OnboardingManager instance to reset
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

                    MenuSection(title: "UI COMPONENTS") {
                        Button(action: {
                            isLoadingSuccess = true
                            showLoadingSuccess = true
                        }) {
                            MenuItemContent(
                                title: "Show Loading Success Animation",
                                subtitle: "Test spinner → circle fill → checkmark"
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
            Text("The 'Event Ended' notification will appear in 10 seconds. You can close the app to test background delivery.")
        }
        // MARK: - New Full Screen Covers
        .fullScreenCover(isPresented: $showOnboardingFlow) {
            // Instantiate a new manager instance for isolated testing of the flow
            OnboardingFlowView() // No need to pass manager in init now
                .environmentObject(appState.onboardingManager) // Inject via environment
                .environmentObject(appState) // Ensure AppState is also available
        }
        .fullScreenCover(isPresented: $showBurnerModeSetup) {
            BurnerModeSetupView(
                burnerManager: burnerManager,
                onSkip: { showBurnerModeSetup = false }
            )
        }
        .fullScreenCover(isPresented: $showLoadingSuccess) {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    LoadingSuccessView(
                        isLoading: $isLoadingSuccess
                    )
                    
                    Button(action: {
                        if isLoadingSuccess {
                            isLoadingSuccess = false
                            // Reset after animation completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                showLoadingSuccess = false
                            }
                        } else {
                            isLoadingSuccess = true
                        }
                    }) {
                        Text(isLoadingSuccess ? "Complete Loading" : "Loading...")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(!isLoadingSuccess)
                    
                    Button(action: {
                        showLoadingSuccess = false
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
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

    private func resetAppToFirstInstall() {
        Task {
            // Clear Firestore preferences before signing out
            if let userId = appState.authService.currentUser?.uid {
                await clearFirestorePreferences(userId: userId)
            }

            // Sign out the user if signed in
            if appState.authService.currentUser != nil {
                try? appState.authService.signOut()
            }

            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                  UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }

            // ✅ FIX: Call reset on the AppState's shared OnboardingManager instance
            await MainActor.run {
                appState.onboardingManager.resetOnboarding() // This clears the userDefaults flags for onboarding/sign-in
            }

            // Clear local preferences
            await MainActor.run {
                let localPrefs = LocalPreferences()
                localPrefs.reset()
            }

            // Disable burner mode if enabled
            if appState.showingBurnerLockScreen {
                burnerManager.disable()
                await MainActor.run {
                    appState.showingBurnerLockScreen = false
                }
            }

            // Clear burner selections
            burnerManager.clearAllSelections()

            // Reset user location
            await MainActor.run {
                appState.userLocationManager.resetLocation()
            }

            // Reset navigation
            await MainActor.run {
                appState.navigationCoordinator.resetAllNavigation()
                appState.navigationCoordinator.selectTab(.explore)
            }

            // Clear debug event if active
            if eventState != .noEvent {
                appState.clearDebugEventToday()
                eventState = .noEvent
            }
        }
    }

    // Helper function to clear Firestore preferences
    private func clearFirestorePreferences(userId: String) async {
        let db = FirebaseFirestore.Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        do {
            // Remove preferences field from Firestore
            try await userRef.updateData(["preferences": FieldValue.delete()])
        } catch {
            // Ignore error if field doesn't exist or update fails
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
                        try await burnerManager.enable(appState: appState) // Add appState parameter
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
