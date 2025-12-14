import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher
import Combine

struct OnboardingFlowView: View {
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var tagViewModel = TagViewModel()

    @State private var currentStep = 0
    @State private var isRequesting = false
    @State private var isCompleting = false
    @State private var isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

    private let totalSlides = 5
    private let flowSteps = 3

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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    VStack(spacing: 0) {
                        if currentStep == 0 {
                            AuthHeader()
                        } else if currentStep > 0 && currentStep < totalSlides - 1 {
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
                            .padding(.top, currentStep == 0 ? 0 : 4)
                            .padding(.leading, 20)
                            Spacer()
                        }
                    }

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

                ZStack {
                    ForEach(0..<totalSlides, id: \.self) { step in
                        Group {
                            switch step {
                            case 0:
                                AuthWelcomeSlide(
                                    onLogin: { handleNextStep() },
                                    onExplore: { handleNextStep() },
                                    isFirstLaunch: isFirstLaunch
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
        .onAppear {
            if isFirstLaunch {
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SkipOnboardingToExplore"))) { _ in
            guard onboardingManager.shouldShowOnboarding else { return }
            completeOnboarding()
        }
    }

    private func slideOffset(for step: Int) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth * CGFloat(step - currentStep)
    }

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

        onboardingManager.completeOnboarding()
    }
}

struct AuthWelcomeSlide: View {
    let onLogin: () -> Void
    let onExplore: () -> Void
    let isFirstLaunch: Bool

    @State private var showingSignIn = false
    @EnvironmentObject var appState: AppState

    private var eventImageURLs: [URL] {
        appState.eventViewModel.events.compactMap {
            guard !$0.imageUrl.isEmpty, let url = URL(string: $0.imageUrl) else {
                return nil
            }
            return url
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            
            EventMosaicCarousel(eventImages: eventImageURLs)
                .padding(.top, 24)

            VStack(spacing: 0) {
                TightHeaderText("JOIN THE", "MOVEMENT", alignment: .center)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 120)
            .padding(.bottom, 22)

            VStack(spacing: 14) {
                BurnerButton("SIGN UP/IN", style: .primary, maxWidth: 200) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingSignIn = true
                }
                .buttonStyle(PlainButtonStyle())

                BurnerButton("EXPLORE", style: .secondary, maxWidth: 160) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("SkipOnboardingToExplore"), object: nil)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 40)

            Spacer()
                .frame(minHeight: 40)
        }
        .sheet(isPresented: $showingSignIn) {
            SignInSheetView(showingSignIn: $showingSignIn, isOnboarding: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserSignedIn"))) { _ in
            showingSignIn = false
            onLogin()
        }
    }
}

struct AuthHeader: View {
    var body: some View {
        HStack {
            Spacer()
            Image("transparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .padding(.top, 20)
            Spacer()
        }
    }
}

struct LocationSlide: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localPreferences: LocalPreferences
    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var detectedCity: String?

    let onLocationSet: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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

                    detectedCity = savedLocation.name.uppercased()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onLocationSet()
                    }
                }
            }
        }
    }
}

struct GenreSlide: View {
    @ObservedObject var localPreferences: LocalPreferences
    @ObservedObject var tagViewModel: TagViewModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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

struct NotificationsSlide: View {
    @EnvironmentObject var localPreferences: LocalPreferences
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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

            VStack(spacing: 14) {
                BurnerButton("I'M IN", style: .primary, maxWidth: 130) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    requestNotifications()
                }
                .buttonStyle(PlainButtonStyle())

                BurnerButton("NO", style: .secondary, maxWidth: 100) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    localPreferences.hasEnabledNotifications = false
                    onContinue()
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
                localPreferences.hasEnabledNotifications = granted
                onContinue()
            }
        }
    }
}

struct CompleteSlide: View {
    let onComplete: () -> Void
    @State private var hasTriggeredCompletion = false

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

struct KFCarouselCard: View {
    let url: URL?
    @State private var isLoaded = false

    static let size = CGSize(width: 134, height: 134)

    var body: some View {
        KFImage.url(url)
            .placeholder {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: Self.size.width, height: Self.size.height)
            }
            .onSuccess { _ in
                withAnimation(.easeIn(duration: 0.4)) {
                    isLoaded = true
                }
            }
            .fade(duration: 0.4)
            .retry(maxCount: 2, interval: .seconds(0.5))
            .resizable()
            .scaledToFill()
            .frame(width: Self.size.width, height: Self.size.height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 3)
            .opacity(isLoaded ? 1 : 0)
    }
}

struct EventStaticRow: View {
    let urls: [URL]
    let cardSize: CGSize = KFCarouselCard.size
    let spacing: CGFloat = 8
    let maxCards: Int

    private var displayedUrls: [URL] {
        Array(urls.prefix(maxCards))
    }

    var body: some View {
        GeometryReader { geo in
            if urls.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                    .frame(height: cardSize.height)
            } else {
                HStack(spacing: spacing) {
                    Spacer(minLength: 0)
                    
                    ForEach(displayedUrls.indices, id: \.self) { i in
                        KFCarouselCard(url: displayedUrls[i])
                    }
                }
                .frame(width: geo.size.width, height: cardSize.height, alignment: .trailing)
            }
        }
        .frame(height: cardSize.height)
    }
}

struct EventMosaicCarousel: View {
    let eventImages: [URL]

    private let rowOneMax = 4
    private let rowTwoMax = 4
    private let rowThreeMax = 4
    
    private var totalRequiredImages: Int {
        rowOneMax + rowTwoMax + rowThreeMax
    }
    
    private var uniqueImages: [URL] {
        Array(eventImages.prefix(totalRequiredImages))
    }
    
    private let constantOffset: CGFloat = 30
    private let mosaicHeight: CGFloat = 134 * 3 + 8 * 2

    var body: some View {
        if eventImages.isEmpty {
            Rectangle()
                .fill(Color.white.opacity(0.03))
                .frame(height: 180)
                .overlay {
                    ProgressView().tint(.white)
                }
        } else {
            VStack(spacing: 8) {
                EventStaticRow(
                    urls: Array(uniqueImages.prefix(rowOneMax)),
                    maxCards: rowOneMax
                )
                .frame(height: 134)
                .offset(x: constantOffset)

                EventStaticRow(
                    urls: Array(uniqueImages.dropFirst(rowOneMax).prefix(rowTwoMax)),
                    maxCards: rowTwoMax
                )
                .frame(height: 134)
                .offset(x: constantOffset)

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
