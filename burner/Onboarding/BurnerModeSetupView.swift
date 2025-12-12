import SwiftUI
import FamilyControls
import ManagedSettings

// NOTE: You will need to define your custom extensions (e.g., .appFont, .appIcon, .appSecondary)
// and the BurnerModeManager/TightHeaderText structures for this to compile fully in your project environment.

// MARK: - Main View

struct BurnerModeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0

    // START: FIX - Authorization status must start as false to prevent unwanted auto-advance.
    @State private var authorizationGranted = false
    // END: FIX

    @State private var showingAppPicker = false
    @ObservedObject var burnerManager: BurnerModeManager // Assume BurnerModeManager is defined elsewhere
    var onSkip: (() -> Void)? = nil
    
    private let totalSteps = 6
    
    // START: FIX - Removed checkAuthorizationStatus() call from onAppear/initialization
    
    // Track completion state of current step
    private var isCurrentStepCompleted: Bool {
        switch currentStep {
        case 0: return true  // Welcome
        case 1: return true  // What is it
        case 2: return true  // How to exit
        case 3: return authorizationGranted  // Screen Time
        case 4: return burnerManager.isSetupValid  // Categories
        case 5: return true  // Confirmation
        default: return false
        }
    }
    
    private var showBackButton: Bool {
        return currentStep > 0 && currentStep < totalSteps - 1
    }
    
    private func handleBackButton() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.3)) {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Area with Back and Close Buttons
                ZStack {
                    // 1. Center: Progress Indicator
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)
                        
                        if currentStep > 0 {
                            HStack {
                                Spacer()
                                ProgressLineView(
                                    currentStep: currentStep - 1,
                                    totalSteps: totalSteps - 1,
                                    isStepCompleted: isCurrentStepCompleted
                                )
                                .frame(width: 120)
                                .padding(.bottom, 3)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Invisible spacer to maintain height
                            Spacer().frame(height: 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // 2. Top Left: Back Button
                    if showBackButton {
                        HStack {
                            Button(action: { handleBackButton() }) {
                                Image(systemName: "chevron.left")
                                    .appFont(size: 20, weight: .medium)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.top, 10)
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    
                    // 3. Top Right: Close Button
                    HStack {
                        Spacer()
                        Button(action: {
                            if let onSkip = onSkip {
                                onSkip()
                            } else {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .appFont(size: 17, weight: .semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                    }
                }
                .frame(height: 60)
                
                // Sliding content area
                TabView(selection: $currentStep) {
                    // Step 0: Welcome
                    WelcomeSlideContent()
                        .tag(0)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                    // Step 1: What is it?
                    WhatIsItSlideContent()
                        .tag(1)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                    // Step 2: How to exit early
                    ExitMethodsSlideContent()
                        .tag(2)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    
                    // Step 3: Grant Permission
                    PermissionSlideContent(
                        authorizationGranted: $authorizationGranted,
                        onGrantPermission: requestAuthorization,
                        currentStep: $currentStep
                    )
                    .tag(3)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    
                    // Step 4: Select Categories
                    CategorySelectionSlideContent(
                        burnerManager: burnerManager,
                        showingAppPicker: $showingAppPicker,
                        currentStep: $currentStep
                    )
                    .tag(4)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    
                    // Step 5: Confirmation
                    ConfirmationSlideContent(
                        burnerManager: burnerManager
                    )
                    .tag(5)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(true)  // Disable swipe navigation
                .animation(.easeOut(duration: 0.3), value: currentStep)
                
                Spacer()
                
                VStack(spacing: 12) {
                    // Navigation button - fixed at bottom
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: $burnerManager.selectedApps
        )
        .interactiveDismissDisabled(true)
        .onAppear {
            // START: FIX - Removed call to checkAuthorizationStatus()
        }
    }
    
    private func getNextButtonText() -> String {
        switch currentStep {
        case 0: return "Get Started"
        case 1, 2: return "Continue"
        case 3: return authorizationGranted ? "Continue" : "Grant Access"
        case 4:
            if !burnerManager.isSetupValid {
                return "Select Categories"
            } else {
                return "Continue"
            }
        case 5: return "Complete Setup"
        default: return "Next"
        }
    }
    
    private func canProceed() -> Bool {
        switch currentStep {
        case 0, 1, 2: return true
        case 3: return true  // Always allow button on Screen Time page (button handles both grant and continue)
        case 4: return burnerManager.isSetupValid  // Only allow if categories are selected
        case 5: return true
        default: return false
        }
    }

    private func handleNextButton() {
        if currentStep == 3 && !authorizationGranted {
            // Request authorization (will check status first, and auto-advance on success)
            requestAuthorization()
        } else if currentStep == 4 {
            if !burnerManager.isSetupValid {
                // Show app picker to select categories
                showingAppPicker = true
            } else {
                // Categories already selected, advance to next step
                withAnimation {
                    currentStep += 1
                }
            }
        } else if currentStep < totalSteps - 1 {
            // Advance to next step
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
            // If onSkip is provided, let the caller handle dismissal and navigation
            onSkip()
        } else {
            // Otherwise, dismiss and navigate to tickets tab
            dismiss()

            // Navigate to tickets tab to show the user's ticket
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.navigationCoordinator.selectTab(.tickets)
            }
        }
    }
    
    // START: FIX - Modified requestAuthorization to check status first
    private func requestAuthorization() {
        Task {
            // 1. Check current status
            let preStatus = AuthorizationCenter.shared.authorizationStatus
            
            if preStatus == .approved {
                // Already approved: Set state to true to trigger auto-advance without showing the system dialog
                await MainActor.run {
                    self.authorizationGranted = true
                }
                return
            }
            
            // 2. If not approved, request it
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                
                // Wait briefly for the system to process/update
                try await Task.sleep(nanoseconds: 500_000_000)
                
                // 3. Check the final authorization status
                let postStatus = AuthorizationCenter.shared.authorizationStatus
                await MainActor.run {
                    self.authorizationGranted = (postStatus == .approved)
                }
            } catch {
                // Fallback check in case user cancels or navigates to settings
                let finalStatus = AuthorizationCenter.shared.authorizationStatus
                await MainActor.run {
                    self.authorizationGranted = (finalStatus == .approved)
                }
            }
        }
    }
    // END: FIX
}

// MARK: - Progress Line with Glow
struct ProgressLineView: View {
    let currentStep: Int
    let totalSteps: Int
    let isStepCompleted: Bool
    let lineHeight: CGFloat = 4
    
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
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background line (unfilled track)
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: lineHeight)
                    .clipShape(Capsule())
                
                // Glowing filled line with progress
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * animatedProgress, height: lineHeight)
                    .clipShape(Capsule())
                    .shadow(color: .white.opacity(0.6), radius: 8, x: 0, y: 0)
                    .shadow(color: .white.opacity(0.4), radius: 16, x: 0, y: 0)
            }
        }
        .frame(height: lineHeight)
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

// MARK: - Slide Content Structures (No Changes)

// Assuming these helper types are defined elsewhere:
// - struct TightHeaderText: View
// - extension View { func appBody() -> some View; func appFont(size: CGFloat) -> Font }
// - final class BurnerModeManager: ObservableObject { var selectedApps: FamilyActivitySelection { get set } ... }

struct WelcomeSlideContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 60)

            VStack(alignment: .leading, spacing: 0) {
                TightHeaderText("UNLOCK YOUR", "TICKETS.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
                .frame(height: 24)

            Text("Complete this quick setup to access your tickets. You'll only need to do this once.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct WhatIsItSlideContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 60)

            VStack(alignment: .leading, spacing: 0) {
                TightHeaderText("HOW DOES IT", "WORK?")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("BURNER blocks distracting apps during events.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 32)
            
            VStack(spacing: 20) {
                StepCard(
                    number: "1",
                    title: "Buy Ticket",
                    description: "Purchase a ticket through the app."
                )
                
                StepCard(
                    number: "2",
                    title: "Scan In",
                    description: "When scanned at the venue, BURNER activates. Phone, Messages, and Maps stay accessible."
                )
                
                StepCard(
                    number: "3",
                    title: "Stay Present",
                    description: "When the event ends, you'll get a notification and apps unlock."
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct StepCard: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number circle
            Text(number)
                .appCard()
                .foregroundColor(.black)
                .frame(width: 36, height: 36)
                .background(Color.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appFont(size: 17, weight: .semibold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.appFont(size: 14))
                    .kerning(-0.3)
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExitMethodsSlideContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: 60)

            VStack(alignment: .leading, spacing: 0) {
                TightHeaderText("NEED TO", "LEAVE EARLY?")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("Three ways to exit BURNER before the event ends.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 32)
            
            // Exit methods
            VStack(spacing: 16) {
                ExitMethodCard(
                    icon: "timer",
                    title: "Self-Unlock Timer",
                    description: "Wait through a cooldown period."
                )
                
                ExitMethodCard(
                    icon: "person.badge.key.fill",
                    title: "Staff Override",
                    description: "Event staff can unlock instantly."
                )
                
                ExitMethodCard(
                    icon: "clock.badge.checkmark.fill",
                    title: "Event Ends",
                    description: "Automatic unlock with notification."
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct ExitMethodCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .appFont(size: 20)
                .foregroundColor(.white)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appBody()
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.appFont(size: 14))
                    .kerning(-0.3)
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Permission Slide Content

struct PermissionSlideContent: View {
    @Binding var authorizationGranted: Bool
    let onGrantPermission: () -> Void
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // Consistent header spacing
            Spacer()
                .frame(height: 60)

            // Use reusable TightHeaderText component (aligned left)
            if authorizationGranted {
                VStack(alignment: .leading, spacing: 0) {
                    TightHeaderText("YOU'RE", "APPROVED")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    TightHeaderText("GRANT", "ACCESS")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Subtitle below
            Text(authorizationGranted
                    ? "Screen Time access enabled. BURNER can now block apps during events."
                    : "Required to block apps during events. We never read or store your data.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            
            Spacer()
                .frame(height: 32)
            
            if authorizationGranted {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .appSectionHeader()
                        .foregroundColor(.white)
                    
                    Text("READY TO CONTINUE")
                        .appBody()
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
       
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: authorizationGranted) { oldValue, newValue in
            // This is the auto-advance that triggers after the user explicitly taps "Grant Access"
            if newValue == true {
                // Auto-advance after showing success briefly
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            }
        }
    }
}

// MARK: - Category Selection Slide Content

struct CategorySelectionSlideContent: View {
    @ObservedObject var burnerManager: BurnerModeManager
    @Binding var showingAppPicker: Bool
    @Binding var currentStep: Int
    @State private var hasAutoAdvanced = false

    private var categoryCount: Int {
        burnerManager.selectedApps.categoryTokens.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Consistent header spacing
            Spacer()
                .frame(height: 60)

            // Use reusable TightHeaderText component (aligned left)
            if burnerManager.isSetupValid {
                VStack(alignment: .leading, spacing: 0) {
                    TightHeaderText("CATEGORIES", "SELECTED")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    TightHeaderText("CHOOSE", "DISTRACTIONS")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Subtitle below
            Text(burnerManager.isSetupValid
                    ? "We'll take care of the rest."
                    : "Select 'All Apps and Categories'.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)

            Spacer()
                .frame(height: 32)

            if burnerManager.isSetupValid {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .appSectionHeader()
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("All categories selected")
                            .appFont(size: 17, weight: .semibold)
                            .foregroundColor(.white)

                        Text("Ready to continue")
                            .font(.appFont(size: 14))
                            .kerning(-0.3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: burnerManager.isSetupValid) { oldValue, newValue in
            // Removed auto-advance to prevent skipping category selection
            // User must manually click Continue button after selecting categories
        }
        .onAppear {
            // Reset the auto-advance flag when returning to this slide
            if !burnerManager.isSetupValid {
                hasAutoAdvanced = false
            }
        }
    }
}

// MARK: - Confirmation Slide Content

struct ConfirmationSlideContent: View {
    @ObservedObject var burnerManager: BurnerModeManager
    
    private var categoryCount: Int {
        burnerManager.selectedApps.categoryTokens.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Flexible top spacer for vertical centering
            Spacer()

            // Title (Single line, no negative padding needed)
            TightHeaderText("SEE YOU", "THERE!", alignment: .center)


            // Subtitle below
            Text("BURNER is ready. Your ticket is now available in the tickets tab.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)

            // Flexible bottom spacer for vertical centering
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct ConfirmationItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .appFont(size: 20)
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.appFont(size: 16))
                .kerning(-0.3)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
