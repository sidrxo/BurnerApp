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
        !burnerManager.isSetup || !burnerManager.isAuthorized
    }
    
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Only show header when signed in
                if currentUser != nil {
                    HeaderSection(title: "Settings")
                }
                
                if currentUser != nil {
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
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    coordinator.navigate(to: .bookmarks)
                                }) {
                                    MenuItemContent(
                                        title: "Bookmarks",
                                        subtitle: "Saved events"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    coordinator.navigate(to: .paymentSettings)
                                }) {
                                    MenuItemContent(
                                        title: "Payment",
                                        subtitle: "Cards & billing"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    coordinator.navigate(to: .transferTicketsList)
                                }) {
                                    MenuItemContent(
                                        title: "Transfer Tickets",
                                        subtitle: "Transfer your ticket to another user"
                                    )
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
                                            subtitle: burnerManager.isAuthorized
                                            ? "Configure app blocking"
                                            : "Screen Time permissions needed"
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                Button(action: {
                                    coordinator.navigate(to: .support)
                                }) {
                                    MenuItemContent(
                                        title: "Help & Support",
                                        subtitle: "Get help, terms, privacy"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // DEBUG Section
#if DEBUG
                            MenuSection(title: "DEBUG") {
                                Button(action: {
                                    coordinator.navigate(to: .debugMenu)
                                }) {
                                    MenuItemContent(
                                        title: "Debug Menu",
                                        subtitle: "Development tools"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
#endif
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                } else {
                    notSignedInSection
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentUser = Auth.auth().currentUser
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))) { _ in
            currentUser = nil
        }
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: Binding(
                get: { burnerManager.selectedApps },
                set: { burnerManager.selectedApps = $0 }
            )
        )
    }
    // MARK: - Not signed in view
    private var notSignedInSection: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                // ✅ Add fixed-height frame around image
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140) // ← fixed height
                    .frame(maxWidth: .infinity) // center horizontally
                    .padding(.bottom, 30)
                
                VStack(spacing: 8) {
                    Text("WHERE WILL YOU GO")
                        .appSectionHeader()
                        .foregroundColor(.white)
                    Text("Be part of what's next in music.")
                        .appBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    coordinator.showSignIn()
                } label: {
                    Text("SIGN IN")
                        .font(.appFont(size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
