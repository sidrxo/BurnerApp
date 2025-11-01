//
//  DebugMenuView.swift
//  burner
//
//  Created by Sid Rao on 31/10/2025.
//


import SwiftUI

struct DebugMenuView: View {
    @ObservedObject var appState: AppState
    let burnerManager: BurnerModeManager
    @AppStorage("useWalletView") private var useWalletView = true
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderSection(title: "Debug Menu")
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 0) {
                    CustomMenuSection(title: "VIEW TOGGLES") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use Wallet View")
                                    .appBody()
                                    .foregroundColor(.white)
                                Text(useWalletView ? "TicketsWalletView" : "TicketsView")
                                    .appSecondary()
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Toggle("", isOn: $useWalletView)
                                .labelsHidden()
                                .tint(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    CustomMenuSection(title: "ONBOARDING") {
                        Button(action: {
                            resetOnboarding()
                        }) {
                            CustomMenuItemContent(
                                title: "Reset Onboarding",
                                subtitle: "Show first-time setup again"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    CustomMenuSection(title: "AUTHENTICATION") {
                        Button(action: {
                            refreshCustomClaims()
                        }) {
                            CustomMenuItemContent(
                                title: "Refresh Custom Claims",
                                subtitle: "Force reload user permissions"
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    CustomMenuSection(title: "BURNER MODE") {
                        Button(action: {
                            toggleBurnerMode()
                        }) {
                            CustomMenuItemContent(
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
    }
    
    // MARK: - Debug Actions
    
    private func resetOnboarding() {
        let onboarding = OnboardingManager()
        onboarding.resetOnboarding()
        NotificationCenter.default.post(name: NSNotification.Name("ResetOnboarding"), object: nil)
    }
    
    private func refreshCustomClaims() {
        print("🔄 [Debug] Manually refreshing custom claims...")
        Task {
            do {
                if let role = try await appState.authService.getUserRole() {
                    await MainActor.run {
                        appState.userRole = role
                        print("✅ [Debug] User role refreshed: \(role)")
                    }
                }
                
                let scannerActive = try await appState.authService.isScannerActive()
                await MainActor.run {
                    appState.isScannerActive = scannerActive
                    print("✅ [Debug] Scanner status refreshed: \(scannerActive)")
                }
            } catch {
                print("🔴 [Debug] Error refreshing claims: \(error.localizedDescription)")
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
                burnerManager.enable()
                appState.showingBurnerLockScreen = true
            } else {
                // Could show setup sheet here if needed
                print("⚠️ [Debug] Burner mode setup not valid")
            }
        }
    }
}