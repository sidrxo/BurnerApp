import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls
import ManagedSettings
import Combine


struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    @State private var currentUser: FirebaseAuth.User?
    @State private var showingAppPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    private let db = Firestore.firestore()
    
    // Use shared burner manager from AppState
    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }
    
    // Access role and scanner status from AppState
    private var userRole: String {
        appState.userRole
    }
    
    private var isScannerActive: Bool {
        appState.isScannerActive
    }
    
    // Check if burner mode needs setup
    private var needsBurnerSetup: Bool {
        !burnerManager.hasCompletedSetup || !burnerManager.isSetupValid
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // ACCOUNT Section
                        MenuSection(title: "ACCOUNT") {
                            Button(action: {
                                coordinator.navigate(to: .accountDetails)
                            }) {
                                MenuItemContent(
                                    title: "Account Details",
                                    subtitle: currentUser?.email ?? "View Account"
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

                            // Scanner access for authorized roles
                            if (userRole == "scanner" && isScannerActive) ||
                                userRole == "siteAdmin" ||
                                userRole == "venueAdmin" ||
                                userRole == "subAdmin" {
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
                        }

                        // APP Section
                        MenuSection(title: "APP") {
                            // Show Setup Guide Button only when needed
                            if needsBurnerSetup {
                                Button(action: {
                                    coordinator.showBurnerSetup()
                                }) {
                                    MenuItemContent(
                                        title: "Setup Burner Mode",
                                        subtitle: burnerManager.isSetupValid
                                        ? "Configure app blocking"
                                        : "Screen Time permissions needed"
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

                        // DEBUG Section - Only for siteadmin
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
            currentUser = Auth.auth().currentUser
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))) { _ in
            currentUser = nil
            // Dismiss settings view when user signs out
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
}
