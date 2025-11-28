import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher
import Combine

// MARK: - Onboarding Flow
struct OnboardingFlowView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var tagViewModel = TagViewModel()

    @State private var currentStep = 0
    @State private var isRequesting = false
    @State private var isCompleting = false

    // Total screens is 5: AuthWelcome (0) -> Location(1) -> Genres(2) -> Notifications(3) -> Complete(4)
    private let totalSlides = 5
    private let flowSteps = 3 // Location (1) -> Genres (2) -> Notifications (3)

    // MARK: - Navigation Logic
    private var progressStep: Int {
        return max(0, currentStep - 1)
    }

    private func getSkipText() -> String? {
        switch currentStep {
        case 1: return "SKIP"
        case 2: return "SKIP"
        case 3: return "SKIP"
        default: return nil
        }
    }

    private var showBackButton: Bool {
        return currentStep > 0 && currentStep < totalSlides - 1
    }

    private func handleBackButton() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                    
                    // 1. Center: Logo or Progress Indicator
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)
                        
                        if currentStep == 0 {
                            // Show Auth Header with Logo
                            AuthHeader()
                        } else if currentStep > 0 && currentStep < totalSlides - 1 {
                            // Show Progress Line (Steps 1, 2, 3)
                            HStack {
                                Spacer()
                                ProgressLineView(
                                    currentStep: progressStep,
                                    totalSteps: flowSteps,
                                    isStepCompleted: progressStep > 0
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
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.top, 10)
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }

                    // 3. Top Right: Skip Button
                    if let skipText = getSkipText() {
                        HStack {
                            Spacer()
                            Button(action: { handleSkip() }) {
                                Text(skipText)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 10)
                        }
                    }
                }
                .frame(height: 60)

                // Content Slides using ZStack and Offset
                ZStack {
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
                                GenreSlide(
                                    localPreferences: localPreferences,
                                    tagViewModel: tagViewModel,
                                    onContinue: { handleNextStep() }
                                )
                            case 3:
                                NotificationsSlide(onContinue: { handleNextStep() })
                            case 4:
                                CompleteSlide(onComplete: { completeOnboarding() })
                            default:
                                EmptyView()
                            }
                        }
                        .offset(x: slideOffset(for: step))
                        .opacity(step == currentStep ? 1 : 0)
                        .zIndex(step == currentStep ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeOut(duration: 0.3), value: currentStep)

                Spacer()
            }
        }
        .environmentObject(localPreferences)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SkipOnboardingToExplore"))) { _ in
            completeOnboarding()
        }
        .onAppear {
            // Onboarding flow started
        }
        .onDisappear {
            // Onboarding flow ended
        }
    }
    
    // Custom Slide Transition Logic
    private func slideOffset(for step: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth * CGFloat(step - currentStep)
    }

    // MARK: - Logic
    
    private func handleSkip() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        guard !isCompleting else {
            return
        }
        
        isCompleting = true
        
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
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                  .frame(minHeight: 200)

            // Header positioned at consistent height
            VStack(spacing: 0) {
                TightHeaderText("MEET ME IN THE", "MOMENT", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
            .padding(.bottom, 40)
            .padding(.top, 200)
            // Buttons
            VStack(spacing: 16) {
                BurnerButton("SIGN UP / IN", style: .primary, maxWidth: 200) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingSignIn = true
                }
                .buttonStyle(PlainButtonStyle())

                BurnerButton("EXPLORE", style: .secondary, maxWidth: 160) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onExplore()
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(minHeight: 30)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn, onSkip: {
                onLogin()
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            showingSignIn = false
            onLogin()
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
    @EnvironmentObject var localPreferences: LocalPreferences
    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var detectedCity: String?

    let onLocationSet: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Fixed top spacing for consistent alignment
            Color.clear.frame(height: 100)

            // Header positioned at consistent height
            VStack(spacing: 0) {
                TightHeaderText("WHERE ARE", "YOU?", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)

            Text("We'll use this to show you nearby events.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

            // Location buttons
            VStack(spacing: 16) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    requestCurrentLocation()
                }) {
                    HStack(spacing: 6) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .bold))
                        }
                        
                        Text(detectedCity ?? "CURRENT LOCATION")
                            .font(.system(size: 16, design: .monospaced))
                            .lineLimit(1)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showingManualEntry = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))

                        Text("ENTER CITY")
                            .font(.system(size: 16, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: 160)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: 1)
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
        .onChange(of: appState.userLocationManager.savedLocation) { _, newLocation in
            if let location = newLocation {
                localPreferences.locationName = location.name
                localPreferences.locationLat = location.latitude
                localPreferences.locationLon = location.longitude
            }
        }
    }

    private func requestCurrentLocation() {
        isProcessing = true
        appState.userLocationManager.requestCurrentLocation { result in
            DispatchQueue.main.async {
                isProcessing = false

                if let savedLocation = appState.userLocationManager.savedLocation {
                    localPreferences.locationName = savedLocation.name
                    localPreferences.locationLat = savedLocation.latitude
                    localPreferences.locationLon = savedLocation.longitude
                    
                    // Show the city name on the button
                    detectedCity = savedLocation.name.uppercased()
                    
                    // Auto-advance after showing city
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onLocationSet()
                    }
                }
            }
        }
    }
}

