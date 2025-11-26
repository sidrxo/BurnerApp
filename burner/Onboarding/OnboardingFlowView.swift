import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher
import Combine

// MARK: - Onboarding Flow
struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss // Added for the 'Explore' button

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var tagViewModel = TagViewModel()

    @State private var currentStep = 0
    @State private var isRequesting = false

    // Updated Total Steps: AuthWelcome -> Location -> Genres -> Notifications -> Complete
    // Total screens is 5: AuthWelcome (0) -> Location(1) -> Genres(2) -> Notifications(3) -> Complete(4)
    private let totalSlides = 5
    private let flowSteps = 3 // Location, Genres, Notifications (Steps 1, 2, 3 in terms of flow progress)

    // MARK: - Navigation Logic
    // Progress bar runs from Location to Notifications
    private var progressStep: Int {
        return max(0, currentStep - 1)
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return true // AuthWelcome
        case 1: return true // Location
        case 2: return !localPreferences.selectedGenres.isEmpty // Genres
        case 3: return true // Notifications
        case 4: return true // Complete
        default: return false
        }
    }

    private func getButtonText() -> String {
        if isRequesting { return "PLEASE WAIT..." }

        switch currentStep {
        case 0: return "LOG IN / SIGN UP" // Handled by AuthWelcomeSlide
        case 1: return "CONTINUE"
        case 2: return localPreferences.selectedGenres.isEmpty ? "SELECT PREFERENCES" : "CONTINUE"
        case 3: return "CONTINUE"
        case 4: return "START EXPLORING"
        default: return "NEXT"
        }
    }

    private func getSkipText() -> String? {
        switch currentStep {
        case 1: return "skip" // Location
        case 2: return "skip" // Genres (always show)
        case 3: return "skip" // Notifications
        default: return nil
        }
    }

    private var showBackButton: Bool {
        return currentStep > 0 && currentStep < totalSlides - 1
    }

    private func handleBackButton() {
        withAnimation {
            if currentStep > 0 {
                currentStep -= 1
            }
        }
    }

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
                            // Show Progress Line
                            // Centered and shorter progress bar
                            HStack {
                                Spacer()
                                ProgressLineView(
                                    currentStep: progressStep - 1,
                                    totalSteps: flowSteps - 1,
                                    isStepCompleted: isCurrentStepValid
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
                                Button(action: { handleNextStep() }) {
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

                // Content Slides
                TabView(selection: $currentStep) {
                    // Step 0: Auth Welcome
                    AuthWelcomeSlide(onLogin: { handleNextStep() }, onExplore: { handleNextStep() })
                        .tag(0)

                    // Step 1: Location
                    LocationSlide()
                        .tag(1)

                    // Step 2: Genres
                    GenreSlide(
                        localPreferences: localPreferences,
                        tagViewModel: tagViewModel
                    )
                    .tag(2)

                    // Step 3: Notifications
                    NotificationSlide(localPreferences: localPreferences)
                        .tag(3)

                    // Step 4: Complete
                    CompleteSlide()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .allowsHitTesting(false) // Disable swiping
                .animation(.easeInOut(duration: 0.3), value: currentStep)

                Spacer()

                // Bottom Action Area (Only visible on content slides > 0)
                if currentStep > 0 {
                    VStack(spacing: 16) {
                        Button(action: { handleMainButton() }) {
                            Text(getButtonText().uppercased())
                                .appSecondary() // Use appSecondary for button text
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
                        .disabled(!canProceed())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .environmentObject(localPreferences)
    }

    // MARK: - Logic
    
    private func canProceed() -> Bool {
        if isRequesting { return false }
        if currentStep == 2 && localPreferences.selectedGenres.isEmpty { return false }
        return true
    }

    private func handleMainButton() {
        switch currentStep {
        case 3: // Notifications
            if !localPreferences.hasEnabledNotifications {
                requestNotifications()
            } else {
                handleNextStep()
            }
        case 4: // Complete
            completeOnboarding()
        default:
            handleNextStep()
        }
    }

    private func handleNextStep() {
        withAnimation {
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

    private func requestNotifications() {
        isRequesting = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    localPreferences.hasEnabledNotifications = true
                    handleNextStep()
                }
                isRequesting = false
            }
        }
    }
}

// MARK: - Step 0: Auth Welcome Slide
struct AuthWelcomeSlide: View {
    let onLogin: () -> Void
    let onExplore: () -> Void

    @State private var showingSignIn = false

    var body: some View {
        VStack(spacing: 0) {

            // Text Header
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
                        .frame(maxWidth: .infinity)
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
                        .frame(maxWidth: .infinity)
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
            // Placeholder Image, centered next to 'BURNER'
            Image("transparent") // Assuming this image is defined and available
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

            // Location buttons - centered, narrow pills
            VStack(spacing: 12) {
                Button(action: {
                    requestCurrentLocation()
                }) {
                    Text("Use Current Location")
                        .appSecondary()
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: 300)
                        .background(Color.white.opacity(0.15))
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
                    Text("Enter Location")
                        .appSecondary()
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: 300)
                        .background(Color.white.opacity(0.15))
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
            isProcessing = false
        }
    }
}

// MARK: - Slide 2: Genres
struct GenreSlide: View {
    @ObservedObject var localPreferences: LocalPreferences
    @ObservedObject var tagViewModel: TagViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 40)

            VStack(alignment: .leading, spacing: 0) {
                Text("What do you")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("like?")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }

            Text("Select your vibes. We'll curate the feed for you.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.top, 16)

            Spacer().frame(height: 32)

            if tagViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(tagViewModel.displayTags, id: \.self) { genre in
                        GenrePill(
                            title: genre,
                            isSelected: localPreferences.selectedGenres.contains(genre),
                            action: { toggleGenre(genre) }
                        )
                    }
                }
                .padding(.bottom, 20)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
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

// MARK: - Slide 3: Notifications
struct NotificationSlide: View {
    @ObservedObject var localPreferences: LocalPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("Stay")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
                    .padding(.bottom, -15)

                Text("Updated")
                    .font(.system(size: 48, weight: .bold))
                    .kerning(-1.5)
                    .foregroundColor(.white)
            }

            Text("Get notified about new events, ticket drops, and lineup announcements.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.top, 16)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Slide 4: Complete
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
                
                Image(systemName: "arrow.right")
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

// MARK: - Marquee Components (Reused)
struct MarqueeImageGrid: View {
    let events: [Event]
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                let shuffled = events.shuffled()
                let third = max(1, shuffled.count / 3)
                
                MarqueeRow(
                    events: Array(shuffled.prefix(third)),
                    direction: .left,
                    width: geo.size.width
                )
                
                MarqueeRow(
                    events: Array(shuffled.dropFirst(third).prefix(third)),
                    direction: .right,
                    width: geo.size.width
                )
                
                MarqueeRow(
                    events: Array(shuffled.dropFirst(third * 2)),
                    direction: .left,
                    width: geo.size.width
                )
            }
        }
        .drawingGroup()
    }
}

struct MarqueeRow: View {
    let events: [Event]
    let direction: Direction
    let width: CGFloat
    
    enum Direction { case left, right }
    
    @State private var offset: CGFloat = 0
    private let itemSize: CGFloat = 120
    
    var body: some View {
        let displayEvents = events.isEmpty ? [] : (events + events + events + events)
        
        HStack(spacing: 0) {
            ForEach(0..<displayEvents.count, id: \.self) { i in
                if i < displayEvents.count {
                    let event = displayEvents[i]
                    KFImage(URL(string: event.imageUrl))
                        .placeholder { Color.gray.opacity(0.2) }
                        .resizable()
                        .scaledToFill()
                        .frame(width: itemSize, height: itemSize)
                        .clipped()
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
        }
        .offset(x: offset)
        .frame(width: width, height: itemSize, alignment: .leading)
        .clipped()
        .onAppear {
            let totalWidth = CGFloat(displayEvents.count) * itemSize
            let duration = Double(displayEvents.count) * 2.0
            
            offset = direction == .left ? 0 : -totalWidth / 2
            
            withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                offset = direction == .left ? -totalWidth / 2 : 0
            }
        }
    }
}
