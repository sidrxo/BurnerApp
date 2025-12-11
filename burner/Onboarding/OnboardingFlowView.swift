// OnboardingFlowView.swift - OPTIMIZED FOR INSTANT LOAD
// Shows cached images immediately, loads fresh data in background

import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher
import Combine



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


struct OnboardingFlowView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var tagViewModel = TagViewModel()

    @State private var currentStep = 0
    @State private var isRequesting = false
    @State private var isCompleting = false

    // Total screens: AuthWelcome (0) -> Location(1) -> Genres(2) -> Notifications(3) -> Complete(4)
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
                                    .appFont(size: 20, weight: .medium)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 44, height: 44)
                            }
                            .padding(.top, currentStep == 0 ? 0 : 4)
                            .padding(.leading, 20)
                            Spacer()
                        }
                    }

                    // 3. Top Right: Skip Button
                    if let skipText = getSkipText() {
                        HStack {
                            Spacer()
                            Button(action: { handleSkip() }) {
                                Text(skipText)
                                    .appFont(size: 17, weight: .semibold)
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                            }
                            .padding(.top, currentStep == 0 ? 0 : 4)
                            .padding(.trailing, 20)
                        }
                    }
                }
                .safeAreaPadding(.top)
                .frame(height: 60)
                .padding(.bottom, 4)

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
                                CompleteSlide(
                                    onComplete: { completeOnboarding() },
                                    isCurrentSlide: step == currentStep
                                )
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
        guard !isCompleting else { return }
        isCompleting = true

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        savePreferences()

        onboardingManager.completeOnboarding()
    }

    private func savePreferences() {
        localPreferences.saveToUserDefaults()

        Task {
            let syncService = PreferencesSyncService()
        }
    }
}

// MARK: - Step 0: Auth Welcome Slide (uses Event Mosaic)

struct AuthWelcomeSlide: View {
    let onLogin: () -> Void
    let onExplore: () -> Void

    @State private var showingSignIn = false
    @EnvironmentObject var appState: AppState

