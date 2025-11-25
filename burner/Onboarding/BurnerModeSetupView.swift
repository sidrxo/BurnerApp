import SwiftUI
import FamilyControls
import ManagedSettings

struct BurnerModeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var authorizationGranted = false
    @State private var showingAppPicker = false
    @ObservedObject var burnerManager: BurnerModeManager
    var onSkip: (() -> Void)? = nil
    
    private let totalSteps = 3
    
    // Track completion state of current step
    private var isCurrentStepCompleted: Bool {
        switch currentStep {
        case 0: return true  // Welcome is always "complete" when viewing
        case 1: return authorizationGranted
        case 2: return burnerManager.isSetupValid
        default: return false
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button using CloseButton component
                HStack {
                    Spacer()
                    CloseButton {
                        if let onSkip = onSkip {
                            onSkip()
                        } else {
                            dismiss()
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                
                Spacer()
                
                // Main content container - centered vertically
                VStack(spacing: 40) {
                    // Fixed PNG circle at the top with radial wipe
                    RadialWipeCircleView(
                        currentStep: currentStep,
                        totalSteps: totalSteps,
                        isStepCompleted: isCurrentStepCompleted
                    )
                    
                    // Sliding content area
                    TabView(selection: $currentStep) {
                        // Step 1: Welcome
                        WelcomeSlideContent()
                            .tag(0)
                        
                        // Step 2: Grant Permission
                        PermissionSlideContent(
                            authorizationGranted: $authorizationGranted,
                            onGrantPermission: requestAuthorization
                        )
                        .tag(1)
                        
                        // Step 3: Select Categories
                        CategorySelectionSlideContent(
                            burnerManager: burnerManager,
                            showingAppPicker: $showingAppPicker
                        )
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 200)
                }
                .padding(.vertical, 40)
                
                Spacer()
                
                VStack(spacing: 12) {
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps, id: \.self) { index in
                            Circle()
                                .fill(currentStep == index ? Color.white : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    
                    // Navigation buttons - fixed at bottom
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button(action: {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }) {
                                Text("BACK")
                                    .font(.appFont(size: 17))
                                    .foregroundColor(.white)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Button(action: {
                            handleNextButton()
                        }) {
                            Text(getNextButtonText().uppercased())
                                .font(.appFont(size: 17))
                                .foregroundColor(canProceed() ? .black : .gray)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(canProceed() ? Color.white : Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canProceed())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: $burnerManager.selectedApps
        )
    }
    
    private func getNextButtonText() -> String {
        switch currentStep {
        case 0: return "Get Started"
        case 1: return authorizationGranted ? "Continue" : "Grant Access"
        case 2: return burnerManager.isSetupValid ? "Complete" : "Continue"
        default: return "Next"
        }
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 0: return true
        case 1: return true
        case 2: return burnerManager.isSetupValid
        default: return false
        }
    }
    
    private func handleNextButton() {
        if currentStep == 1 && !authorizationGranted {
            requestAuthorization()
        } else if currentStep == 1 && authorizationGranted {
            withAnimation {
                currentStep += 1
            }
        } else if currentStep == 2 && !burnerManager.isSetupValid {
            showingAppPicker = true
        } else if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            // Complete setup
            finishSetup()
        }
    }

    private func finishSetup() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Mark setup as completed
        burnerManager.completeSetup()

        if let onSkip = onSkip {
            onSkip()
        } else {
            dismiss()
        }
    }
    
    private func requestAuthorization() {
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                await MainActor.run {
                    authorizationGranted = true
                }
            } catch {
                print("Authorization failed: \(error)")
            }
        }
    }
}

// MARK: - Radial Wipe Circle with Glow (ENHANCED)
struct RadialWipeCircleView: View {
    let currentStep: Int
    let totalSteps: Int
    let isStepCompleted: Bool
    let circleSize: CGFloat = 80
    let lineWidth: CGFloat = 12
    
    @State private var animatedProgress: Double = 0
    
    // Each step has 2 segments: arrival (50%) + completion (50%)
    private var targetProgress: Double {
        guard totalSteps > 0 else { return 0 }
        let totalSegments = totalSteps * 2
        let baseSegments = currentStep * 2  // Completed previous steps
        let currentSegments = isStepCompleted ? 2 : 1  // Current step progress
        return Double(baseSegments + currentSegments) / Double(totalSegments)
    }
    
    var body: some View {
        ZStack {
            // Background donut (unfilled track)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: lineWidth)
                .frame(width: circleSize, height: circleSize)
            
            // Glowing filled donut with radial progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: circleSize, height: circleSize)
                .rotationEffect(.degrees(-90)) // Start from top
                .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
                .shadow(color: .white.opacity(0.4), radius: 16, x: 0, y: 0)
                .shadow(color: .white.opacity(0.2), radius: 24, x: 0, y: 0)
        }
        .onChange(of: currentStep) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = targetProgress
            }
        }
        .onChange(of: isStepCompleted) { oldValue, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = targetProgress
            }
        }
        .onAppear {
            animatedProgress = 0
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.2)) {
                animatedProgress = targetProgress
            }
        }
    }
}

// MARK: - Welcome Slide Content (ENHANCED COPY)
struct WelcomeSlideContent: View {
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Welcome to BURNER")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Lock distracting apps during events. Your ticket won't unlock until you complete setup.")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: 16) {
                InfoBox(
                    icon: "clock.fill",
                    text: "BURNER will automatically activate once events start.",
                    color: .white
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - Permission Slide Content (ENHANCED COPY)
struct PermissionSlideContent: View {
    @Binding var authorizationGranted: Bool
    let onGrantPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(authorizationGranted ? "Access Granted" : "Enable Screen Time")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(authorizationGranted
                     ? "All set. Burner Mode can now protect your focus during events."
                     : "Required to block apps during events. Tap below to grant access in Settings.")
                .appBody()
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            if authorizationGranted {
                InfoBox(
                    icon: "checkmark.circle.fill",
                    text: "Screen Time access enabled",
                    color: .green
                )
            } else {
                VStack(spacing: 16) {
                    InfoBox(
                        icon: "lock.shield.fill",
                        text: "Your data stays private. BURNER never reads or stores Screen Time usage.",
                        color: .white
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}

struct InfoBox: View {
    let icon: String
    let text: String
    var color: Color = .blue
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.appIcon)
            
            Text(text)
                .appSecondary()
                .foregroundColor(.gray)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 30)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Selection Slide Content (ENHANCED COPY)
struct CategorySelectionSlideContent: View {
    @ObservedObject var burnerManager: BurnerModeManager
    @Binding var showingAppPicker: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(burnerManager.isSetupValid ? "You're All Set" : "Choose Distractions")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(burnerManager.isSetupValid
                     ? "Categories selected. Burner Mode is ready to protect your focus."
                     : "Select all app categories that distract you. These will be blocked during events.")
                .appBody()
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            VStack(spacing: 16) {
                InfoBox(
                    icon: burnerManager.isSetupValid ? "checkmark.circle.fill" : "square.grid.3x3.fill",
                    text: burnerManager.isSetupValid
                    ? "\(burnerManager.selectedApps.categoryTokens.count) categories ready to block"
                    : "Tap below to select all distracting app categories",
                    color: burnerManager.isSetupValid ? .green : .white
                )
                
                if !burnerManager.isSetupValid {
                    Button(action: {
                        showingAppPicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.appIcon)
                            Text("CHOOSE APPS")
                                .font(.appFont(size: 17))
                        }
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
}
