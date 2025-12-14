import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PasswordlessAuthView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var showingSignIn: Bool
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var emailSent = false
    @State private var canResend = false
    @State private var resendCountdown = 60
    @State private var countdownTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black background
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Content - Vertically centered using GeometryReader and ScrollView
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 40) {
                                Spacer()
                                    .frame(minHeight: 0)

                                // Header
                                VStack(spacing: 12) {
                                    
                                    if emailSent {
                                        TightHeaderText("CHECK YOUR", "EMAIL", alignment: .center)
                                            .frame(maxWidth: .infinity)
                                        
                                        Text("We sent a sign-in link to \(email)")
                                            .appBody()
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    } else {
                                        TightHeaderText("WHAT'S YOUR", "EMAIL?", alignment: .center)
                                            .frame(maxWidth: .infinity)
                                        
                                        Text("We'll send a magic link to sign you in or create an account.")
                                            .appBody()
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 24)
                                    }
                                }
                                .frame(height: 160) // Ensure stable height for visual consistency
                                .padding(.top, 20)
                            
                            if !emailSent {
                                // Email input form
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // The original had a placeholder, which is useful in a TextField
                                        TextField("Email Address", text: $email)
                                            .appBody()
                                            .foregroundColor(.white)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                            .keyboardType(.emailAddress)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12)) // Changed to 12 for consistency
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    }
                                }
                                .padding(.horizontal, 24)
                            } else {
                                // Email sent confirmation
                                VStack(spacing: 28) {
                                    VStack(spacing: 16) {
                                        // Instructions
                                        VStack(alignment: .leading, spacing: 14) {
                                            instructionRow(number: "1", text: "Check your email inbox")
                                            instructionRow(number: "2", text: "Click the sign-in link")
                                            instructionRow(number: "3", text: "You'll be signed in automatically")
                                        }
                                        .padding(16)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    
                                    // Resend section
                                    VStack(spacing: 16) {
                                        Text("Didn't receive the email?")
                                            .appCaption()
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        if canResend {
                                            BurnerButton("RESEND LINK", style: .secondary, maxWidth: 160) {
                                                handleSendLink()
                                            }
                                        } else {
                                            Text("Resend in \(resendCountdown)s")
                                                .appBody() // Changed to appBody for prominence
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                    
                                    // Change email
                                    Button {
                                        withAnimation {
                                            emailSent = false
                                            stopCountdown()
                                        }
                                    } label: {
                                        Text("Use a different email")
                                            .appCaption()
                                            .foregroundColor(.white.opacity(0.5))
                                            .underline()
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                                Spacer()
                                    .frame(minHeight: 0)
                            }
                            .frame(minHeight: geometry.size.height - 80) // Adjusted height
                        }
                    }

                    // Bottom button (BurnerButton)
                    if !emailSent {
                        VStack(spacing: 0) {
                            BurnerButton("SEND LINK", style: .primary, maxWidth: .infinity) {
                                handleSendLink()
                            }
                            .disabled(!isButtonEnabled || isLoading)
                            .opacity(isButtonEnabled && !isLoading ? 1.0 : 0.6)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .background(Color.black)
                    }
                }
                
                // Loading overlay
                if isLoading {
                    Color.black.opacity(0.7) // Increased opacity for better contrast
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .appBody()
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 38, height: 38) // Increased size for better tap target
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onDisappear {
            stopCountdown()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            dismiss()
            showingSignIn = false
        }
    }
    
    // MARK: - Instruction Row
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) { // Changed to .top alignment
            Text(number)
                .appSecondary()
                .foregroundColor(.black) // Black text on white/dimmed background
                .frame(width: 28, height: 28) // Increased size for consistency
                .background(Color.white) // Solid white background for number pill
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Text(text)
                .appBody()
                .foregroundColor(.white)
                .lineSpacing(3) // Added line spacing for readability
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isButtonEnabled: Bool {
        return isValidEmail(email)
    }
    
    // MARK: - Send Sign-In Link (Remains the same functional logic)
    
    private func handleSendLink() {
        guard isValidEmail(email) else {
            showErrorMessage("Please enter a valid email address")
            return
        }
        
        startLoading()
        
        UserDefaults.standard.set(email, forKey: "pendingEmailForSignIn")
        
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://manageburner.online/signin")
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier ?? "")
        
        Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { error in
            DispatchQueue.main.async {
                self.stopLoading()
                
                if let error = error {
                    self.showErrorMessage("Failed to send link: \(error.localizedDescription)")
                    return
                }
                
                withAnimation {
                    self.emailSent = true
                }
                
                self.startCountdown()
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    // MARK: - Countdown Timer (Remains the same functional logic)
    
    private func startCountdown() {
        canResend = false
        resendCountdown = 60
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    
    private func stopCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        canResend = false
        resendCountdown = 60
    }
    
    // MARK: - Helper Functions (Remains the same functional logic)
    
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
}
