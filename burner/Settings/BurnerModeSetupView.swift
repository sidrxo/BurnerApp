import SwiftUI
import FamilyControls
import ManagedSettings

struct PointOffset: Equatable {
    let x: Float
    let y: Float
}

struct BurnerModeSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep = 0
    @State private var authorizationGranted = false
    @State private var showingAppPicker = false
    @State private var randomOffsets: [PointOffset] = Array(repeating: PointOffset(x: 0, y: 0), count: 16)
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
                
                // Fixed animated gradient circle at the top
                Spacer()
                    .frame(height: 80)
                
                AnimatedGradientCircle(randomOffsets: $randomOffsets)
                    .padding(.bottom, 32)
                
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
        .onChange(of: currentStep) { _, _ in
            animateGradient()
        }
    }
    
    private func animateGradient() {
        randomOffsets = (0..<16).map { index in
            if index == 5 || index == 6 || index == 9 || index == 10 {
                return PointOffset(
                    x: Float.random(in: -0.2...0.2),
                    y: Float.random(in: -0.2...0.2)
                )
            }
            return PointOffset(x: 0, y: 0)
        }
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

// MARK: - Animated Gradient Circle Component
struct AnimatedGradientCircle: View {
    @Binding var randomOffsets: [PointOffset]
    var size: CGFloat = 120
    
    var body: some View {
        MeshGradient(
            width: 4,
            height: 4,
            points: [
                [0.0, 0.0],
                [0.3, 0.0],
                [0.7, 0.0],
                [1.0, 0.0],

                [0.0, 0.3],
                [0.2 + randomOffsets[5].x, 0.4 + randomOffsets[5].y],
                [0.7 + randomOffsets[6].x, 0.2 + randomOffsets[6].y],
                [1.0, 0.3],

                [0.0, 0.7],
                [0.3 + randomOffsets[9].x, 0.8 + randomOffsets[9].y],
                [0.7 + randomOffsets[10].x, 0.6 + randomOffsets[10].y],
                [1.0, 0.7],

                [0.0, 1.0],
                [0.3, 1.0],
                [0.7, 1.0],
                [1.0, 1.0]
            ],
            colors: [
                .purple, .indigo, .purple, .yellow,
                .pink, .purple, .pink, .yellow,
                .orange, .pink, .yellow, .orange,
                .yellow, .orange, .pink, .purple
            ]
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(radius: 20)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: randomOffsets)
    }
}

// MARK: - Welcome Slide Content (no circle)
struct WelcomeSlideContent: View {
    var body: some View {
        VStack(spacing: 0) {
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
                .appSectionHeader()
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

// MARK: - Permission Slide Content (no circle)
struct PermissionSlideContent: View {
    @Binding var authorizationGranted: Bool
    let onGrantPermission: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
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

// MARK: - Category Selection Slide Content (no circle)
struct CategorySelectionSlideContent: View {
    @ObservedObject var burnerManager: BurnerModeManager
    @Binding var showingAppPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
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
