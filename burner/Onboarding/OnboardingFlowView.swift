import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher
import Combine

// MARK: - Onboarding Flow
struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var tagViewModel = TagViewModel() // Still needed for genre data

    @State private var currentStep = 0
    @State private var isRequesting = false

    // Total screens is 4: AuthWelcome (0) -> Location(1) -> Notifications(2) -> Complete(3)
    private let totalSlides = 4
    private let flowSteps = 2 // Location (1) -> Notifications (2)

    // MARK: - Navigation Logic
    // Progress bar runs from Location to Notifications (2 steps)
    private var progressStep: Int {
        // Steps 1 and 2 are the flow progress steps.
        // We map currentStep 1 -> 0, currentStep 2 -> 1, currentStep 3 -> 2 (Complete screen has no progress bar)
        return max(0, currentStep - 1)
    }
    
    // Note: The main "Continue" button logic is heavily simplified, only used for final complete step.

    private func getSkipText() -> String? {
        switch currentStep {
        case 1: return "skip" // Location
        case 2: return "skip" // Notifications/Genres
        default: return nil
        }
    }

    private var showBackButton: Bool {
        return currentStep > 0 && currentStep < totalSlides - 1
    }

    private func handleBackButton() {
        withAnimation(.easeOut(duration: 0.3)) {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Area with Back and Skip Buttons
                ZStack {
                    // Center: Logo or Progress Indicator
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)

                        if currentStep == 0 {
                            // Show Auth Header with Logo
                            AuthHeader()
                        } else if currentStep > 0 && currentStep < totalSlides - 1 {
                            // Show Progress Line (Steps 1, 2)
                            HStack {
                                Spacer()
                                ProgressLineView(
                                    currentStep: progressStep,
                                    totalSteps: flowSteps,
                                    isStepCompleted: progressStep > 0 // Only show completion after first step
                                )
                                .frame(width: 120) // Shorter width
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Invisible spacer to maintain height
                            Spacer().frame(height: 24)
                        }
                    }
                    .frame(maxWidth: .infinity)


                    // Top Left: Back Button
                    if showBackButton {
                        VStack {
                            HStack {
                                Button(action: { handleBackButton() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                }
                                .padding(.leading, 20)
                                .padding(.top, 10)
                                Spacer()
                            }
                            Spacer()
                        }
                    }

                    // Top Right: Skip Button
                    if let skipText = getSkipText() {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { handleSkip() }) {
                                    Text(skipText)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 10)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 50)

                // 🔄 Content Slides using ZStack and Offset (New Slide Animation)
                ZStack {
                    // Slides are stacked and offset based on currentStep
                    ForEach(0..<totalSlides, id: \.self) { step in
                        Group {
                            switch step {
                            case 0:
                                AuthWelcomeSlide(
                                    onLogin: { handleNextStep() },
                                    onExplore: { handleNextStep() }
                                )
                            case 1:
                                LocationSlide(onLocationSet: { handleNextStep() })
                            case 2:
                                NotificationGenreSlide( // Combined Notifications and Genres
                                    localPreferences: localPreferences,
                                    tagViewModel: tagViewModel,
                                    onContinue: { handleNextStep() }
                                )
                            case 3:
                                CompleteSlide()
                            default:
                                EmptyView()
                            }
                        }
                        .offset(x: slideOffset(for: step))
                        .opacity(step == currentStep ? 1 : 0) // Hide off-screen content
                        .zIndex(step == currentStep ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeOut(duration: 0.3), value: currentStep) // Apply animation here

                Spacer()

                // Bottom Action Area (Only visible on Complete Slide)
                if currentStep == totalSlides - 1 {
                    VStack(spacing: 16) {
                        Button(action: { completeOnboarding() }) {
                            Text("START EXPLORING".uppercased())
                                .appSecondary()
                                .foregroundColor(.black)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .environmentObject(localPreferences)
    }
    
    // Custom Slide Transition Logic
    private func slideOffset(for step: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth * CGFloat(step - currentStep)
    }

    // MARK: - Logic
    
    private func handleSkip() {
        // Special logic for location skip
        if currentStep == 1 {
            // Do NOT request or set location, just advance the step
        }
        handleNextStep()
    }

    private func handleNextStep() {
        withAnimation(.easeOut(duration: 0.3)) {
            if currentStep < totalSlides - 1 {
                currentStep += 1
            }
        }
    }
    
    private func completeOnboarding() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        onboardingManager.completeOnboarding()
    }
}

// MARK: - Step 0: Auth Welcome Slide
struct AuthWelcomeSlide: View {
    let onLogin: () -> Void
    let onExplore: () -> Void

    @State private var showingSignIn = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("WHERE WILL")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("YOU GO?")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)


            // Buttons
            VStack(spacing: 16) {
                // 1. LOG IN / SIGN UP (Primary: White/Black)
                Button(action: { showingSignIn = true }) {
                                    Text("LOG IN / SIGN UP")
                                        .appSecondary()
                                        .foregroundColor(.black)
                                        .frame(height: 50)
                                        // ⭐️ FIX: Set a fixed maximum width for the button
                                        .frame(maxWidth: 200)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())

                                // 2. EXPLORE (Secondary: Grey/White)
                                Button(action: onExplore) {
                                    Text("EXPLORE")
                                        .appSecondary()
                                        .foregroundColor(.white)
                                        .frame(height: 50)
                                        // ⭐️ FIX: Set a fixed maximum width for the button
                                        .frame(maxWidth: 200)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            // ⭐️ ADJUST: Increased horizontal padding to center the narrower buttons
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                            .padding(.top, 30)
                        }
                        .sheet(isPresented: $showingSignIn) {
                            SignInSheetView(showingSignIn: $showingSignIn, onSkip: { onLogin() })
        }
    }
}

// MARK: - Top Header (Auth and Logo)
struct AuthHeader: View {
    var body: some View {
        HStack {
            Spacer()
            Image("transparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
            Spacer()
        }
    }
}

// MARK: - Slide 1: Location
struct LocationSlide: View {
    @EnvironmentObject var appState: AppState
    @State private var showingManualEntry = false
    @State private var isProcessing = false
    
    let onLocationSet: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("WHERE ARE")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("YOU?")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 60)

            // Location buttons - centered, narrower pills, capitalized text
            VStack(spacing: 16) {
                Button(action: {
                    requestCurrentLocation()
                }) {
                    Text("CURRENT LOCATION")
                        .appBody()
                        .foregroundColor(.black)
                        .frame(height: 50)
                        // ⭐️ FIX: Set a fixed maximum width for the button
                        .frame(maxWidth: 200)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)

                Button(action: {
                    showingManualEntry = true
                }) {
                    Text("ENTER LOCATION")
                        .appBody()
                        .foregroundColor(.white)
                        .frame(height: 50)
                        // ⭐️ FIX: Set a fixed maximum width for the button
                        .frame(maxWidth: 200)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualCityEntryView(
                locationManager: appState.userLocationManager,
                onDismiss: {
                    showingManualEntry = false
                    
                }
            )
        }
    }

    private func requestCurrentLocation() {
        isProcessing = true
        appState.userLocationManager.requestCurrentLocation { result in
            DispatchQueue.main.async {
                isProcessing = false
                // Advance step automatically after location choice (request or not)
                onLocationSet()
            }
        }
    }
}

// MARK: - Slide 2: Notifications & Genres (Combined)
struct NotificationGenreSlide: View {
    @ObservedObject var localPreferences: LocalPreferences
    @ObservedObject var tagViewModel: TagViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text("GET NOTIFIED")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("Stay Updated")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 20)
            
            // --- Genre Selection ---
            Text("Select your vibes to curate your feed.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.bottom, 16)

            if tagViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    FlowLayout(spacing: 8) {
                        ForEach(tagViewModel.displayTags, id: \.self) { genre in
                            GenrePill(
                                title: genre,
                                isSelected: localPreferences.selectedGenres.contains(genre),
                                action: { toggleGenre(genre) }
                            )
                        }
                    }
                    .padding(.bottom, 80) // Padding for scroll view under arrow
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .overlay(
            // Navigation Pill: Only appears if a genre is selected
            VStack {
                Spacer()
                if !localPreferences.selectedGenres.isEmpty {
                    Button(action: onContinue) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
            , alignment: .bottom
        )
    }

    private func toggleGenre(_ genre: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if localPreferences.selectedGenres.contains(genre) {
                localPreferences.selectedGenres.removeAll { $0 == genre }
            } else {
                localPreferences.selectedGenres.append(genre)
            }
        }
    }
}

// MARK: - Slide 3: Complete
struct CompleteSlide: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 40)

            Text("You're All Set!")
                .font(.system(size: 48, weight: .bold))
                .kerning(-1.5)
                .foregroundColor(.white)
            
            Text("Your feed is ready. Let's find your next experience.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.top, 16)
            
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "hand.wave")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Supporting Views

// FlowLayout for flexible genre pill wrapping
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
                self.size.width = max(self.size.width, currentX - spacing)
                self.size.height = currentY + lineHeight
            }
        }
    }
}

struct GenrePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title.lowercased())
                    .appSecondary()
                    .font(.system(size: 16, weight: .medium)) // Adjusted size slightly
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
