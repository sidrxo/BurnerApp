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
    @State private var isBurnerModeEnabled = false
    @State private var showingAppPicker = false
    @State private var showingBurnerSetup = false
    @State private var showingAutoEnabledAlert = false
    
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
                                    
                                    // Only show scanner option if user has scanner role
                                    if userRole == "scanner" || userRole == "siteAdmin" || userRole == "venueAdmin" {
                                        NavigationLink(destination: ScannerView()) {
                                            CustomMenuItemContent(title: "Scanner", subtitle: "Scan QR codes")
                                        }
                                    }
                                }
                                
                                // APP Section
                                CustomMenuSection(title: "APP") {
                                    // 🔘 Manual Burner Mode Toggle
                                    Toggle(isOn: $isBurnerModeEnabled) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Burner Mode")
                                                .appBody()
                                                .foregroundColor(.white)
                                            Text("Manually enable or disable blocking")
                                                .appSecondary()
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .tint(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .onChange(of: isBurnerModeEnabled) { oldValue, newValue in
                                        if newValue {
                                            if burnerManager.isSetupValid {
                                                burnerManager.enable()
                                            } else {
                                                // Revert toggle if setup invalid
                                                isBurnerModeEnabled = false
                                                appState.showError("Please complete Burner Mode setup first.")
                                                showingBurnerSetup = true
                                            }
                                        } else {
                                            burnerManager.disable()
                                        }
                                    }
                                    Divider().background(Color.gray.opacity(0.3))

                                    // ⚙️ Setup Guide Button
                                    Button(action: {
                                        showingBurnerSetup = true
                                    }) {
                                        CustomMenuItemContent(
                                            title: "Setup Burner Mode",
                                            subtitle: "Step-by-step setup guide"
                                        )
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
            fetchUserRole()
            isBurnerModeEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
            
            // Setup notification observer for auto-enabled burner mode
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("BurnerModeAutoEnabled"),
                object: nil,
                queue: .main
            ) { _ in
                showingAutoEnabledAlert = true
                isBurnerModeEnabled = true
            }
        }
        .alert("Burner Mode Enabled", isPresented: $showingAutoEnabledAlert) {
            Button("OK") { }
        } message: {
            Text("Burner Mode has been automatically enabled because your ticket was scanned for today's event.")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
            fetchUserRole()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedOut"))) { _ in
            currentUser = nil
            userRole = ""
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn)
        }
        .fullScreenCover(isPresented: $showingBurnerSetup) {
            BurnerModeSetupView(burnerManager: burnerManager)
        }
    }
    
    // MARK: - Fetch Role
    private func fetchUserRole() {
        guard let userId = Auth.auth().currentUser?.uid else {
            userRole = ""
            return
        }
        
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let data = snapshot?.data(),
                   let role = data["role"] as? String {
                    userRole = role
                } else {
                    userRole = "user"
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
