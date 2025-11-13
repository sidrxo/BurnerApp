//
//  PasswordlessAuthView.swift
//  burner
//
//  Created by Sid Rao on 03/11/2025.
//


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
                    // Content - Vertically centered
                    GeometryReader { geometry in
                        ScrollView {
                            VStack(spacing: 32) {
                                Spacer()
                                    .frame(minHeight: 0)

                                // Header
                                VStack(spacing: 12) {
                                    
                                    Text(emailSent ? "Check your email" : "Enter your email")
                                        .appSectionHeader()
                                        .foregroundColor(.white)

                                    Text(emailSent ? "We sent a sign-in link to \(email)" : "We'll send you a link to sign in")
                                        .appBody()
                                        .foregroundColor(.white.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                }
                                .padding(.top, 20)
                            
                            if !emailSent {
                                // Email input form
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                    
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
                                .padding(.horizontal, 24)
                            } else {
                                // Email sent confirmation
                                VStack(spacing: 24) {
                                    VStack(spacing: 16) {
                                        // Instructions
                                        VStack(alignment: .leading, spacing: 12) {
                                            instructionRow(number: "1", text: "Check your email inbox")
                                            instructionRow(number: "2", text: "Click the sign-in link")
                                            instructionRow(number: "3", text: "You'll be signed in automatically")
                                        }
                                        .padding(16)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    
                                    // Resend section
                                    VStack(spacing: 12) {
                                        Text("Didn't receive the email?")
                                            .appCaption()
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        if canResend {
                                            Button {
                                                handleSendLink()
                                            } label: {
                                                Text("Resend Link")
                                                    .appBody()
                                                    .foregroundColor(.blue)
                                            }
                                        } else {
                                            Text("Resend in \(resendCountdown)s")
                                                .appCaption()
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
                                    }
                                }
                                .padding(.horizontal, 24)
                            }

                                Spacer()
                                    .frame(minHeight: 0)
                            }
                            .frame(minHeight: geometry.size.height)
                        }
                    }

                    // Bottom button
                    if !emailSent {
                        VStack(spacing: 0) {
                                               
                            Button {
                                handleSendLink()
                            } label: {
                                Text("SEND LINK")
                                    .appBody()
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .disabled(!isButtonEnabled || isLoading)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                        }
                        .background(Color.black)
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
                            .frame(width: 32, height: 32)
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
            // Dismiss this view when user successfully signs in
            dismiss()
            // Also dismiss the parent sign-in sheet
            showingSignIn = false
        }
    }
    
    // MARK: - Instruction Row
    
    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .appSecondary()
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
            
            Text(text)
                .appBody()
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isButtonEnabled: Bool {
        return isValidEmail(email)
    }
    
    // MARK: - Send Sign-In Link
    
    private func handleSendLink() {
        guard isValidEmail(email) else {
            showErrorMessage("Please enter a valid email address")
            return
        }
        
        startLoading()
        
        // Store email for verification after link is clicked
        UserDefaults.standard.set(email, forKey: "pendingEmailForSignIn")
        
        // Configure action code settings
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://manageburner.online/signin") // Replace with your dynamic link
        actionCodeSettings.handleCodeInApp = true
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier ?? "")
        // If you want to support Android too:
        // actionCodeSettings.setAndroidPackageName("com.yourapp.android", installIfNotAvailable: true, minimumVersion: "1")
        
        Auth.auth().sendSignInLink(toEmail: email, actionCodeSettings: actionCodeSettings) { error in
            DispatchQueue.main.async {
                self.stopLoading()
                
                if let error = error {
                    self.showErrorMessage("Failed to send link: \(error.localizedDescription)")
                    return
                }
                
                // Success - show confirmation
                withAnimation {
                    self.emailSent = true
                }
                
                // Start countdown timer
                self.startCountdown()
                
                // Provide haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
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

// MARK: - Preview
struct PasswordlessAuthView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordlessAuthView(showingSignIn: .constant(true))
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("Passwordless Auth View")
    }
}
