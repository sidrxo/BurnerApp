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

    // Updated Total Steps: AuthWelcome -> Genres -> Notifications -> Complete
    // Total screens is 4: AuthWelcome (0) -> Genres(1) -> Notifications(2) -> Complete(3)
    private let totalSlides = 4 // AuthWelcome (0) -> Genres(1) -> Notifications(2) -> Complete(3)
    private let flowSteps = 2 // Genres, Notifications (Steps 1, 2 in terms of flow progress)

    // MARK: - Navigation Logic
    // Progress bar runs from Genres to Notifications
    private var progressStep: Int {
        return max(0, currentStep - 1)
    }

    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0: return true // AuthWelcome
        case 1: return !localPreferences.selectedGenres.isEmpty // Genres
        case 2: return true // Notifications
        case 3: return true // Complete
        default: return false
        }
    }

    private func getButtonText() -> String {
        if isRequesting { return "PLEASE WAIT..." }

        switch currentStep {
        case 0: return "LOG IN / SIGN UP" // Handled by AuthWelcomeSlide
        case 1: return localPreferences.selectedGenres.isEmpty ? "SELECT PREFERENCES" : "CONTINUE"
        case 2: return "CONTINUE"
        case 3: return "START EXPLORING"
        default: return "NEXT"
        }
    }

    private func getSkipText() -> String? {
        switch currentStep {
        case 1: return localPreferences.selectedGenres.isEmpty ? "Skip for now" : nil
        case 2: return !localPreferences.hasEnabledNotifications ? "Skip for now" : nil
        default: return nil
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Area with Skip Button
                ZStack {
                    // Center: Logo or Progress Indicator
                    VStack(spacing: 0) {
                        Spacer().frame(height: 20)

                        if currentStep == 0 {
                            // Show Auth Header with Logo
                            AuthHeader()
                        } else if currentStep > 0 && currentStep < totalSlides - 1 {
                            // Show Progress Line (Starts from Genres, ends before Complete)
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

                    // Top Right: Skip Button
                    if let skipText = getSkipText() {
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { handleNextStep() }) {
                                    Text(skipText)
                                        .appSecondary()
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                .padding(.trailing, 20)
                                .padding(.top, 10)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(height: 50) // Increased height to accommodate the logo/progress

                // Content Slides
                TabView(selection: $currentStep) {
                    // Step 0: Auth Welcome
                    AuthWelcomeSlide(onLogin: { handleNextStep() }, onExplore: { handleNextStep() })
                        .tag(0)

                    // Step 1: Genres
                    GenreSlide(
                        localPreferences: localPreferences,
                        tagViewModel: tagViewModel
                    )
                    .tag(1)

                    // Step 2: Notifications
                    NotificationSlide(localPreferences: localPreferences)
                        .tag(2)

                    // Step 3: Complete
                    CompleteSlide()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .gesture(DragGesture(), including: .all) // Disable swiping only
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
        if currentStep == 1 && localPreferences.selectedGenres.isEmpty { return false }
        return true
    }

    private func handleMainButton() {
        switch currentStep {
        case 2: // Notifications
            if !localPreferences.hasEnabledNotifications {
                requestNotifications()
            } else {
                handleNextStep()
            }
        case 3: // Complete
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


// MARK: - Slide 1: Genres
struct GenreSlide: View {
    @ObservedObject var localPreferences: LocalPreferences
    @ObservedObject var tagViewModel: TagViewModel
    
    private let columns = [GridItem(.adaptive(minimum: 90, maximum: 180), spacing: 12)]

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
                LazyVGrid(columns: columns, spacing: 12) {
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
    @State private var selectedTypes: Set<String> = ["Tickets", "Lineups"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 40)

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
            
            Text("Choose what you want to be notified about.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
                .padding(.top, 16)

            Spacer().frame(height: 32)
            
            VStack(spacing: 12) {
                NotificationToggleRow(
                    icon: "ticket.fill",
                    text: "Ticket Drops",
                    isSelected: selectedTypes.contains("Tickets")
                ) { toggleType("Tickets") }
                
                NotificationToggleRow(
                    icon: "music.mic",
                    text: "Lineup Announcements",
                    isSelected: selectedTypes.contains("Lineups")
                ) { toggleType("Lineups") }
                
                NotificationToggleRow(
                    icon: "exclamationmark.triangle.fill",
                    text: "Venue Changes",
                    isSelected: selectedTypes.contains("Venue")
                ) { toggleType("Venue") }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private func toggleType(_ type: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
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
            .padding(.horizontal, 12) // Reduced from 20
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

struct NotificationToggleRow: View {
    let icon: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.3))
            }
            .padding(16)
            .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
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
