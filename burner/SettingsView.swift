import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls

struct SettingsView: View {
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var userRole: String = ""
    @State private var burnerModeEnabled = false
    @State private var showingBurnerModeSetup = false
    
    @StateObject private var burnerModeManager = BurnerModeManager()
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            if currentUser != nil {
                ScrollView {
                    VStack(spacing: 0) {
                        HeaderSection(title: "Settings")
                        
                        VStack(spacing: 0) {
                            // ACCOUNT Section
                            CustomMenuSection(title: "ACCOUNT") {
                                NavigationLink(destination: AccountDetailsView()) {
                                    CustomMenuItemContent(
                                        title: "Account Details",
                                        subtitle: currentUser?.email ?? "View Ac"
                                    )
                                }
                                NavigationLink(destination: TicketsView()) {
                                    CustomMenuItemContent(title: "My Tickets", subtitle: "View purchases")
                                }
                                NavigationLink(destination: FavoritesView()) {
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
                                NavigationLink(destination: NotificationSettingsView()) {
                                    CustomMenuItemContent(title: "Notifications", subtitle: "Push alerts")
                                }
                                
                                // Burner Mode Toggle
                                VStack(spacing: 0) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Burner Mode")
                                                .appFont(size: 16, weight: .medium)
                                                .foregroundColor(.white)
                                            Text(burnerModeEnabled ? "Block distracting apps" : "Allow all apps")
                                                .appFont(size: 14)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Toggle("", isOn: $burnerModeEnabled)
                                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    
                                    if burnerModeEnabled {
                                        Divider()
                                            .background(Color.gray.opacity(0.3))
                                        
                                        Button(action: {
                                            showingBurnerModeSetup = true
                                        }) {
                                            HStack {
                                                Text("Configure Blocked Apps")
                                                    .appFont(size: 14, weight: .medium)
                                                    .foregroundColor(.orange)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .appFont(size: 12, weight: .medium)
                                                    .foregroundColor(.gray)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                    }
                                }
                            }
                            
                            // SUPPORT Section
                            CustomMenuSection(title: "SUPPORT") {
                                NavigationLink(destination: SupportView()) {
                                    CustomMenuItemContent(title: "Help & Support", subtitle: "Get help, terms, privacy")
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
                .background(Color.black)
                .navigationBarHidden(true)
            } else {
                notSignedInSection
                    .navigationBarHidden(true)
                    .background(Color.black)
            }
        }
        .background(Color.black)
        .onAppear {
            currentUser = Auth.auth().currentUser
            fetchUserRole()
            burnerModeEnabled = burnerModeManager.isEnabled
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
            fetchUserRole()
        }
        .onChange(of: burnerModeEnabled) { oldValue, newValue in
            Task {
                if newValue {
                    await burnerModeManager.enableBurnerMode()
                } else {
                    await burnerModeManager.disableBurnerMode()
                }
            }
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn)
        }
        .sheet(isPresented: $showingBurnerModeSetup) {
            BurnerModeSetupView(burnerModeManager: burnerModeManager)
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
        VStack(spacing: 0) {
            HeaderSection(title: "Settings")
            
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("Not Signed In")
                        .appFont(size: 22, weight: .semibold)
                        .foregroundColor(.white)
                    Text("Sign in to access your settings")
                        .appFont(size: 16)
                        .foregroundColor(.gray)
                }
                Button("Sign In") {
                    showingSignIn = true
                }
                .appFont(size: 17, weight: .semibold)
                .foregroundColor(.black)
                .frame(maxWidth: 200)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
            Spacer()
        }
    }
}

// MARK: - Custom Menu Components

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
                .appFont(size: 12, weight: .semibold)
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
                    .appFont(size: 16, weight: .medium)
                    .foregroundColor(.white)
                Text(subtitle)
                    .appFont(size: 14)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .appFont(size: 12, weight: .medium)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
