import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct EmailAuthView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showingSignIn: Bool
    
    @State private var currentStep: AuthStep = .email
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var isSignUpMode = false
    
    enum AuthStep {
        case email
        case password
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Content
                    ScrollView {
                        VStack(spacing: 32) {
                            // Header
                            VStack(spacing: 12) {
                                Text(headerTitle)
                                    .appPageHeader()
                                    .foregroundColor(.white)
                                
                                if let subtitle = headerSubtitle {
                                    Text(subtitle)
                                        .appBody()
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 60)
                            
                            // Form content
                            VStack(spacing: 20) {
                                switch currentStep {
                                case .email:
                                    emailStepView
                                case .password:
                                    passwordStepView
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    // Bottom button
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        Button {
                            handleContinue()
                        } label: {
                            Text(buttonTitle)
                                .appBody()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isButtonEnabled ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!isButtonEnabled || isLoading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .background(Color.black)
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea(.all)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                if showingError {
                    CustomAlertView(
                        title: "Error",
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep != .email {
                        Button {
                            withAnimation {
                                goBack()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .appBody()
                                Text("Back")
                                    .appBody()
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .appBody()
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Step Views
    
    private var emailStepView: some View {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var passwordStepView: some View {
        VStack(spacing: 20) {
            // Email display (non-editable)
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .appCaption()
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Text(email)
                        .appBody()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            currentStep = .email
                            password = ""
                            confirmPassword = ""
                            isSignUpMode = false
                        }
                    } label: {
                        Text("Change")
                            .appCaption()
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                if isSignUpMode {
                    Text("Must be at least 6 characters")
                        .appCaption()
                        .foregroundColor(.white.opacity(0.5))
                }
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            
            // Toggle between sign in and sign up
            if !isSignUpMode {
                // Forgot password link for sign in
                HStack {
                    Spacer()
                    Button {
                        handleForgotPassword()
                    } label: {
                        Text("Forgot password?")
                            .appCaption()
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Toggle text
            Button {
                withAnimation {
                    isSignUpMode.toggle()
                    password = ""
                    confirmPassword = ""
                }
            } label: {
                Text(isSignUpMode ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                    .appCaption()
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var headerTitle: String {
        switch currentStep {
        case .email:
            return "Enter your email"
        case .password:
            return isSignUpMode ? "Create account" : "Welcome back"
        }
    }
    
    private var headerSubtitle: String? {
        switch currentStep {
        case .email:
            return "We'll help you sign in or create an account"
        case .password:
            return isSignUpMode ? "Create a new account to get started" : "Sign in to continue"
        }
    }
    
    private var buttonTitle: String {
        switch currentStep {
        case .email:
            return "Continue"
        case .password:
            return isSignUpMode ? "Create Account" : "Sign In"
        }
    }
    
    private var isButtonEnabled: Bool {
        switch currentStep {
        case .email:
            return isValidEmail(email)
        case .password:
            if isSignUpMode {
                return password.count >= 6 && password == confirmPassword
            } else {
                return !password.isEmpty
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleContinue() {
        switch currentStep {
        case .email:
            // Move to password entry
            withAnimation {
                currentStep = .password
            }
        case .password:
            if isSignUpMode {
                handleSignUp()
            } else {
                handleSignIn()
            }
        }
    }
    
    private func goBack() {
        switch currentStep {
        case .email:
            break
        case .password:
            currentStep = .email
            password = ""
            confirmPassword = ""
            isSignUpMode = false
        }
    }
    
    // MARK: - Sign In
    
    private func handleSignIn() {
        guard !password.isEmpty else {
            showErrorMessage("Please enter your password")
            return
        }
        
        startLoading()
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.stopLoading()
                    
                    // Check if it's a user not found error
                    let nsError = error as NSError
                    if nsError.code == AuthErrorCode.userNotFound.rawValue {
                        // Suggest signing up instead
                        withAnimation {
                            self.isSignUpMode = true
                        }
                        self.showErrorMessage("No account found with this email. Please sign up.")
                    } else {
                        self.showErrorMessage("Sign in failed: \(error.localizedDescription)")
                    }
                    return
                }
                
                if let user = authResult?.user {
                    self.createUserProfile(for: user, provider: "password") {
                        self.completeSignIn()
                    }
                }
            }
        }
    }
    
    // MARK: - Sign Up
    
    private func handleSignUp() {
        guard password.count >= 6 else {
            showErrorMessage("Password must be at least 6 characters")
            return
        }
        
        guard password == confirmPassword else {
            showErrorMessage("Passwords do not match")
            return
        }
        
        startLoading()
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.stopLoading()
                    
                    // Check if it's an email already in use error
                    let nsError = error as NSError
                    if nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                        // Suggest signing in instead
                        withAnimation {
                            self.isSignUpMode = false
                            self.confirmPassword = ""
                        }
                        self.showErrorMessage("An account already exists with this email. Please sign in.")
                    } else {
                        self.showErrorMessage("Sign up failed: \(error.localizedDescription)")
                    }
                    return
                }
                
                if let user = authResult?.user {
                    self.createUserProfile(for: user, provider: "password") {
                        self.completeSignIn()
                    }
                }
            }
        }
    }
    
    // MARK: - Forgot Password
    
    private func handleForgotPassword() {
        startLoading()
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                self.stopLoading()
                
                if let error = error {
                    self.showErrorMessage("Error sending reset email: \(error.localizedDescription)")
                } else {
                    self.showErrorMessage("Password reset email sent. Please check your inbox.")
                }
            }
        }
    }
    
    // MARK: - User Profile Management
    
    private func createUserProfile(
        for user: User,
        provider: String,
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
                let displayName = user.email?.components(separatedBy: "@").first ?? "User"
                
                userData.merge([
                    "email": user.email ?? "",
                    "displayName": displayName,
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
    
    // MARK: - Helper Functions
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
                self.isLoading = false
                self.errorMessage = message
                self.showingError = true
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func completeSignIn() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = false
            }
            
            self.triggerSuccessFeedback()
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedIn"), object: nil)
            
            self.showingSignIn = false
            self.dismiss()
        }
    }
    
    private func triggerSuccessFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Preview
struct EmailAuthView_Previews: PreviewProvider {
    static var previews: some View {
        EmailAuthView(showingSignIn: .constant(true))
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Email Auth View")
    }
}
