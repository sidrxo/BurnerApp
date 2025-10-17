import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls
import ManagedSettings
import Combine

struct SettingsView: View {
    // ✅ NEW: Access AppState to control sign-in sheet
    @EnvironmentObject var appState: AppState
    
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var userRole: String = ""
    @State private var isBurnerModeEnabled = false
    @State private var showingAppPicker = false
    @State private var showingBurnerSetup = false
    @StateObject private var burnerManager = BurnerModeManager()
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
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
                                Button(action: {
                                    showingBurnerSetup = true
                                }) {
                                    CustomMenuItemContent(
                                        title: "Setup Burner Mode",
                                        subtitle: "Step-by-step setup guide"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Burner Mode")
                                            .appBody()
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Toggle("", isOn: $isBurnerModeEnabled)
                                        .toggleStyle(SwitchToggleStyle(tint: burnerManager.isSetupValid ? .blue : .gray))
                                        .disabled(!burnerManager.isSetupValid)
                                        .onChange(of: isBurnerModeEnabled) { oldValue, newValue in
                                            if newValue {
                                                burnerManager.enable()
                                            } else {
                                                burnerManager.disable()
                                            }
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                
                                NavigationLink(destination: SupportView()) {
                                    CustomMenuItemContent(title: "Help & Support", subtitle: "Get help, terms, privacy")
                                }
                            }
                            
                            // DEBUG Section
                            #if DEBUG
                            CustomMenuSection(title: "DEBUG") {
                                Button(action: {
                                    // Reset onboarding for testing
                                    let onboarding = OnboardingManager()
                                    onboarding.resetOnboarding()
                                    
                                    // Restart the app to show onboarding
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first {
                                        window.rootViewController = UIHostingController(
                                            rootView: ContentView()
                                                .environmentObject(AppState())
                                        )
                                        window.makeKeyAndVisible()
                                    }
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
                        selection: $burnerManager.selectedApps
                    )
                } else {
                    notSignedInSection
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .background(Color.black)
        .onAppear {
            currentUser = Auth.auth().currentUser
            fetchUserRole()
            isBurnerModeEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
            fetchUserRole()
        }
        // ✅ NEW: Listen for sign out events
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
                    userRole = "user" // default role
                }
            }
        }
    }
    
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
