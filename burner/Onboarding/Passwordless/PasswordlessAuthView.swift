import SwiftUI
import Supabase

struct PasswordlessAuthView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState // <--- Added AppState
    @Binding var showingSignIn: Bool
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var emailSent = false
    @State private var canResend = false
    @State private var resendCountdown = 60
    @State private var countdownTimer: Timer?
    @FocusState private var isEmailFieldFocused: Bool
    @State private var hasAttemptedSubmit = false
    @State private var showingPINEntry = false  // NEW: For demo PIN flow
    
    private let supabase = SupabaseManager.shared.client
    
    // Computed property for validation
    private var showValidationError: Bool {
        hasAttemptedSubmit && !email.isEmpty && !isValidEmail(email)
    }
    
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
                                        TextField("Email Address", text: $email)
                                            .appBody()
                                            .foregroundColor(.white)
                                            .autocorrectionDisabled()
                                            .textInputAutocapitalization(.never)
                                            .keyboardType(.emailAddress)
                                            .textContentType(.emailAddress)
                                            .submitLabel(.continue)
                                            .focused($isEmailFieldFocused)
                                            .onSubmit {
                                                hasAttemptedSubmit = true
                                                if isButtonEnabled {
                                                    handleSendLink()
                                                }
                                            }
                                            .onChange(of: email) { _, _ in
                                                // Clear validation error when user types
                                                if hasAttemptedSubmit && isValidEmail(email) {
                                                    hasAttemptedSubmit = false
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(showValidationError ? Color.red.opacity(0.6) : Color.white.opacity(0.2), lineWidth: showValidationError ? 2 : 1)
                                            )
                                        
                                        // Validation error message
                                        if showValidationError {
                                            HStack(spacing: 6) {
                                                Image(systemName: "exclamationmark.circle.fill")
                                                    .font(.system(size: 12))
                                                Text("Please enter a valid email address")
                                                    .appCaption()
                                            }
                                            .foregroundColor(.red.opacity(0.9))
                                            .padding(.leading, 4)
                                            .transition(.opacity.combined(with: .move(edge: .top)))
                                        }
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
                                                .appBody()
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
                            .frame(minHeight: geometry.size.height - 80)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isEmailFieldFocused = false
                            }
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
                    Color.black.opacity(0.7)
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
                            .frame(width: 38, height: 38)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .onDisappear {
            stopCountdown()
        }
        // Listener 1: Notification (Backup)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            dismiss()
            showingSignIn = false
        }
        // Listener 2: State Change (Robust Fix)
        // If the AppState detects a user, close this view immediately.
        .onChange(of: appState.authService.currentUser) { _, newUser in
            if newUser != nil {
                dismiss()
                showingSignIn = false
            }
        }
        // NEW: Show PIN entry for demo email
        .fullScreenCover(isPresented: $showingPINEntry) {
            DemoPINEntryView(
                showingSignIn: $showingSignIn,
                demoEmail: email
            )
            .environmentObject(appState)
        }
    }
    
    // MARK: - Instruction Row
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .appSecondary()
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            
            Text(text)
                .appBody()
                .foregroundColor(.white)
                .lineSpacing(3)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isButtonEnabled: Bool {
        return isValidEmail(email)
    }
    
    // MARK: - Send Sign-In Link
    
    private func handleSendLink() {
        hasAttemptedSubmit = true
        
        guard isValidEmail(email) else {
            // Haptic feedback for validation error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        // NEW: Check if this is the demo email
        if appState.authService.isDemoEmail(email) {
            // Dismiss keyboard
            isEmailFieldFocused = false
            
            // Show PIN entry instead of sending magic link
            showingPINEntry = true
            return
        }
        
        // Regular magic link flow for non-demo emails
        // Dismiss keyboard immediately to prevent lag during transition
        isEmailFieldFocused = false
        
        startLoading()
        
        // Store email for later verification
        UserDefaults.standard.set(email, forKey: "pendingEmailForSignIn")
        
        Task {
            do {
                // Supabase magic link with redirect URL
                try await supabase.auth.signInWithOTP(
                    email: email,
                    redirectTo: URL(string: "burner://signin")
                )
                
                await MainActor.run {
                    self.stopLoading()
                    
                    withAnimation {
                        self.emailSent = true
                    }
                    
                    self.startCountdown()
                    
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            } catch {
                await MainActor.run {
                    self.showErrorMessage("Failed to send link: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Countdown Timer
    
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
    
    // MARK: - Helper Functions
    
    private func isValidEmail(_ email: String) -> Bool {
        // Basic format check
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return false
        }
        
        // Additional checks for common mistakes
        let components = email.components(separatedBy: "@")
        guard components.count == 2,
              !components[0].isEmpty,
              !components[1].isEmpty else {
            return false
        }
        
        let domain = components[1]
        
        // Check for common TLD typos
        let commonTypos = ["cov", "con", "comm", "cim", "bet", "met", "ent"]
        let tld = domain.components(separatedBy: ".").last?.lowercased() ?? ""
        
        if commonTypos.contains(tld) {
            return false
        }
        
        // Check domain has at least one dot and reasonable structure
        guard domain.contains("."),
              !domain.hasPrefix("."),
              !domain.hasSuffix("."),
              !domain.contains("..") else {
            return false
        }
        
        return true
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
