import SwiftUI

struct DebugMenuView: View {
    @ObservedObject var appState: AppState
    let burnerManager: BurnerModeManager
    @AppStorage("useWalletView") private var useWalletView = true
    @State private var showBurnerError = false
    @State private var burnerErrorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderSection(title: "Debug Menu")
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    // ... other sections remain the same ...
                    
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
    }
    
    // ... other functions remain the same ...
    
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
                print("⚠️ [Debug] Burner mode setup not valid")
            }
        }
    }
}
