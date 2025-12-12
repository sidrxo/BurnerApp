// BurnerModeSetupView.swift - Fixed to prevent advancing without proper setup

import SwiftUI
import FamilyControls
import ManagedSettings

struct BurnerModeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0

    @State private var authorizationGranted = false
    @State private var showingAppPicker = false
    @ObservedObject var burnerManager: BurnerModeManager
    var onSkip: (() -> Void)? = nil
    
    private let totalSteps = 6
    
    // ✅ FIXED: More strict step completion validation
    private var isCurrentStepCompleted: Bool {
        switch currentStep {
        case 0: return true  // Welcome
        case 1: return true  // What is it
        case 2: return true  // How to exit
        case 3: return authorizationGranted  // Screen Time - must be granted
        case 4: return burnerManager.isSetupValid  // Categories - must have all 8 categories
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
                // Header Area
                ZStack {
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
                            Spacer().frame(height: 24)
                        }
                    }
                    .frame(maxWidth: .infinity)
                   
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
                    WelcomeSlideContent()
                        .tag(0)
                   
                    WhatIsItSlideContent()
                        .tag(1)
                   
                    ExitMethodsSlideContent()
                        .tag(2)
                   
                    PermissionSlideContent(
                        authorizationGranted: $authorizationGranted,
                        onGrantPermission: requestAuthorization,
                        currentStep: $currentStep
                    )
                    .tag(3)
                   
                    CategorySelectionSlideContent(
                        burnerManager: burnerManager,
                        showingAppPicker: $showingAppPicker,
                        currentStep: $currentStep
                    )
                    .tag(4)
                   
                    ConfirmationSlideContent(
                        burnerManager: burnerManager
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(true)
                .animation(.easeOut(duration: 0.3), value: currentStep)
              
                Spacer()
              
                VStack(spacing: 12) {
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
            // Check authorization status on appear
            authorizationGranted = (AuthorizationCenter.shared.authorizationStatus == .approved)
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
    
    // ✅ FIXED: Strict validation - can't proceed without completing current step
    private func canProceed() -> Bool {
        switch currentStep {
        case 0, 1, 2: return true  // Info slides
        case 3: return true  // Button handles both grant and continue
        case 4: return true  // Button opens picker or advances if valid
        case 5: return burnerManager.isSetupValid  // Final step requires valid setup
        default: return false
        }
    }

    private func handleNextButton() {
        // ✅ Screen Time step - handle authorization
        if currentStep == 3 {
            if !authorizationGranted {
                requestAuthorization()
            } else {
                // Already authorized, proceed
                withAnimation {
                    currentStep += 1
                }
            }
            return
        }
        
        // ✅ Category selection step - strict validation
        if currentStep == 4 {
            if !burnerManager.isSetupValid {
                // Show picker if not valid
                showingAppPicker = true
            } else {
                // Valid setup, can advance
                withAnimation {
                    currentStep += 1
                }
            }
            return
        }
        
        // ✅ Final confirmation step - verify setup before completing
        if currentStep == 5 {
            // Double-check setup is actually valid before finishing
            if burnerManager.isSetupValid {
                finishSetup()
            }
            return
        }
        
        // ✅ All other steps
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        }
    }

    private func finishSetup() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        burnerManager.completeSetup()

        if let onSkip = onSkip {
            onSkip()
        } else {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appState.navigationCoordinator.selectTab(.tickets)
            }
        }
    }
    
    private func requestAuthorization() {
        Task {
            let preStatus = AuthorizationCenter.shared.authorizationStatus
           
            if preStatus == .approved {
                await MainActor.run {
                    self.authorizationGranted = true
                }
                return
            }
           
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                try await Task.sleep(nanoseconds: 500_000_000)
              
                let postStatus = AuthorizationCenter.shared.authorizationStatus
                await MainActor.run {
                    self.authorizationGranted = (postStatus == .approved)
                }
            } catch {
                let finalStatus = AuthorizationCenter.shared.authorizationStatus
                await MainActor.run {
                    self.authorizationGranted = (finalStatus == .approved)
                }
            }
        }
    }
}

// MARK: - CategorySelectionSlideContent with validation feedback

struct CategorySelectionSlideContent: View {
    @ObservedObject var burnerManager: BurnerModeManager
    @Binding var showingAppPicker: Bool
    @Binding var currentStep: Int

    private var categoryCount: Int {
        burnerManager.selectedApps.categoryTokens.count
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)

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
            } else if categoryCount > 0 {
                // ✅ Show progress if some categories selected but not enough
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .appSectionHeader()
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(categoryCount) of \(burnerManager.minimumCategoriesRequired) categories")
                            .appFont(size: 17, weight: .semibold)
                            .foregroundColor(.white)

                        Text("Select more categories to continue")
                            .font(.appFont(size: 14))
                            .kerning(-0.3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// Keep all other slide components the same...
struct WelcomeSlideContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 60)
            VStack(alignment: .leading, spacing: 0) {
                TightHeaderText("UNLOCK YOUR", "TICKETS.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer().frame(height: 24)
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
            Spacer().frame(height: 60)
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
            Spacer().frame(height: 32)
            VStack(spacing: 20) {
                StepCard(number: "1", title: "Buy Ticket", description: "Purchase a ticket through the app.")
                StepCard(number: "2", title: "Scan In", description: "When scanned at the venue, BURNER activates. Phone, Messages, and Maps stay accessible.")
                StepCard(number: "3", title: "Stay Present", description: "When the event ends, you'll get a notification and apps unlock.")
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
            Spacer().frame(height: 60)
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
            Spacer().frame(height: 32)
            VStack(spacing: 16) {
                ExitMethodCard(icon: "timer", title: "Self-Unlock Timer", description: "Wait through a cooldown period.")
                ExitMethodCard(icon: "person.badge.key.fill", title: "Staff Override", description: "Event staff can unlock instantly.")
                ExitMethodCard(icon: "clock.badge.checkmark.fill", title: "Event Ends", description: "Automatic unlock with notification.")
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

struct PermissionSlideContent: View {
    @Binding var authorizationGranted: Bool
    let onGrantPermission: () -> Void
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)
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
            Text(authorizationGranted
                    ? "Screen Time access enabled. BURNER can now block apps during events."
                    : "Required to block apps during events. We never read or store your data.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
            Spacer().frame(height: 32)
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
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .onChange(of: authorizationGranted) { oldValue, newValue in
            if newValue == true {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation {
                        currentStep += 1
                    }
                }
            }
        }
    }
}

struct ConfirmationSlideContent: View {
    @ObservedObject var burnerManager: BurnerModeManager
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TightHeaderText("SEE YOU", "THERE!", alignment: .center)
            Text("BURNER is ready. Your ticket is now available in the tickets tab.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct ProgressLineView: View {
    let currentStep: Int
    let totalSteps: Int
    let isStepCompleted: Bool
    let lineHeight: CGFloat = 4
    
    @State private var animatedProgress: Double = 0
    
    private var targetProgress: Double {
        guard totalSteps > 0 else { return 0 }
        let totalSegments = totalSteps * 2
        let baseSegments = currentStep * 2
        let currentSegments = isStepCompleted ? 2 : 1
        return Double(baseSegments + currentSegments) / Double(totalSegments)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: lineHeight)
                    .clipShape(Capsule())
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
