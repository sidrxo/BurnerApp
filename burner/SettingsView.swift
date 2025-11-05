import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls
import ManagedSettings
import Combine


struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var showingAppPicker = false
    @State private var showingBurnerSetup = false
    
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
                                NavigationLink(destination: AccountDetailsView()) {
                                    MenuItemContent(
                                        title: "Account Details",
                                        subtitle: currentUser?.email ?? "View Account"
                                    )
                                }
                                
                                NavigationLink(destination: BookmarksView()) {
                                    MenuItemContent(
                                        title: "Bookmarks",
                                        subtitle: "Saved events"
                                    )
                                }
                                
                                NavigationLink(destination: PaymentSettingsView()) {
                                    MenuItemContent(
                                        title: "Payment",
                                        subtitle: "Cards & billing"
                                    )
                                }
                                
                                NavigationLink(destination: TransferTicketsListView()) {
                                    MenuItemContent(
                                        title: "Transfer Tickets",
                                        subtitle: "Transfer your ticket to another user"
                                    )
                                }
                                
                                // Scanner access for authorized roles
                                if (userRole == "scanner" && isScannerActive) ||
                                    userRole == "siteAdmin" ||
                                    userRole == "venueAdmin" ||
                                    userRole == "subAdmin" {
                                    NavigationLink(destination: ScannerView()) {
                                        MenuItemContent(
                                            title: "Scanner",
                                            subtitle: "Scan QR codes"
                                        )
                                    }
                                }
                            }
                            
                            // APP Section
                            MenuSection(title: "APP") {
                                // Show Setup Guide Button only when needed
                                if needsBurnerSetup {
                                    Button(action: {
                                        showingBurnerSetup = true
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
                                
                                NavigationLink(destination: SupportView()) {
                                    MenuItemContent(
                                        title: "Help & Support",
                                        subtitle: "Get help, terms, privacy"
                                    )
                                }
                            }
                            
                            // DEBUG Section
                            #if DEBUG
                            MenuSection(title: "DEBUG") {
                                NavigationLink(
                                    destination: DebugMenuView(
                                        appState: appState,
                                        burnerManager: burnerManager
                                    )
                                ) {
                                    MenuItemContent(
                                        title: "Debug Menu",
                                        subtitle: "Development tools"
                                    )
                                }
                            }
                            #endif
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .familyActivityPicker(
                        isPresented: $showingAppPicker,
                        selection: Binding(
                            get: { burnerManager.selectedApps },
                            set: { burnerManager.selectedApps = $0 }
                        )
                    )
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
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn)
        }
        .fullScreenCover(isPresented: $showingBurnerSetup) {
            BurnerModeSetupView(burnerManager: burnerManager)
        }
    }
    
    // MARK: - Not signed in view
    private var notSignedInSection: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("transparent")
                .resizable()
                .scaledToFit()
                .frame(width: 180)
                .clipShape(Circle()) // 👈 makes it circular
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
                showingSignIn = true
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
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