// MARK: - Slide 2: Genres
struct GenreSlide: View {
    @ObservedObject var localPreferences: LocalPreferences
    @ObservedObject var tagViewModel: TagViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Fixed top spacing for consistent alignment
            Color.clear.frame(height: 100)

            // Header positioned at consistent height
            VStack(spacing: 0) {
                TightHeaderText("WHAT'S YOUR", "VIBE?", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)

            Text("Get personalized event recommendations.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
                .padding(.bottom, 32)

            if tagViewModel.isLoading {
                ProgressView().tint(.white)
                    .padding(.bottom, 80)
            } else {
                // Show genres without scroll view
                FlowLayout(spacing: 8) {
                    ForEach(tagViewModel.displayTags, id: \.self) { genre in
                        GenrePill(
                            title: genre,
                            isSelected: localPreferences.selectedGenres.contains(genre),
                            action: { toggleGenre(genre) }
                        )
                    }
                }
                .animation(nil, value: localPreferences.selectedGenres)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
            
            // Continue button
            Group {
                if !localPreferences.selectedGenres.isEmpty {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onContinue()
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    Color.clear.frame(width: 60, height: 60)
                }
            }
            
            Spacer()
        }
    }

    private func toggleGenre(_ genre: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if localPreferences.selectedGenres.contains(genre) {
            localPreferences.selectedGenres.removeAll { $0 == genre }
        } else {
            localPreferences.selectedGenres.append(genre)
        }
    }
}

// MARK: - Slide 3: Notifications
struct NotificationsSlide: View {
    @EnvironmentObject var localPreferences: LocalPreferences
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Fixed top spacing for consistent alignment
            Color.clear.frame(height: 100)

            // Header positioned at consistent height
            VStack(spacing: 0) {
                TightHeaderText("STAY IN", "THE LOOP", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)

            Text("Get alerts for new events and updates on shows you're interested in.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
                .padding(.bottom, 40)

            BurnerButton("I'M IN", style: .primary, maxWidth: 140) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                requestNotifications()
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                localPreferences.hasEnabledNotifications = granted
                onContinue()
            }
        }
    }
}

// MARK: - Slide 4: Complete (Success Screen with auto-advance)
struct CompleteSlide: View {
    let onComplete: () -> Void
    @State private var hasTriggeredCompletion = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 32)
            
            // Header positioned at consistent height
            VStack(spacing: 0) {
                TightHeaderText("YOU'RE ALL", "SET!", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
            
            Text("Let's explore what's happening near you.")
                .appBody()
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            // Auto-advance after 1 second
            if !hasTriggeredCompletion {
                hasTriggeredCompletion = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
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
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background(isSelected ? Color.white : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
