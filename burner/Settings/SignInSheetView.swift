import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

struct SignInSheetView: View {
    @Binding var showingSignIn: Bool
    var onSkip: (() -> Void)? = nil

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var currentNonce: String?
    @State private var appleSignInDelegate: AppleSignInDelegate?
    @State private var presentationContextProvider: ApplePresentationContextProvider?

    // Email sign-in states
    @State private var showingEmailSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUpMode = false

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea(.all)
            
            // Background Image - moved up
            Image("Background3")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(.all)
                .offset(y: -200)
            
            // Black gradient overlay - higher coverage
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)

            VStack(spacing: 0) {
                // Close button - using CloseButton component
                HStack {
                    Spacer()
                    CloseButton {
                        if let onSkip = onSkip {
                            onSkip()
                        } else {
                            showingSignIn = false
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.33 - 150)
                
                // Transparent logo image
                Image("transparent")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .padding(.bottom, 60)

                
                Spacer()

                // Bottom section with buttons and terms
                if showingEmailSignIn {
                    emailSignInForm
                        .padding(.bottom, 50)
                        .frame(maxWidth: 400)
                } else {
                    VStack(spacing: 8) {
                        signInButtonsSection
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                    .frame(maxWidth: 400)
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK") {
                errorMessage = ""
                showingError = false
            }
        } message: {
            Text(errorMessage)
        }
    }

    private var signInButtonsSection: some View {
        VStack(spacing: 16) {
            // Google Sign In Button
            Button {
                handleGoogleSignIn()
            } label: {
                HStack(spacing: 12) {
                    Image("google_logo")
                        .resizable()
                        .frame(width: 22, height: 22)
                    
                    Text("Continue with Google")
                        .appBody()
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isLoading)

            // Apple Sign In Button - styled like Google button
            Button {
                handleAppleSignIn()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "applelogo")
                        .font(.appIcon)
                        .foregroundColor(.black)
                    
                    Text("Continue with Apple")
                        .appBody()
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isLoading)

            // Email Sign In Button
            Button {
                withAnimation {
                    showingEmailSignIn = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .font(.appIcon)
                        .foregroundColor(.white)

                    Text("Continue with Email")
                        .appBody()
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isLoading)
        }
    }

    private var footerSection: some View {
        Text("By continuing, you agree to our Terms of Service & Privacy Policy")
            .appCaption()
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 40)
            .padding(.top, 8)
    }

    // MARK: - Email Sign In Form
    private var emailSignInForm: some View {
        VStack(spacing: 20) {
            // Title
            Text(isSignUpMode ? "Create Account" : "Sign In")
                .appSectionHeader()
                .foregroundColor(.white)

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .appCaption()
                    .foregroundColor(.white.opacity(0.7))

                TextField("", text: $email)
                    .appBody()
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .appCaption()
                    .foregroundColor(.white.opacity(0.7))

                SecureField("", text: $password)
                    .appBody()
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Confirm password field (only for sign up)
            if isSignUpMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .appCaption()
                        .foregroundColor(.white.opacity(0.7))

                    SecureField("", text: $confirmPassword)
                        .appBody()
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Sign in/up button
            Button {
                handleEmailSignIn()
            } label: {
                Text(isSignUpMode ? "Create Account" : "Sign In")
                    .appBody()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUpMode && confirmPassword.isEmpty))

            // Toggle between sign in and sign up
            Button {
                withAnimation {
                    isSignUpMode.toggle()
                    confirmPassword = ""
                }
            } label: {
                Text(isSignUpMode ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .appCaption()
                    .foregroundColor(.white.opacity(0.7))
            }

            // Back button
            Button {
                withAnimation {
                    showingEmailSignIn = false
                    email = ""
                    password = ""
                    confirmPassword = ""
                    isSignUpMode = false
                }
            } label: {
                Text("Back")
                    .appBody()
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Google Sign In Handler
    private func handleGoogleSignIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            showErrorMessage("Firebase configuration error.")
            return
        }

        startLoading()
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let rootVC = getRootViewController() else {
            showErrorMessage("Could not access the app window.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    let errorCode = (error as NSError).code
                    if errorCode == -5 { // User cancelled
                        self.stopLoading()
                        return
                    }
                    self.showErrorMessage("Google Sign-In failed: \(error.localizedDescription)")
                    return
                }

                guard let result = result,
                      let idToken = result.user.idToken?.tokenString else {
                    self.showErrorMessage("Failed to get sign-in credentials.")
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )

                self.authenticateWithFirebase(credential: credential) { authResult in
                    if let user = authResult?.user {
                        self.createUserProfile(
                            for: user,
                            provider: "google.com",
                            googleUser: result.user
                        ) {
                            self.completeSignIn()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Apple Sign In Handler
    private func handleAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let delegate = AppleSignInDelegate(
            currentNonce: nonce,
            onSuccess: { credential in
                self.authenticateWithFirebase(credential: credential) { authResult in
                    if let user = authResult?.user {
                        self.handleAppleSignInSuccess(user: user)
                    }
                }
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

    // MARK: - Apple Sign In Success Handler
    private func handleAppleSignInSuccess(user: User) {
        createUserProfile(
            for: user,
            provider: "apple.com"
        ) {
            self.completeSignIn()
        }
    }

    // MARK: - Email Sign In Handler
    private func handleEmailSignIn() {
        // Validate email and password
        guard !email.isEmpty, !password.isEmpty else {
            showErrorMessage("Please enter both email and password")
            return
        }

        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            showErrorMessage("Please enter a valid email address")
            return
        }

        // Validate password length
        guard password.count >= 6 else {
            showErrorMessage("Password must be at least 6 characters")
            return
        }

        // If sign up mode, check passwords match
        if isSignUpMode {
            guard password == confirmPassword else {
                showErrorMessage("Passwords do not match")
                return
            }
        }

        startLoading()

        if isSignUpMode {
            // Sign up
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorMessage("Sign up failed: \(error.localizedDescription)")
                        return
                    }

                    if let user = authResult?.user {
                        self.createUserProfile(
                            for: user,
                            provider: "password"
                        ) {
                            self.completeSignIn()
                        }
                    }
                }
            }
        } else {
            // Sign in
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.showErrorMessage("Sign in failed: \(error.localizedDescription)")
                        return
                    }

                    if let user = authResult?.user {
                        self.createUserProfile(
                            for: user,
                            provider: "password"
                        ) {
                            self.completeSignIn()
                        }
                    }
                }
            }
        }
    }

    private func authenticateWithFirebase(credential: AuthCredential, completion: @escaping (AuthDataResult?) -> Void) {
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showErrorMessage("Authentication failed: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    completion(authResult)
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    private func createUserProfile(
        for user: User,
        provider: String,
        googleUser: GIDGoogleUser? = nil,
        completion: @escaping () -> Void
    ) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { snapshot, error in
            if error != nil {
                completion()
                return
            }
            
            let isNewUser = snapshot?.exists != true
            
            var userData: [String: Any] = [
                "lastLoginAt": FieldValue.serverTimestamp(),
                "provider": provider
            ]
            
            if isNewUser {
                let userInfo = self.extractUserInfo(
                    user: user,
                    provider: provider,
                    googleUser: googleUser
                )
                
                userData.merge([
                    "email": userInfo.email,
                    "displayName": userInfo.displayName,
                    "role": "user",
                    "createdAt": FieldValue.serverTimestamp(),
                    "venuePermissions": []
                ]) { _, new in new }
                
                userRef.setData(userData) { error in
                    completion()
                }
            } else {
                userRef.updateData(userData) { error in
                    completion()
                }
            }
        }
    }

    private func extractUserInfo(
        user: User,
        provider: String,
        googleUser: GIDGoogleUser? = nil
    ) -> (email: String, displayName: String) {
        var email = ""
        var displayName = ""

        if provider == "google.com" {
            email = googleUser?.profile?.email ?? user.email ?? ""
            displayName = googleUser?.profile?.name ?? user.displayName ?? ""
        } else if provider == "apple.com" {
            email = user.email ?? ""
            displayName = user.displayName ?? ""
        } else if provider == "password" {
            email = user.email ?? ""
            displayName = user.displayName ?? user.email?.components(separatedBy: "@").first ?? ""
        }

        return (email, displayName)
    }
    
    // MARK: - Apple Sign In Helpers
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
    
    // MARK: - Helper Functions
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
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            showingSignIn = false
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

// MARK: - Apple Sign In Delegate
class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    let currentNonce: String
    let onSuccess: (AuthCredential) -> Void
    let onError: (String) -> Void
    let startLoading: () -> Void
    let stopLoading: () -> Void
    
    init(currentNonce: String, onSuccess: @escaping (AuthCredential) -> Void, onError: @escaping (String) -> Void, startLoading: @escaping () -> Void, stopLoading: @escaping () -> Void) {
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
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: currentNonce,
            fullName: appleIDCredential.fullName
        )
        
        onSuccess(credential)
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

// MARK: - Apple Presentation Context Provider
class ApplePresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return UIWindow()
        }
        return windowScene.windows.first(where: { $0.isKeyWindow }) ?? UIWindow()
    }
}

// MARK: - Preview
struct SignInSheetView_Previews: PreviewProvider {
    static var previews: some View {
        SignInSheetView(showingSignIn: .constant(true))
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Sign In Sheet")
    }
}
