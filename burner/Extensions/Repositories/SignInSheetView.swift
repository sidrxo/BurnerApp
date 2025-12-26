import SwiftUI
import AuthenticationServices
import CryptoKit
import Combine
import Supabase

struct SignInSheetView: View {
    @Binding var showingSignIn: Bool
    var isOnboarding: Bool = false
    @EnvironmentObject var appState: AppState

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var currentNonce: String?
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var presentationContextProvider: ApplePresentationContextProvider?
    @State private var showingPasswordlessAuth = false
    @State private var showingAccountExistsAlert = false
    @State private var showingLinkSuccessAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var linkSuccessMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 20)

                    VStack(spacing: 16) {
                        signInButtonsSection
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)

                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea(.all)

                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }

                if showingError && !showingAccountExistsAlert && !showingLinkSuccessAlert {
                    CustomAlertView(
                        title: "Sign In Error",
                        description: errorMessage,
                        primaryAction: {
                            errorMessage = ""
                            showingError = false
                        },
                        primaryActionTitle: "OK",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1002)
                }

                if showingAccountExistsAlert {
                    CustomAlertView(
                        title: alertTitle,
                        description: alertMessage,
                        cancelAction: {
                            self.showingAccountExistsAlert = false
                        },
                        cancelActionTitle: "Cancel",
                        primaryAction: {
                            self.showingLinkSuccessAlert = false
                        },
                        primaryActionTitle: "Continue",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1003)
                }

                if showingLinkSuccessAlert {
                    CustomAlertView(
                        title: "Success!",
                        description: linkSuccessMessage,
                        primaryAction: {
                            self.showingLinkSuccessAlert = false
                        },
                        primaryActionTitle: "OK",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1003)
                }
            }
        }
        .fullScreenCover(isPresented: $showingPasswordlessAuth) {
            PasswordlessAuthView(showingSignIn: $showingSignIn)
        }
    }

    private var signInButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                handleAppleSignIn()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "applelogo")
                        .appFont(size: 20, weight: .medium)

                    Text("CONTINUE WITH APPLE")
                        .appBody()
                }
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .clipShape(Capsule())
            }
            .disabled(isLoading)
            .buttonStyle(PlainButtonStyle())

            Button {
                handleGoogleSignIn()
            } label: {
                HStack(spacing: 12) {
                    Image("google_logo")
                        .resizable()
                        .frame(width: 26, height: 26)

                    Text("CONTINUE WITH GOOGLE")
                        .appBody()
                }
                .foregroundColor(.black)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(1), lineWidth: 1.5)
                )
            }
            .disabled(isLoading)
            .buttonStyle(PlainButtonStyle())

            Button {
                showingPasswordlessAuth = true
            } label: {
                HStack(spacing: 12) {
                 Spacer()
                    Text("CONTINUE WITH EMAIL")
                        .appBody()
                    Spacer()

                }
                .foregroundColor(.black)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(1), lineWidth: 1.5)
                )
            }
            .disabled(isLoading)
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var footerSection: some View {
        VStack(spacing: 6) {
            Text("By continuing, you agree to our")
                .appCaption()
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)

            HStack(spacing: 4) {
                NavigationLink(destination: TermsOfServiceView()) {
                    Text("Terms of Service")
                        .appCaption()
                        .foregroundColor(.black)
                        .underline()
                }

                Text("&")
                    .appCaption()
                    .foregroundColor(.black.opacity(0.6))

                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("Privacy Policy")
                        .appCaption()
                        .foregroundColor(.black)
                        .underline()
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 4)
    }
    
    private func handleGoogleSignIn() {
        startLoading()

        Task {
            do {
                // Add queryItems to include prompt=select_account
                // This forces Google to show the account picker every time
                var components = URLComponents(string: "burner://auth")
                components?.queryItems = [
                    URLQueryItem(name: "prompt", value: "select_account")
                ]
                
                try await SupabaseManager.shared.client.auth.signInWithOAuth(
                    provider: .google,
                    redirectTo: components?.url,
                    queryParams: [("prompt", "select_account")]
                )
                
                await MainActor.run {
                    stopLoading()
                    completeSignIn()
                }
            } catch {
                await MainActor.run {
                    // Check if user cancelled the sign-in
                    let nsError = error as NSError
                    if nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && nsError.code == 1 {
                        // User cancelled - just stop loading, don't show error
                        stopLoading()
                        return
                    }
                    
                    // For other errors, show the error message
                    showErrorMessage("Google Sign-In failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let delegate = AppleSignInDelegate(
            currentNonce: nonce,
            onSuccess: { idToken in
                self.completeAppleSignIn(idToken: idToken)
            },
            onError: { error in
                self.showErrorMessage("Apple Sign-In failed: \(error)")
            },
            startLoading: {
                self.startLoading()
            },
            stopLoading: {
                self.stopLoading()
            }
        )
        
        let contextProvider = ApplePresentationContextProvider()
        
        self.appleSignInDelegate = delegate
        self.presentationContextProvider = contextProvider
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = contextProvider
        authorizationController.performRequests()
    }

    private func completeAppleSignIn(idToken: String) {
        Task {
            do {
                guard let nonce = currentNonce else {
                    throw NSError(domain: "SignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No nonce available"])
                }
                
                try await appState.authService.signInWithApple(idToken: idToken, nonce: nonce, fullName: nil)
                
                await MainActor.run {
                    stopLoading()
                    completeSignIn()
                }
            } catch {
                await MainActor.run {
                    showErrorMessage("Apple Sign-In failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    private func startLoading() {
        withAnimation {
            isLoading = true
            errorMessage = ""
            showingError = false
        }
    }
    
    private func stopLoading() {
        withAnimation {
            isLoading = false
        }
    }
    
    private func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            withAnimation {
                isLoading = false
                errorMessage = message
                showingError = true
            }

            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func completeSignIn() {
        DispatchQueue.main.async {
            withAnimation {
                isLoading = false
            }

            triggerSuccessFeedback()

            Task { @MainActor in
                if self.isOnboarding {
                    NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
                }
            }
            
            if !self.isOnboarding {
                self.showingSignIn = false
            }
        }
    }
    
    private func triggerSuccessFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return nil
        }
        
        return windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    }
}

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let currentNonce: String
    let onSuccess: (String) -> Void
    let onError: (String) -> Void
    let startLoading: () -> Void
    let stopLoading: () -> Void
    
    init(
        currentNonce: String,
        onSuccess: @escaping (String) -> Void,
        onError: @escaping (String) -> Void,
        startLoading: @escaping () -> Void,
        stopLoading: @escaping () -> Void
    ) {
        self.currentNonce = currentNonce
        self.onSuccess = onSuccess
        self.onError = onError
        self.startLoading = startLoading
        self.stopLoading = stopLoading
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        startLoading()
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onError("Failed to get Apple ID credential.")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            onError("Unable to fetch identity token")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            onError("Unable to serialize token string from data")
            return
        }
        
        onSuccess(idTokenString)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        if nsError.code == ASAuthorizationError.canceled.rawValue {
            stopLoading()
            return
        }
        onError(error.localizedDescription)
    }
}

class ApplePresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return UIWindow()
        }
        return windowScene.windows.first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}

struct SignInSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SignInSheetView(showingSignIn: .constant(true))
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Sign In Sheet")
    }
}
