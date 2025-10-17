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
                
                // Content area
                TabView(selection: $currentStep) {
                    // Step 1: Welcome
                    WelcomeSlide()
                        .tag(0)
                    
                    // Step 2: Grant Permission
                    PermissionSlide(
                        authorizationGranted: $authorizationGranted,
                        onGrantPermission: requestAuthorization
                    )
                    .tag(1)
                    
                    // Step 3: Select Categories
                    CategorySelectionSlide(
                        burnerManager: burnerManager,
                        showingAppPicker: $showingAppPicker
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(currentStep == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Back")
                                .appBody()
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    Button(action: {
                        handleNextButton()
                    }) {
                        Text(getNextButtonText())
                            .appBody()
                            .foregroundColor(canProceed() ? .black : .gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canProceed() ? Color.white : Color.gray.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canProceed())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
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
        case 1: return authorizationGranted ? "Continue" : "Grant Permission"
        case 2: return burnerManager.isSetupValid ? "Complete Setup" : "Select Categories"
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
            if let onSkip = onSkip {
                onSkip()
            } else {
                dismiss()
            }
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

// MARK: - Welcome Slide
struct WelcomeSlide: View {
    var body: some View {
        VStack(spacing: 0) {
            // Fixed top spacing - consistent with other views
            Spacer()
                .frame(height: 80)
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 32)
            
            // Header text
            VStack(spacing: 12) {
                Text("Welcome to Burner.")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Block all distractions and stay focused by restricting access to apps during events.")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            
            // Info boxes
            VStack(spacing: 16) {
                InfoBox(
                    icon: "lock.shield.fill",
                    text: "Block all apps except essentials during events",
                    color: .blue
                )
                
                InfoBox(
                    icon: "clock.fill",
                    text: "Automatically activates when you attend ticketed events",
                    color: .blue
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appBody()
                    .foregroundColor(.white)
                Text(description)
                    .appSecondary()
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Permission Slide
struct PermissionSlide: View {
    @Binding var authorizationGranted: Bool
    let onGrantPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed top spacing - consistent with other views
            Spacer()
                .frame(height: 80)
            
            // Icon
            ZStack {
                Circle()
                    .fill(authorizationGranted ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: authorizationGranted ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 60))
                    .foregroundColor(authorizationGranted ? .green : .blue)
            }
            .padding(.bottom, 32)
            
            // Header text
            VStack(spacing: 12) {
                Text(authorizationGranted ? "Permission Granted" : "Grant Permission")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(authorizationGranted
                    ? "You're all set! Screen Time permissions have been granted."
                    : "Burner Mode needs Screen Time permissions to block apps. This is required.")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            
            // Info boxes
            if authorizationGranted {
                InfoBox(
                    icon: "checkmark.circle.fill",
                    text: "Screen Time access enabled successfully",
                    color: .green
                )
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 16) {
                    InfoBox(
                        icon: "info.circle.fill",
                        text: "This permission allows the app to manage which apps are accessible during Burner Mode.",
                        color: .blue
                    )
                    
                    InfoBox(
                        icon: "hand.raised.fill",
                        text: "Your privacy is protected. Burner does not read or collect any data about your Screen Time usage.",
                        color: .orange
                    )
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Category Selection Slide
struct CategorySelectionSlide: View {
    @ObservedObject var burnerManager: BurnerModeManager
    @Binding var showingAppPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed top spacing - consistent with other views
            Spacer()
                .frame(height: 80)
            
            // Icon
            ZStack {
                Circle()
                    .fill(burnerManager.isSetupValid ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: burnerManager.isSetupValid ? "checkmark.circle.fill" : "square.grid.3x3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(burnerManager.isSetupValid ? .green : .orange)
            }
            .padding(.bottom, 32)
            
            // Header text
            VStack(spacing: 12) {
                Text(burnerManager.isSetupValid ? "Categories Selected" : "Select App Categories")
                    .appPageHeader()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(burnerManager.isSetupValid
                    ? "You've selected enough categories. You're ready to use Burner Mode."
                    : "Select all app categories to enable Burner Mode blocking.")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            
            // Info boxes
            VStack(spacing: 16) {
                InfoBox(
                    icon: burnerManager.isSetupValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                    text: burnerManager.isSetupValid
                        ? "Ready for Burner Mode - \(burnerManager.selectedApps.categoryTokens.count) categories selected"
                        : "Select more categories - \(burnerManager.selectedApps.categoryTokens.count) of \(burnerManager.minimumCategoriesRequired) required",
                    color: burnerManager.isSetupValid ? .green : .orange
                )
                
                if !burnerManager.isSetupValid {
                    Button(action: {
                        showingAppPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.grid.3x3.fill")
                            Text("Open Category Selector")
                                .appBody()
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                } else {
                    Button(action: {
                        showingAppPicker = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Modify Selection")
                                .appBody()
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
