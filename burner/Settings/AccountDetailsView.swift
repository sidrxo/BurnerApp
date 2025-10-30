
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AccountDetailsView: View {
    // ✅ NEW: Access AppState
    @EnvironmentObject var appState: AppState
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var showingSignOut = false
    @State private var showingDeleteAccount = false
    @State private var isSigningOut = false
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            SettingsHeaderSection(title: "Account Details")
            CustomMenuSection(title: "PROFILE") {
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
            }
            
            CustomMenuSection(title: "ACCOUNT ACTIONS") {
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
        .alert("Sign Out", isPresented: $showingSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { signOut() }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { deleteAccount() }
        } message: {
            Text("This action cannot be undone.")
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
            }
        }
    }

    private func signOut() {
        isSigningOut = true
        do {
            // ✅ FIXED: Notify AppState before signing out
            appState.handleManualSignOut()
            
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
        
        // ✅ FIXED: Notify AppState before deleting account
        appState.handleManualSignOut()
        
        user.delete { error in
            if error == nil {
                // ✅ Post notification
                NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)

                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