    // Build event image URLs from your appState.eventViewModel.events, filtering for valid URLs
    private var eventImageURLs: [URL] {
        let events = appState.eventViewModel.events

        // Find the top featured event (priority 0)
        let topFeatured = events.first { event in
            event.isFeatured && event.featuredPriority == 0 && !event.imageUrl.isEmpty
        }

        // Get other events (excluding the top featured one)
        let otherEvents = events.filter { event in
            guard !event.imageUrl.isEmpty else { return false }
            // Exclude the top featured event
            if let topFeatured = topFeatured, event.id == topFeatured.id {
                return false
            }
            return true
        }

        // Build the 3x3 grid with top featured in center (index 4)
        var gridUrls: [URL?] = Array(repeating: nil, count: 9)

        // Place top featured event in center (index 4)
        if let topFeatured = topFeatured, let url = URL(string: topFeatured.imageUrl) {
            gridUrls[4] = url
        }

        // Fill remaining positions with other events
        let otherUrls = otherEvents.compactMap { URL(string: $0.imageUrl) }
        var otherIndex = 0
        for i in 0..<9 {
            if i == 4 { continue } // Skip center position
            if otherIndex < otherUrls.count {
                gridUrls[i] = otherUrls[otherIndex]
                otherIndex += 1
            }
        }

        return gridUrls.compactMap { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ✅ OPTIMIZED: Always show mosaic immediately, even if loading
            EventMosaicCarousel(eventImages: eventImageURLs)
                .padding(.top, 24)

            // Header — keep the same visual hierarchy
            VStack(spacing: 0) {
                TightHeaderText("MEET ME IN THE", "MOMENT", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
            .padding(.bottom, 22)

            // Buttons
            VStack(spacing: 14) {
                BurnerButton("SIGN UP/IN", style: .primary, maxWidth: 200) {
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
                .frame(minHeight: 40)
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

// MARK: - EventMosaicCarousel: Shows shimmer placeholders while loading
struct EventMosaicCarousel: View {
    let eventImages: [URL]

    private let rowOneMax = 3
    private let rowTwoMax = 3
    private let rowThreeMax = 3
    
    private var totalRequiredImages: Int {
        rowOneMax + rowTwoMax + rowThreeMax
    }
    
    private var uniqueImages: [URL] {
        Array(eventImages.prefix(totalRequiredImages))
    }
    
    private let constantOffset: CGFloat = 30
    private let mosaicHeight: CGFloat = 134 * 3 + 8 * 2

    var body: some View {
        // ✅ OPTIMIZED: Show shimmer placeholders immediately if no images
        if eventImages.isEmpty {
            // Show shimmer grid instead of loading text
            ShimmerMosaicGrid()
                .frame(height: mosaicHeight)
        } else {
            VStack(spacing: 8) {
                // Row 1
                EventStaticRow(
                    urls: Array(uniqueImages.prefix(rowOneMax)),
                    maxCards: rowOneMax
                )
                .frame(height: 134)
                .offset(x: constantOffset)

                // Row 2
                EventStaticRow(
                    urls: Array(uniqueImages.dropFirst(rowOneMax).prefix(rowTwoMax)),
                    maxCards: rowTwoMax
                )
                .frame(height: 134)
                .offset(x: constantOffset)

                // Row 3
                EventStaticRow(
                    urls: Array(uniqueImages.dropFirst(rowOneMax + rowTwoMax).prefix(rowThreeMax)),
                    maxCards: rowThreeMax
                )
                .frame(height: 134)
                .offset(x: constantOffset)
            }
            .padding(.horizontal, 12)
            .rotationEffect(.degrees(-6))
            .frame(height: mosaicHeight)
            .mask(
                VStack(spacing: 0) {
                    Rectangle()
                        .frame(height: mosaicHeight * 0.6)
                        .foregroundColor(.white)
                    
                    LinearGradient(
                        gradient: Gradient(colors: [.white, .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
        }
    }
}

// ✅ NEW: Shimmer placeholder grid
struct ShimmerMosaicGrid: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<3) { _ in
                HStack(spacing: 8) {
                    Spacer()
                    ForEach(0..<3) { _ in
                        ShimmerCard()
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .rotationEffect(.degrees(-6))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

struct ShimmerCard: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 134, height: 134)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Rest of supporting views remain the same...
// [Include all other views from the previous file: AuthHeader, LocationSlide, GenreSlide, etc.]




// MARK: - Top Header (Auth and Logo)
struct AuthHeader: View {
    var body: some View {
        HStack {
            Spacer()
            Image("transparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                // Reduced padding to account for safeAreaPadding in parent
                .padding(.top, 20)
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
            // Reduced to provide more vertical space
            Color.clear.frame(height: 40)

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
                                .appSecondary(weight: .bold)
                        }

                        Text(detectedCity ?? "CURRENT LOCATION")
                            .appButton()
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
                            .appSecondary(weight: .bold)

                        Text("ENTER CITY")
                            .appButton()
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
        // 👇 MODIFIED SHEET PRESENTATION TO PASS AUTO-ADVANCE LOGIC
        .sheet(isPresented: $showingManualEntry) {
            ManualCityEntryView(
                locationManager: appState.userLocationManager,
                onDismiss: {
                    // ManualCityEntryView calls this after the UX delay (0.6s)
                    // and after saving the location. We just dismiss the modal.
                    showingManualEntry = false
                    // Since the location is now set and saved in UserDefaults,
                    // the onChange handler below will catch the update and proceed.
                }
            )
        }
        // This onChange listener now handles both current location and manual entry
        .onChange(of: appState.userLocationManager.savedLocation) { _, newLocation in
            if let location = newLocation {
                localPreferences.locationName = location.name
                localPreferences.locationLat = location.latitude
                localPreferences.locationLon = location.longitude
                
                // Set the detected city for the button and trigger the next step.
                detectedCity = location.name.uppercased()
                
                // Introduce a small delay to allow the `detectedCity` update to flash
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Check if the manual entry sheet is still presented to prevent double-advance
                    if !showingManualEntry {
                        onLocationSet()
                    }
                }
            }
        }
    }
// ... (rest of LocationSlide implementation remains unchanged)
    private func requestCurrentLocation() {
        isProcessing = true
        appState.userLocationManager.requestCurrentLocation { result in
            DispatchQueue.main.async {
                isProcessing = false

                // The logic to handle location setting and calling onLocationSet() is
                // now moved to the .onChange(of: appState.userLocationManager.savedLocation) handler
                // to unify the flow for both current location and manual entry.
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
            // Reduced to provide more vertical space
            Color.clear.frame(height: 40)

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

            Group {
                if !localPreferences.selectedGenres.isEmpty {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onContinue()
                    }) {
                        Image(systemName: "arrow.right")
                            .appSectionHeader()
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
            // Reduced to provide more vertical space
            Color.clear.frame(height: 40)

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

    // Externally-set to know when visible
    var isCurrentSlide: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .appFont(size: 50, weight: .bold)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 32)

            VStack(spacing: 0) {
                TightHeaderText("YOU'RE", "IN!", alignment: .center)
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
        .onChange(of: isCurrentSlide) { oldValue, newValue in
            guard newValue == true, !hasTriggeredCompletion else {
                return
            }

            hasTriggeredCompletion = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        }
    }
}

// MARK: - --- Event Mosaic Components ---

// EventStaticRow (A static row of KFCarouselCard)
struct EventStaticRow: View {
    let urls: [URL]
    let cardSize: CGSize = KFCarouselCard.size
    let spacing: CGFloat = 8
    let maxCards: Int // Property to limit static display

    private var displayedUrls: [URL] {
        // Only show up to maxCards
        Array(urls.prefix(maxCards))
    }

    var body: some View {
        GeometryReader { geo in
            if urls.isEmpty {
                // Placeholder
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .frame(height: cardSize.height)
            } else {
                HStack(spacing: spacing) {
                    // PUSHES CONTENT TO THE RIGHT
                    Spacer(minLength: 0)
                    
                    ForEach(displayedUrls.indices, id: \.self) { i in
                        KFCarouselCard(url: displayedUrls[i])
                    }
                }
                // Alignment is explicitly set to trailing
                .frame(width: geo.size.width, height: cardSize.height, alignment: .trailing)
            }
        }
        .frame(height: cardSize.height)
    }
}

// EventMosaicCarousel: stacks three static rows to form mosaic (3x3 grid)


// MARK: - Supporting Views and Layouts (FlowLayout, GenrePill)


struct GenrePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title.lowercased())
                    .appBody()
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

// MARK: - --- Event Mosaic Components ---
struct KFCarouselCard: View {
    let url: URL?
    
    // Maintain square size and rounded corners (16)
    static let size = CGSize(width: 134, height: 134)
    
    var body: some View {
        KFImage(url)
            .placeholder {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: Self.size.width, height: Self.size.height)
            }
            .retry(maxCount: 1, interval: .seconds(1))
            .resizable()
            .scaledToFill()
            .frame(width: Self.size.width, height: Self.size.height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
    }
    
    
}
