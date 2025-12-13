
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountDetailsView: View {
    // ✅ NEW: Access AppState
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator

    @State private var displayName = ""
    @State private var email = ""
    @State private var userRole = ""
    @State private var showingSignOut = false
    @State private var showingDeleteAccount = false
    @State private var showingDeleteAccountFinal = false
    @State private var isSigningOut = false
    @State private var showingReauthenticationSheet = false
    @State private var deleteErrorMessage: String?
    @State private var showingDeleteError = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderSection(title: "Account Details", includeTopPadding: false, includeHorizontalPadding: false)
                MenuSection(title: "PROFILE") {
                    // Name first, then Email
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Name")
                                .appBody()
                                .foregroundColor(.white)
                            Text(displayName.isEmpty ? "(No Name Set)" : displayName)
                                .appSecondary()
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .appBody()
                                .foregroundColor(.white)
                            Text(email.isEmpty ? "(No Email Set)" : email)
                                .appSecondary()
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Role")
                                .appBody()
                                .foregroundColor(.white)
                            Text(userRole.isEmpty ? "user" : userRole)
                                .appSecondary()
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }

                MenuSection(title: "ACCOUNT ACTIONS") {
                    Button(action: { showingSignOut = true }) {
                        HStack {
                            Text("Sign Out")
                                .appBody()
                                .foregroundColor(.red)
                            Spacer()
                            if isSigningOut {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .disabled(isSigningOut)

                    Button(action: { showingDeleteAccount = true }) {
                        HStack {
                            Text("Delete Account")
                                .appBody()
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .background(Color.black)

            if showingSignOut {
                CustomAlertView(
                    title: "Sign Out",
                    description: "Are you sure you want to sign out?",
                    cancelAction: { showingSignOut = false },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showingSignOut = false
                        signOut()
                    },
                    primaryActionTitle: "Sign Out",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showingDeleteAccount {
                CustomAlertView(
                    title: "Delete Account",
                    description: "Are you sure you want to delete your account? This will remove all your data.",
                    cancelAction: { showingDeleteAccount = false },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showingDeleteAccount = false
                        showingDeleteAccountFinal = true
                    },
                    primaryActionTitle: "Continue",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }

            if showingDeleteAccountFinal {
                CustomAlertView(
                    title: "Final Confirmation",
                    description: "This action cannot be undone. Your account and all tickets will be permanently deleted.",
                    cancelAction: { showingDeleteAccountFinal = false },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        showingDeleteAccountFinal = false
                        deleteAccount()
                    },
                    primaryActionTitle: "Delete",
                    primaryActionColor: .red,
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1002)
            }

            if showingDeleteError {
                CustomAlertView(
                    title: "Delete Account Failed",
                    description: deleteErrorMessage ?? "An error occurred while deleting your account.",
                    cancelAction: { showingDeleteError = false },
                    cancelActionTitle: "OK",
                    primaryAction: nil,
                    primaryActionTitle: nil,
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1003)
            }
        }
        .sheet(isPresented: $showingReauthenticationSheet) {
            ReauthenticationView(
                onSuccess: {
                    showingReauthenticationSheet = false
                    // Try deletion again after re-authentication
                    deleteAccountAfterReauth()
                },
                onCancel: {
                    showingReauthenticationSheet = false
                }
            )
        }
        .onAppear {
            fetchUserInfoFromFirestore()
        }
    }
    
    private func fetchUserInfoFromFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                self.displayName = data["displayName"] as? String ?? ""
                self.email = data["email"] as? String ?? ""
                // Don't read role from Firestore - only use custom claims
            }
        }

        // Fetch role from custom claims (the authoritative source)
        Task {
            do {
                let result = try await user.getIDTokenResult(forcingRefresh: false)
                if let role = result.claims["role"] as? String {
                    await MainActor.run {
                        self.userRole = role
                    }
                } else {
                    // No custom claim set, default to "user"
                    await MainActor.run {
                        self.userRole = "user"
                    }
                }
            } catch {
                // On error, default to "user"
                await MainActor.run {
                    self.userRole = "user"
                }
            }
        }
    }

    private func signOut() {
        isSigningOut = true
        do {
            // End all live activities before signing out
            if #available(iOS 16.1, *) {
                TicketLiveActivityManager.endLiveActivity()
            }

            // ✅ FIXED: Notify AppState before signing out
            appState.handleManualSignOut()
            UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

            try Auth.auth().signOut()

            // ✅ Post notification for SettingsView to update
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)

            // Dismiss the view
            presentationMode.wrappedValue.dismiss()
        } catch {
            // Sign out failed, keep user in view
        }
        isSigningOut = false
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }

        user.delete { error in
            if let error = error {
                let nsError = error as NSError
                // Check if re-authentication is required
                if nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
                    // Show re-authentication sheet
                    showingReauthenticationSheet = true
                } else {
                    // Show other errors
                    deleteErrorMessage = error.localizedDescription
                    showingDeleteError = true
                }
            } else {
                // End all live activities before deleting account
                if #available(iOS 16.1, *) {
                    TicketLiveActivityManager.endLiveActivity()
                }

                UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

                // Success - notify AppState and sign out
                appState.handleManualSignOut()
                NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
                presentationMode.wrappedValue.dismiss()

                // Navigate to explore tab
                coordinator.selectTab(.explore)
                coordinator.popToRoot(in: .explore)
            }
        }
    }

    private func deleteAccountAfterReauth() {
        guard let user = Auth.auth().currentUser else { return }

        user.delete { error in
            if let error = error {
                deleteErrorMessage = error.localizedDescription
                showingDeleteError = true
            } else {
                // End all live activities before deleting account
                if #available(iOS 16.1, *) {
                    TicketLiveActivityManager.endLiveActivity()
                }

                // Success - notify AppState and sign out
                appState.handleManualSignOut()
                NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
                presentationMode.wrappedValue.dismiss()

                // Navigate to explore tab
                coordinator.selectTab(.explore)
                coordinator.popToRoot(in: .explore)
            }
        }
    }
}
