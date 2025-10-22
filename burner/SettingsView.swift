import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls
import ManagedSettings
import Combine

struct SettingsView: View {
    // ✅ Access AppState to control sign-in sheet
    @EnvironmentObject var appState: AppState
    
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var userRole: String = ""
    @State private var showingAppPicker = false
    @State private var showingBurnerSetup = false
    @State private var isScannerActive = false

    private let db = Firestore.firestore()
    
    // Use shared burner manager from AppState
    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 0) {
                    // Only show header when signed in
                    if currentUser != nil {
                        HeaderSection(title: "Settings")
                    }
                    
                    if currentUser != nil {
                        ScrollView {
                            VStack(spacing: 0) {
                                // ACCOUNT Section
                                CustomMenuSection(title: "ACCOUNT") {
                                    NavigationLink(destination: AccountDetailsView()) {
                                        CustomMenuItemContent(
                                            title: "Account Details",
                                            subtitle: currentUser?.email ?? "View Account"
                                        )
                                    }
                                    NavigationLink(destination: BookmarksView()) {
                                        CustomMenuItemContent(title: "Bookmarks", subtitle: "Saved events")
                                    }
                                    NavigationLink(destination: PaymentSettingsView()) {
                                        CustomMenuItemContent(title: "Payment", subtitle: "Cards & billing")
                                    }

                                    // Only show scanner option if user has scanner role AND active status
                                    // Admin roles (siteAdmin, venueAdmin, subAdmin) can always access scanner
                                    if (userRole == "scanner" && isScannerActive) ||
                                       userRole == "siteAdmin" ||
                                       userRole == "venueAdmin" ||
                                       userRole == "subAdmin" {
                                        NavigationLink(destination: ScannerView()) {
                                            CustomMenuItemContent(title: "Scanner", subtitle: "Scan QR codes")
                                        }
                                    }
                                }
                                
                                // APP Section
                                CustomMenuSection(title: "APP") {
                                    // ⚙️ Setup Guide Button
                                    Button(action: {
                                        showingBurnerSetup = true
                                    }) {
                                        CustomMenuItemContent(
                                            title: "Setup Burner Mode",
                                            subtitle: "Configure app blocking"
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    NavigationLink(destination: SupportView()) {
                                        CustomMenuItemContent(title: "Help & Support", subtitle: "Get help, terms, privacy")
                                    }
                                }

                                // DEBUG Section
                                #if DEBUG
                                CustomMenuSection(title: "DEBUG") {
                                    Button(action: {
                                        resetOnboarding()
                                    }) {
                                        CustomMenuItemContent(
                                            title: "Reset Onboarding",
                                            subtitle: "Show first-time setup again"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        refreshCustomClaims()
                                    }) {
                                        CustomMenuItemContent(
                                            title: "Refresh Custom Claims",
                                            subtitle: "Force reload user permissions"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // ✅ NEW: Manual lock screen trigger for testing
                                    Button(action: {
                                        appState.showingBurnerLockScreen.toggle()
                                    }) {
                                        CustomMenuItemContent(
                                            title: "Toggle Lock Screen",
                                            subtitle: "Test Burner Mode lock screen"
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
        }
        .onAppear {
            currentUser = Auth.auth().currentUser
            fetchUserRoleFromClaims()
            checkScannerAccessFromClaims()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
            fetchUserRoleFromClaims()
            checkScannerAccessFromClaims()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))) { _ in
            currentUser = nil
            userRole = ""
            isScannerActive = false
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn)
        }
        .fullScreenCover(isPresented: $showingBurnerSetup) {
            BurnerModeSetupView(burnerManager: burnerManager)
        }
        // ✅ REMOVED: Lock screen is now handled globally in BurnerApp
    }
    
    // MARK: - Fetch Role from Custom Claims
    private func fetchUserRoleFromClaims() {
        guard Auth.auth().currentUser != nil else {
            userRole = ""
            return
        }

        print("🔵 [Settings] Fetching role from custom claims")
        
        Task {
            do {
                if let role = try await appState.authService.getUserRole() {
                    await MainActor.run {
                        self.userRole = role
                        print("✅ [Settings] User role from custom claims: \(role)")
                    }
                } else {
                    await MainActor.run {
                        self.userRole = "user"
                        print("⚠️ [Settings] No role in custom claims, defaulting to 'user'")
                    }
                }
            } catch {
                print("🔴 [Settings] Error fetching custom claims: \(error.localizedDescription)")
                await MainActor.run {
                    self.userRole = "user"
                }
            }
        }
    }

    private func checkScannerAccessFromClaims() {
        guard Auth.auth().currentUser != nil else {
            isScannerActive = false
            return
        }

        print("🔵 [Settings] Checking scanner access from custom claims")
        
        Task {
            do {
                let active = try await appState.authService.isScannerActive()
                await MainActor.run {
                    self.isScannerActive = active
                    print("✅ [Settings] Scanner active from custom claims: \(active)")
                }
            } catch {
                print("🔴 [Settings] Error checking scanner access: \(error.localizedDescription)")
                await MainActor.run {
                    self.isScannerActive = false
                }
            }
        }
    }
    
    // MARK: - Not signed in view
    private var notSignedInSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.crop.circle")
                .font(.appLargeIcon)
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Not Signed In")
                    .appSectionHeader()
                    .foregroundColor(.white)
                Text("Sign in to access your settings")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingSignIn = true
            } label: {
                Text("Sign In")
                    .appBody()
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
    
    // MARK: - Reset Onboarding
    private func resetOnboarding() {
        let onboarding = OnboardingManager()
        onboarding.resetOnboarding()
        NotificationCenter.default.post(name: NSNotification.Name("ResetOnboarding"), object: nil)
    }
    
    // MARK: - Refresh Custom Claims (DEBUG)
    private func refreshCustomClaims() {
        print("🔄 [Settings] Manually refreshing custom claims...")
        fetchUserRoleFromClaims()
        checkScannerAccessFromClaims()
    }
}

struct CustomMenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .appCaption()
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content
            }
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.bottom, 24)
    }
}

struct CustomMenuItemContent: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .appBody()
                    .foregroundColor(.white)
                Text(subtitle)
                    .appSecondary()
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .appCaption()
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
