import SwiftUI
import Combine
import Supabase

struct ReauthenticationView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void

    @State private var password = ""
    @State private var isReauthenticating = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    private let supabase = SupabaseManager.shared.client

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("Re-authentication Required")
                            .appSectionHeader()
                            .foregroundColor(.white)

                        Text("For security reasons, please confirm your password to delete your account.")
                            .appBody()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 16) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(white: 0.15))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .appSecondary()
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: reauthenticate) {
                            if isReauthenticating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Confirm")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(SecondaryButton(
                            backgroundColor: password.isEmpty ? Color.gray : Color.white,
                            foregroundColor: .black
                        ))
                        .disabled(password.isEmpty || isReauthenticating)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(.white)
            )
        }
    }

    private func reauthenticate() {
        Task {
            guard let session = try? await supabase.auth.session,
                  let email = session.user.email else {
                await MainActor.run {
                    errorMessage = "Unable to get user email"
                }
                return
            }

            await MainActor.run {
                isReauthenticating = true
                errorMessage = nil
            }

            do {
                // Re-authenticate by signing in again with email and password
                // This verifies the user's credentials
                _ = try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                
                await MainActor.run {
                    isReauthenticating = false
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    isReauthenticating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
