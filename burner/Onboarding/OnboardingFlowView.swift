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
    @StateObject private var tagViewModel = TagViewModel()

    @State private var currentStep = 0
    @State private var isRequesting = false

    // Total screens is 5: AuthWelcome (0) -> Location(1) -> Notifications(2) -> Genres(3) -> Complete(4)
    private let totalSlides = 5
    private let flowSteps = 3 // Location (1) -> Notifications (2) -> Genres (3)

    // MARK: - Navigation Logic
    private var progressStep: Int {
        return max(0, currentStep - 1)
    }

    private func getSkipText() -> String? {
        switch currentStep {
        case 1: return "skip"
        case 2: return "skip"
        case 3: return "skip"
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
                            // Show Progress Line (Steps 1, 2, 3)
                            HStack {
                                Spacer()
                                ProgressLineView(
                                    currentStep: progressStep,
                                    totalSteps: flowSteps,
                                    isStepCompleted: progressStep > 0
                                )
                                .frame(width: 120)
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
                            HStack(alignment: .center) {
                                Button(action: { handleBackButton() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
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
                            HStack(alignment: .center) {
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

                // 🔄 Content Slides using ZStack and Offset
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
                                NotificationsSlide(onContinue: { handleNextStep() })
                            case 3:
                                GenreSlide(
                                    localPreferences: localPreferences,
                                    tagViewModel: tagViewModel,
                                    onContinue: { handleNextStep() }
                                )
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
    }
    
    // Custom Slide Transition Logic
    private func slideOffset(for step: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth * CGFloat(step - currentStep)
    }

    // MARK: - Logic
    
    private func handleSkip() {
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
            .padding(.bottom, 16)
            
            Text("We'll use this to show you nearby events.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)

            // Location buttons
            VStack(spacing: 16) {
                Button(action: {
                    requestCurrentLocation()
                }) {
                    Text("CURRENT LOCATION")
                        .appBody()
                        .foregroundColor(.black)
                        .frame(height: 50)
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
                onLocationSet()
            }
        }
    }
}

// MARK: - Slide 2: Notifications
struct NotificationsSlide: View {
    let onContinue: () -> Void
    @State private var selectedOption: NotificationOption = .all

    enum NotificationOption {
        case all
        case myEventsOnly
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                Text("STAY IN")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("THE LOOP")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
            
            Text("Get notified about new events, recommendations, and updates on shows you're interested in.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)
                .padding(.bottom, 40)

            // Notification option pills
            VStack(spacing: 16) {
                Button(action: {
                    selectedOption = .all
                    requestNotifications()
                }) {
                    Text("I'M IN")
                        .appBody()
                        .foregroundColor(.black)
                        .frame(height: 50)
                        .frame(maxWidth: 200)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    selectedOption = .myEventsOnly
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onContinue()
                    }
                }) {
                    Text("SAVED ONLY")
                        .appBody()
                        .foregroundColor(.white)
                        .frame(height: 50)
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
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                onContinue()
            }
        }
    }
}

// MARK: - Slide 3: Genres
struct GenreSlide: View {
    @ObservedObject var localPreferences: LocalPreferences
    @ObservedObject var tagViewModel: TagViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text("WHAT'S YOUR")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("VIBE?")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 16)
            
            Text("We'll curate your feed based on your interests.")
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
                    .animation(nil, value: localPreferences.selectedGenres)
                    .padding(.bottom, 80)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .overlay(
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
        if localPreferences.selectedGenres.contains(genre) {
            localPreferences.selectedGenres.removeAll { $0 == genre }
        } else {
            localPreferences.selectedGenres.append(genre)
        }
    }
}

// MARK: - Slide 4: Complete (Auto-dismiss loader)
struct CompleteSlide: View {
    let onComplete: () -> Void
    
    @State private var currentMessageIndex = 0
    @State private var loadingProgress: CGFloat = 0
    
    let loadingMessages = [
        "Curating your feed...",
        "Loading your preferences...",
        "Downloading event database...",
        "Finding events near you...",
        "Almost ready..."
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated loader
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: loadingProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: loadingProgress)
            }
            .padding(.bottom, 32)
            
            // Loading message
            Text(loadingMessages[currentMessageIndex])
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .animation(.easeInOut, value: currentMessageIndex)
            
            Spacer()
        }
        .onAppear {
            startLoadingSequence()
        }
    }
    
    private func startLoadingSequence() {
        // Animate progress bar
        withAnimation(.easeInOut(duration: 2.5)) {
            loadingProgress = 1.0
        }
        
        // Cycle through messages
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if currentMessageIndex < loadingMessages.count - 1 {
                currentMessageIndex += 1
            } else {
                timer.invalidate()
            }
        }
        
        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete()
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
                    .font(.system(size: 16, weight: .medium))
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
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
