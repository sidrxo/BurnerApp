import SwiftUI
import Supabase
import FamilyControls
import ManagedSettings
import Combine

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var currentUserEmail: String?
    @State private var showingAppPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }
    
    private var userRole: String {
        appState.userRole
    }
    
    private var isScannerActive: Bool {
        appState.isScannerActive
    }
    
    private var needsBurnerSetup: Bool {
        !burnerManager.hasCompletedSetup
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        MenuSection(title: "ACCOUNT") {
                            Button(action: {
                                coordinator.navigate(to: .accountDetails)
                            }) {
                                MenuItemContent(
                                    title: "Account Details",
                                    subtitle: currentUserEmail ?? "View Account"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                coordinator.navigate(to: .bookmarks)
                            }) {
                                MenuItemContent(
                                    title: "Saves",
                                    subtitle: "Your saves appear here"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                coordinator.navigate(to: .paymentSettings)
                            }) {
                                MenuItemContent(
                                    title: "Payment",
                                    subtitle: "Cards & billing"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                coordinator.navigate(to: .transferTicketsList)
                            }) {
                                MenuItemContent(
                                    title: "Transfer Tickets",
                                    subtitle: "Transfer your ticket to another user"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            // --- Scanner Visibility FIX ---
                            if userRole == "siteAdmin" {
                                Button(action: {
                                    coordinator.navigate(to: .scanner)
                                }) {
                                    MenuItemContent(
                                        title: "Scanner",
                                        subtitle: "Scan QR codes"
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            // --- End Scanner Visibility FIX ---
                        }

                        MenuSection(title: "APP") {
                            if needsBurnerSetup {
                                Button(action: {
                                    // The `showBurnerSetup` now requires a completion handler
                                    coordinator.showBurnerSetup(onCompletion: {})
                                }) {
                                    MenuItemContent(
                                        title: "Setup Burner Mode",
                                        subtitle: "Complete setup to access tickets"
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            Button(action: {
                                coordinator.navigate(to: .notifications)
                            }) {
                                MenuItemContent(
                                    title: "Notifications",
                                    subtitle: "Manage notification preferences"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())

                            Button(action: {
                                coordinator.navigate(to: .support)
                            }) {
                                MenuItemContent(
                                    title: "Help & Support",
                                    subtitle: "Get help, terms, privacy"
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        // --- Debug Menu Visibility FIX ---
                        if userRole == "siteAdmin" {
                            MenuSection(title: "DEBUG") {
                                Button(action: {
                                    coordinator.navigate(to: .debugMenu)
                                }) {
                                    MenuItemContent(
                                        title: "Debug Menu",
                                        subtitle: "Development tools"
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        // --- End Debug Menu Visibility FIX ---
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Task {
                await loadCurrentUser()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            Task {
                await loadCurrentUser()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))) { _ in
            currentUserEmail = nil
            presentationMode.wrappedValue.dismiss()
        }
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: Binding(
                get: { burnerManager.selectedApps },
                set: { burnerManager.selectedApps = $0 }
            )
        )
    }
    
    private func loadCurrentUser() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            await MainActor.run {
                currentUserEmail = session.user.email
            }
        } catch {
            await MainActor.run {
                currentUserEmail = nil
            }
        }
    }
}
