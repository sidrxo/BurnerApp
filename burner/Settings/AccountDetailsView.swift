import SwiftUI
import Supabase

struct AccountDetailsView: View {
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
                    deleteAccountAfterReauth()
                },
                onCancel: {
                    showingReauthenticationSheet = false
                }
            )
        }
        .onAppear {
            fetchUserInfo()
        }
    }
    
    private func fetchUserInfo() {
        guard let userId = appState.authService.currentUser?.id.uuidString else { return }
        
        Task {
            do {
                // Fetch user profile from Supabase
                if let profile = try await DependencyContainer.shared.userRepository.fetchUserProfile(userId: userId) {
                    await MainActor.run {
                        self.displayName = profile.displayName
                        self.email = profile.email
                        self.userRole = profile.role
                    }
                }
                
                // Also get role from user metadata (custom claims equivalent)
                let session = try await SupabaseManager.shared.client.auth.session
                if let role = session.user.userMetadata["role"] as? String {
                    await MainActor.run {
                        self.userRole = role
                    }
                }
            } catch {
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

            appState.handleManualSignOut()
            UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

            try appState.authService.signOut()

            NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)

            presentationMode.wrappedValue.dismiss()
        } catch {
            // Sign out failed, keep user in view
        }
        isSigningOut = false
    }
    
    private func deleteAccount() {
        guard let userId = appState.authService.currentUser?.id.uuidString else { return }

        Task {
            do {
                // Note: Supabase requires server-side user deletion for security
                // You'll need to create an Edge Function or backend API endpoint
                // For now, this assumes you have a function that handles deletion
                
                // Example: Call your backend function
                // let response = try await SupabaseManager.shared.client.functions
                //     .invoke("delete-user", options: FunctionInvokeOptions(body: ["userId": userId]))
                
                // For demonstration, we'll try the admin API (this will fail without service role)
                // In production, replace this with a call to your backend function
                try await SupabaseManager.shared.client.auth.signOut()
                
                await MainActor.run {
                    if #available(iOS 16.1, *) {
                        TicketLiveActivityManager.endLiveActivity()
                    }

                    UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")

                    appState.handleManualSignOut()
                    NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
                    presentationMode.wrappedValue.dismiss()

                    coordinator.selectTab(.explore)
                    coordinator.popToRoot(in: .explore)
                }
            } catch {
                await MainActor.run {
                    deleteErrorMessage = error.localizedDescription
                    showingDeleteError = true
                }
            }
        }
    }

    private func deleteAccountAfterReauth() {
        // Re-authentication already handled in ReauthenticationView
        // Just proceed with deletion
        deleteAccount()
    }
}
