import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import Combine

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
    @State private var pendingLinkCredential: AuthCredential?
    @State private var pendingLinkEmail: String?
    @State private var pendingNewProvider: String?
    @State private var pendingExistingProvider: String?
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var shouldLinkAfterSignIn = false
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
                            self.clearPendingLinkData()
                        },
                        cancelActionTitle: "Cancel",
                        primaryAction: {
                            self.signInWithExistingProvider()
                        },
                        primaryActionTitle: "Sign in with \(pendingExistingProvider ?? "Existing Account")",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1003)
                }


                if showingLinkSuccessAlert {
                    CustomAlertView(
                        title: "Accounts Linked!",
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
                    if errorCode == -5 {
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
                
                if let email = result.user.profile?.email {
                    self.checkAndHandleAccountLinking(
                        email: email,
                        newCredential: credential,
                        newProvider: "Google",
                        googleUser: result.user
                    )
                } else {
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
    }

    private func handleAppleSignIn() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let delegate = AppleSignInDelegate(
            currentNonce: nonce,
            onSuccess: { credential, email in
                if let email = email {
                    self.checkAndHandleAccountLinking(
                        email: email,
                        newCredential: credential,
                        newProvider: "Apple",
                        googleUser: nil
                    )
                } else {
                    self.authenticateWithFirebase(credential: credential) { authResult in
                        if let user = authResult?.user {
                            self.handleAppleSignInSuccess(user: user)
                        }
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

    private func checkAndHandleAccountLinking(
        email: String,
        newCredential: AuthCredential,
        newProvider: String,
        googleUser: GIDGoogleUser?
    ) {
        self.authenticateWithFirebase(credential: newCredential) { authResult in
            if let user = authResult?.user {
                self.createUserProfile(
                    for: user,
                    provider: newProvider.lowercased() + ".com",
                    googleUser: googleUser
                ) {
                    self.completeSignIn()
                }
            }
        }
    }

    private func friendlyProviderName(from method: String) -> String {
        if method.contains("google") { return "Google" }
        if method.contains("apple") { return "Apple" }
        if method.contains("password") { return "Email" }
        return "another provider"
    }

    private func showAccountExistsAlert(
        email: String,
        existingProvider: String,
        newProvider: String,
        newCredential: AuthCredential
    ) {
        self.pendingLinkCredential = newCredential
        self.pendingLinkEmail = email
        self.pendingNewProvider = newProvider
        self.pendingExistingProvider = existingProvider
        
        self.alertTitle = "Account Already Exists"
        self.alertMessage = "This email is already linked to a \(existingProvider) account.\n\nPlease sign in with \(existingProvider) first, then you can link your \(newProvider) account in Settings."
        
        self.showingAccountExistsAlert = true
    }

    private func signInWithExistingProvider() {
        guard let provider = pendingExistingProvider else { return }
        
        self.showingAccountExistsAlert = false
        self.shouldLinkAfterSignIn = true

        if provider == "Google" {
            handleGoogleSignInForLinking()
        } else if provider == "Apple" {
            handleAppleSignInForLinking()
        }
    }
    
    private func handleGoogleSignInForLinking() {
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
                    if errorCode == -5 {
                        self.stopLoading()
                        self.shouldLinkAfterSignIn = false
                        return
                    }
                    self.showErrorMessage("Google Sign-In failed: \(error.localizedDescription)")
                    self.shouldLinkAfterSignIn = false
                    return
                }

                guard let result = result,
                      let idToken = result.user.idToken?.tokenString else {
                    self.showErrorMessage("Failed to get sign-in credentials.")
                    self.shouldLinkAfterSignIn = false
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )

                self.authenticateWithFirebase(credential: credential) { authResult in
                    if let user = authResult?.user {
                        if self.shouldLinkAfterSignIn, let pendingCred = self.pendingLinkCredential {
                            self.linkCredentialToAccount(user: user, credential: pendingCred)
                        } else {
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
    }
    
    private func handleAppleSignInForLinking() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let delegate = AppleSignInDelegate(
            currentNonce: nonce,
            onSuccess: { credential, email in
                self.authenticateWithFirebase(credential: credential) { authResult in
                    if let user = authResult?.user {
                        if self.shouldLinkAfterSignIn, let pendingCred = self.pendingLinkCredential {
                            self.linkCredentialToAccount(user: user, credential: pendingCred)
                        } else {
                            self.handleAppleSignInSuccess(user: user)
                        }
                    }
                }
            },
            onError: { error in
                self.showErrorMessage("Apple Sign-In failed: \(error)")
                self.shouldLinkAfterSignIn = false
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
    
    private func linkCredentialToAccount(user: User, credential: AuthCredential) {
        user.link(with: credential) { authResult, error in
            DispatchQueue.main.async {
                self.stopLoading()
                self.shouldLinkAfterSignIn = false
                
                if let error = error {
                    let nsError = error as NSError
                    
                    if nsError.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                        self.handleCredentialAlreadyInUse(credential: credential, existingUser: user)
                    } else if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        self.showErrorMessage("This email is already in use with a different account.")
                    } else {
                        self.showErrorMessage("Failed to link accounts: \(error.localizedDescription)")
                    }
                    return
                }

                self.updateUserProfileWithLinkedProvider(user: user)
                
                self.linkSuccessMessage = "Your \(self.pendingNewProvider ?? "new") account has been successfully linked! You can now sign in with either method."
                self.showingLinkSuccessAlert = true
                self.clearPendingLinkData()
            }
        }
    }
    
    private func handleCredentialAlreadyInUse(credential: AuthCredential, existingUser: User) {
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showErrorMessage("Failed to merge accounts: \(error.localizedDescription)")
                    return
                }
                
                guard let newUser = authResult?.user, let email = self.pendingLinkEmail else {
                    self.showErrorMessage("Failed to merge accounts")
                    return
                }

                self.mergeAccountData(
                    fromUserId: existingUser.uid,
                    toUserId: newUser.uid,
                    email: email
                )
            }
        }
    }
    
    private func mergeAccountData(fromUserId: String, toUserId: String, email: String) {
        let db = Firestore.firestore()
        let oldUserRef = db.collection("users").document(fromUserId)
        let newUserRef = db.collection("users").document(toUserId)
        
        startLoading()
        
        oldUserRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                guard let oldData = snapshot?.data() else {
                    self.stopLoading()
                    self.completeSignIn()
                    return
                }

                var mergedData = oldData
                mergedData["lastLoginAt"] = FieldValue.serverTimestamp()
                mergedData["linkedProviders"] = FieldValue.arrayUnion([self.pendingNewProvider?.lowercased() ?? "unknown"])
                
                newUserRef.setData(mergedData, merge: true) { error in
                    if error != nil {
                        self.stopLoading()
                        self.showErrorMessage("Failed to merge account data")
                        return
                    }

                    oldUserRef.updateData([
                        "mergedInto": toUserId,
                        "mergedAt": FieldValue.serverTimestamp(),
                        "status": "merged"
                    ]) { _ in }
                    
                    self.migrateUserTickets(from: fromUserId, to: toUserId) {
                        self.stopLoading()
                        
                        self.linkSuccessMessage = "Your accounts have been successfully merged! All your tickets and data are now accessible."
                        self.showingLinkSuccessAlert = true
                        self.clearPendingLinkData()
                    }
                }
            }
        }
    }
    
    private func migrateUserTickets(from oldUserId: String, to newUserId: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        
        db.collection("tickets")
            .whereField("userId", isEqualTo: oldUserId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    completion()
                    return
                }

                let batch = db.batch()
                for doc in documents {
                    batch.updateData(["userId": newUserId], forDocument: doc.reference)
                }

                batch.commit { error in
                    completion()
                }
            }
    }
    
    private func updateUserProfileWithLinkedProvider(user: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.updateData([
            "linkedProviders": FieldValue.arrayUnion([pendingNewProvider?.lowercased() ?? "unknown"]),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]) { error in
        }
    }
    
    private func clearPendingLinkData() {
        pendingLinkCredential = nil
        pendingLinkEmail = nil
        pendingNewProvider = nil
        pendingExistingProvider = nil
        shouldLinkAfterSignIn = false
    }

    private func handleAppleSignInSuccess(user: User) {
        createUserProfile(
            for: user,
            provider: "apple.com"
        ) {
            self.completeSignIn()
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
            
            let documentExists = snapshot?.exists == true
            
            var userData: [String: Any] = [
                "lastLoginAt": FieldValue.serverTimestamp(),
                "provider": provider
            ]
            
            if !documentExists {
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
            }
            
            userRef.setData(userData, merge: true) { error in
                completion()
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
                let syncService = PreferencesSyncService()
                let localPrefs = LocalPreferences()

                let hasLocalPrefs = localPrefs.hasAnyPreferences
                let firebasePrefs = await syncService.loadPreferencesFromFirebase()
                
                if let firebasePrefs = firebasePrefs {
                    if firebasePrefs.hasAnyPreferences {
                        if hasLocalPrefs {
                            await syncService.mergePreferences(localPreferences: localPrefs)
                        } else {
                            firebasePrefs.saveToUserDefaults()
                        }
                    } else if hasLocalPrefs {
                        await syncService.syncLocalPreferencesToFirebase(localPreferences: localPrefs)
                    }
                } else if hasLocalPrefs {
                    await syncService.syncLocalPreferencesToFirebase(localPreferences: localPrefs)
                }

                if self.isOnboarding {
                    NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
                } else {
                    if !self.appState.onboardingManager.hasCompletedOnboarding {
                        self.appState.onboardingManager.completeOnboarding()
                    }
                }
            }
            
            if !self.isOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showingSignIn = false
                }
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
    let onSuccess: (AuthCredential, String?) -> Void
    let onError: (String) -> Void
    let startLoading: () -> Void
    let stopLoading: () -> Void
    
    init(
        currentNonce: String,
        onSuccess: @escaping (AuthCredential, String?) -> Void,
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
        
        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: currentNonce,
            fullName: appleIDCredential.fullName
        )
        
        let email = appleIDCredential.email
        onSuccess(credential, email)
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
