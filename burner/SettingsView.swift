import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FamilyControls
import ManagedSettings
import Combine

struct SettingsView: View {
    @State private var showingSignIn = false
    @State private var currentUser: FirebaseAuth.User?
    @State private var userRole: String = ""
    @State private var isBurnerModeEnabled = false
    @State private var showingAppPicker = false
    @StateObject private var burnerManager = BurnerModeManager()
    
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
                                        subtitle: currentUser?.email ?? "View Account"
                                    )
                                }
                                NavigationLink(destination: TicketsView()) {
                                    CustomMenuItemContent(title: "My Tickets", subtitle: "View purchases")
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
                                NavigationLink(destination: NotificationSettingsView()) {
                                    CustomMenuItemContent(title: "Notifications", subtitle: "Push alerts")
                                }
                                
                                // App Selector Button
                                Button(action: {
                                    showingAppPicker = true
                                }) {
                                    VStack(spacing: 0) {
                                        CustomMenuItemContent(
                                            title: "Select Apps to Keep Available",
                                            subtitle: burnerManager.getSelectedAppsDescription()
                                        )
                                        
                                        // Block-all mode indicator
                                        if burnerManager.hasAllCategoriesSelected() {
                                            HStack {
                                                Image(systemName: "shield.fill")
                                                    .foregroundColor(.green)
                                                    .font(.caption)
                                                Text("All categories selected - Block-All Mode ready")
                                                    .appFont(size: 12)
                                                    .foregroundColor(.green)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 4)
                                        }
                                        
                                        // Validation message
                                        if !burnerManager.isSetupValid {
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .foregroundColor(.orange)
                                                    .font(.caption)
                                                Text(burnerManager.getSetupValidationMessage())
                                                    .appFont(size: 12)
                                                    .foregroundColor(.orange)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 8)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Simple Burner Mode Toggle
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Burner Mode")
                                            .appFont(size: 16, weight: .medium)
                                            .foregroundColor(.white)
                                        Text(isBurnerModeEnabled ? "All apps blocked except selected" :
                                             burnerManager.isSetupValid ? "Ready to block all apps" : "Must select all categories first")
                                            .appFont(size: 14)
                                            .foregroundColor(burnerManager.isSetupValid ? .gray : .orange)
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
                .familyActivityPicker(
                    isPresented: $showingAppPicker,
                    selection: $burnerManager.selectedApps
                )
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
            isBurnerModeEnabled = UserDefaults.standard.bool(forKey: "burnerModeEnabled")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            currentUser = Auth.auth().currentUser
            fetchUserRole()
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn)
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

// MARK: - Burner Mode Manager

@MainActor
class BurnerModeManager: ObservableObject {
    @Published var selectedApps = FamilyActivitySelection() {
        didSet {
            saveSelectedApps()
            checkSetupCompliance()
        }
    }
    @Published var isSetupValid = false
    @Published var setupError: String?
    
    private let store = ManagedSettingsStore()
    
    // All possible categories that exist in iOS
    // This is a comprehensive list - adjust based on what you want to require
    private let allRequiredCategories = [
        "Social", "Games", "Entertainment", "Creativity", "Productivity",
        "Education", "Utilities", "Business", "Developer Tools", "Graphics & Design",
        "Lifestyle", "Music", "News", "Photo & Video", "Shopping",
        "Sports", "Travel", "Health & Fitness", "Food & Drink", "Finance",
        "Weather", "Reference", "Navigation", "Medical", "Books"
    ]
    
    // Minimum categories required (you can set this to all categories)
    private let minimumCategoriesRequired = 8 // Must select 11+ categories
    
    init() {
        loadSelectedApps()
        checkSetupCompliance()
    }
    
    func hasAllCategoriesSelected() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        return categoryCount >= minimumCategoriesRequired
    }
   
    @discardableResult
    func checkSetupCompliance() -> Bool {
        let categoryCount = selectedApps.categoryTokens.count
        
        // Require all categories to be selected
        if categoryCount < minimumCategoriesRequired {
            setupError = "Please select at least \(minimumCategoriesRequired) app categories (\(categoryCount)/\(minimumCategoriesRequired) selected)"
            isSetupValid = false
            return false
        }
        
        setupError = nil
        isSetupValid = true
        return true
    }
    
    func getSetupValidationMessage() -> String {
        if isSetupValid {
            return "✓ Ready for Block-All Mode"
        } else {
            return setupError ?? "Setup incomplete"
        }
    }
    
    func getSelectedAppsDescription() -> String {
        let appCount = selectedApps.applicationTokens.count
        let categoryCount = selectedApps.categoryTokens.count
        
        if hasAllCategoriesSelected() {
            return appCount > 0 ? "\(appCount) apps will stay available" : "All apps will be blocked"
        } else if categoryCount > 0 {
            return "\(categoryCount) categories selected - Need \(minimumCategoriesRequired) total"
        } else {
            return "Select \(minimumCategoriesRequired) categories to enable block-all mode"
        }
    }
    
    private func loadSelectedApps() {
        if let data = UserDefaults.standard.data(forKey: "selectedApps"),
           let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selectedApps = selection
        }
    }
    
    private func saveSelectedApps() {
        if let data = try? JSONEncoder().encode(selectedApps) {
            UserDefaults.standard.set(data, forKey: "selectedApps")
        }
    }
    
    func enable() {
        guard isSetupValid else {
            print("Cannot enable: Must select at least \(minimumCategoriesRequired) categories first")
            return
        }
        
        guard hasAllCategoriesSelected() else {
            print("Cannot enable: Not enough categories selected")
            return
        }
        
        print("Enabling Block-All Burner Mode...")
        print("Categories selected: \(selectedApps.categoryTokens.count)")
        print("Apps to keep available: \(selectedApps.applicationTokens.count)")
        
        // Request authorization
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Authorization error: \(error)")
            }
        }
        
        // Block ALL categories except the selected apps (if any)
        if selectedApps.applicationTokens.isEmpty {
            // Block everything - no exceptions
            store.shield.applicationCategories = .all()
        } else {
            // Block all except selected apps
            store.shield.applicationCategories = .all(except: selectedApps.applicationTokens)
        }
        
        UserDefaults.standard.set(true, forKey: "burnerModeEnabled")
        print("Block-All Burner mode enabled")
    }
    
    func disable() {
        print("Disabling burner mode...")
        store.clearAllSettings()
        UserDefaults.standard.set(false, forKey: "burnerModeEnabled")
        print("Burner mode disabled")
    }
    
    func clearAllSelections() {
        selectedApps = FamilyActivitySelection()
        UserDefaults.standard.removeObject(forKey: "selectedApps")
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
