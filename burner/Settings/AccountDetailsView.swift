import SwiftUI
import Supabase

struct AccountDetailsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator

    @State private var showingSignOut = false
    @State private var showingDeleteAccount = false
    @State private var showingDeleteAccountFinal = false
    @State private var isSigningOut = false
    @State private var showingReauthenticationSheet = false // Reauthentication logic was removed, but state remains
    @State private var deleteErrorMessage: String?
    @State private var showingDeleteError = false
    @Environment(\.presentationMode) var presentationMode

    // Computed properties for cleaner access to data
    private var currentUser: User? {
        appState.authService.currentUser
    }
    
    // Get display name directly from the AppState, which is sourced from the UserProfile (database)
    private var currentDisplayName: String {
        appState.userDisplayName
    }
    
    private var currentEmail: String {
        currentUser?.email ?? ""
    }
    
    // Role is also sourced from AppState
    private var currentRole: String {
        appState.userRole.isEmpty ? "user" : appState.userRole
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HeaderSection(title: "Account Details", includeTopPadding: false, includeHorizontalPadding: false)
                MenuSection(title: "PROFILE") {
                    // Name
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Name")
                                .appBody()
                                .foregroundColor(.white)
                            // Use the centrally managed display name
                            Text(currentDisplayName.isEmpty ? "(No Name Set)" : currentDisplayName)
                                .appSecondary()
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Email
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .appBody()
                                .foregroundColor(.white)
                            // Use the email from the Auth object
                            Text(currentEmail.isEmpty ? "(No Email Set)" : currentEmail)
                                .appSecondary()
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Role
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Role")
                                .appBody()
                            .foregroundColor(.white)
                            // Use the centrally managed role
                            Text(currentRole)
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
                        deleteAccount() // Calls the secure deletion function
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
        // Removed unnecessary .sheet for ReauthenticationView, as that logic was simplified
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

            // Dismiss the view (works immediately due to synchronous nature of signOut())
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
                // Step 1: Call the Supabase Edge Function (Server-side deletion of user and data)
                try await SupabaseManager.shared.client.functions
                    .invoke(
                        "delete-user",
                        options: FunctionInvokeOptions(
                            headers: [
                                "Authorization": "Bearer \(try await SupabaseManager.shared.client.auth.session.accessToken)"
                            ],
                            body: ["userId": userId]
                        )
                    )
                
                // Server success -> Perform local cleanup and UI updates.
                
                await MainActor.run {
                    
                    // FIX: Clear Navigation Stacks of the hosting tab (Tickets) and the destination tab (Explore)
                    coordinator.popToRoot(in: .tickets)
                    coordinator.popToRoot(in: .explore)
                    
                    // Dismiss the AccountDetailsView
                    presentationMode.wrappedValue.dismiss()
                    
                    // Switch to the desired tab
                    coordinator.selectTab(.explore)
                    
                    // Perform local app state cleanup
                    if #available(iOS 16.1, *) {
                        TicketLiveActivityManager.endLiveActivity()
                    }
                    UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    appState.handleManualSignOut()
                    NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
                }

                // Step 2: Finally, destroy the local session (this must happen after server confirmation)
                try appState.authService.signOut()

            } catch {
                await MainActor.run {
                    deleteErrorMessage = "Deletion failed. Error: \(error.localizedDescription)"
                    showingDeleteError = true
                    
                    // Keep safety sign-out in the error block
                    try? appState.authService.signOut()
                }
            }
        }
    }

    private func deleteAccountAfterReauth() {
        // Since reauthentication was not implemented, this just proceeds with deletion.
        deleteAccount()
    }
    
    // Helper struct for decoding the function response (only used for type checking now)
    private struct FunctionResponse: Codable {
        let message: String
    }
}
