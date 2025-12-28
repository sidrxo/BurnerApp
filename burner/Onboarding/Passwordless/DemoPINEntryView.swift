import SwiftUI

struct DemoPINEntryView: View {
    @Binding var showingSignIn: Bool
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var pin: String = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @FocusState private var isPINFocused: Bool
    
    let demoEmail: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Black background to match PasswordlessAuthView
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        
                        TightHeaderText("DEMO", "ACCOUNT", alignment: .center)
                            .frame(maxWidth: .infinity)
                        
                        Text("Enter your 6-digit PIN")
                            .appBody()
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(demoEmail)
                            .appCaption()
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 60)
                    
                    // PIN Display - Reduced spacing to fit on screen
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            PINDigitView(
                                isFilled: index < pin.count,
                                isActive: index == pin.count && isPINFocused
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 32)
                    
                    // Hidden TextField for keyboard input
                    TextField("", text: $pin)
                        .keyboardType(.numberPad)
                        .focused($isPINFocused)
                        .opacity(0)
                        .frame(height: 0)
                        .onChange(of: pin) { oldValue, newValue in
                            // Only allow digits
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                pin = filtered
                                return
                            }
                            
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                pin = String(newValue.prefix(6))
                            }
                            
                            // Auto-submit when 6 digits entered
                            if pin.count == 6 {
                                handlePINSubmit()
                            }
                        }
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Instructions
                    Text("Tap to enter PIN")
                        .appCaption()
                        .foregroundColor(.white.opacity(0.5))
                        .onTapGesture {
                            isPINFocused = true
                        }
                    
                    Spacer()
                    
                    // Bottom cancel button
                    VStack(spacing: 0) {
                        BurnerButton("CANCEL", style: .secondary, maxWidth: .infinity) {
                            dismiss()
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .background(Color.black)
                }
                .onAppear {
                    // Auto-focus on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPINFocused = true
                    }
                }
                
                // Top-right close button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .appSecondary()
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                        }
                        .padding(.top, 16)
                        .padding(.trailing, 24)
                    }
                    
                    Spacer()
                }
                
                // Loading Overlay
                if isLoading {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea(.all)
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                // Error Alert
                if showingError {
                    CustomAlertView(
                        title: "Invalid PIN",
                        description: errorMessage,
                        primaryAction: {
                            errorMessage = ""
                            showingError = false
                            pin = ""
                            isPINFocused = true
                        },
                        primaryActionTitle: "Try Again",
                        customContent: EmptyView()
                    )
                    .transition(.opacity)
                    .zIndex(1002)
                }
            }
        }
    }
    
    private func handlePINSubmit() {
        isPINFocused = false
        
        // Debug: Print what we're comparing
        print("DEBUG: Entered PIN: '\(pin)'")
        print("DEBUG: Validating with authService.validateDemoPIN()")
        
        // Validate PIN
        if appState.authService.validateDemoPIN(pin) {
            print("DEBUG: PIN validation PASSED")
            // Correct PIN - sign in
            signInWithDemoAccount()
        } else {
            print("DEBUG: PIN validation FAILED")
            // Incorrect PIN - show detailed error
            showError("The PIN '\(pin)' is incorrect. Please check your AuthenticationService.swift file for the correct PIN.")
        }
    }
    
    private func signInWithDemoAccount() {
        isLoading = true
        
        Task {
            do {
                print("DEBUG: Attempting to sign in with demo account...")
                try await appState.authService.signInWithDemoAccount()
                
                await MainActor.run {
                    isLoading = false
                    print("DEBUG: Demo account sign-in SUCCESS")
                    
                    // Success feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // FIX: Set binding first, then dismiss
                    // This ensures both navigation changes happen in the same frame
                    showingSignIn = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("DEBUG: Demo account sign-in FAILED: \(error.localizedDescription)")
                    showError("Sign in failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        withAnimation {
            errorMessage = message
            showingError = true
        }
        
        // Haptic feedback for error
        let impactFeedback = UINotificationFeedbackGenerator()
        impactFeedback.notificationOccurred(.error)
    }
}

struct PINDigitView: View {
    let isFilled: Bool
    let isActive: Bool
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(width: 45, height: 56)
            
            // Border
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.white : Color.white.opacity(0.3), lineWidth: isActive ? 2 : 1)
                .frame(width: 45, height: 56)
            
            // Filled dot
            if isFilled {
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isFilled)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

struct DemoPINEntryView_Previews: PreviewProvider {
    static var previews: some View {
        DemoPINEntryView(
            showingSignIn: .constant(true),
            demoEmail: "demo@example.com"
        )
    }
}
