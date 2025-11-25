//
//  OnboardingFlowView.swift
//  burner
//
//  5-step onboarding flow: Welcome → Location → Genres → Notifications → Complete
//  Design: Monochrome black & white system with premium feel
//

import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher
import Combine

// MARK: - Design System
struct OnboardingColors {
    static let background = Color.black
    static let foreground = Color.white
    static let muted = Color(white: 0.15)
    static let mutedForeground = Color(white: 0.6)
    static let border = Color(white: 0.2)
    static let pillBg = Color(white: 0.15)
    static let pillActive = Color.white
    static let pillActiveForeground = Color.black
}

struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var locationManager = OnboardingLocationManager()

    @State private var currentStep = 0

    private let totalSteps = 5

    var body: some View {
        ZStack {
            OnboardingColors.background.ignoresSafeArea()

            TabView(selection: $currentStep) {
                // Step 0: Welcome + Featured Events Carousel
                WelcomeStep()
                    .tag(0)

                // Step 1: Location
                LocationStep(
                    locationManager: locationManager,
                    localPreferences: localPreferences
                )
                .tag(1)

                // Step 2: Genre Selection
                GenreSelectionStep(
                    localPreferences: localPreferences
                )
                .tag(2)

                // Step 3: Notifications
                NotificationsStep(
                    localPreferences: localPreferences
                )
                .tag(3)

                // Step 4: Complete
                CompleteStep(
                    onComplete: {
                        onboardingManager.completeOnboarding()
                    }
                )
                .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Minimalist progress indicator (for steps 1-3 only)
            if currentStep > 0 && currentStep < 4 {
                VStack {
                    HStack(spacing: 6) {
                        ForEach(1...3, id: \.self) { index in
                            Capsule()
                                .fill(currentStep >= index ? OnboardingColors.foreground : OnboardingColors.border)
                                .frame(width: currentStep == index ? 40 : 24, height: 2)
                                .animation(.spring(response: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 60)

                    Spacer()
                }
            }
        }
        .environmentObject(localPreferences)
    }
}

// MARK: - Step 0: Welcome + Featured Events Carousel
struct WelcomeStep: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            VStack(spacing: 16) {
                Text("Welcome to\nBurner.")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(OnboardingColors.foreground)
                    .multilineTextAlignment(.leading)
                    .tracking(1.5)
                    .padding(.horizontal, 40)

                Text("Discover events, buy tickets,\nand focus on what matters")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(OnboardingColors.mutedForeground)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 50)

            // Featured Events Carousel - Tall centered card with arced layout
            ArcedCarouselView(events: appState.eventViewModel.featuredEvents)
                .frame(height: 450)

            Spacer()

            NavigationButton(
                title: "GET STARTED",
                style: .primary,
                action: {}
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Arced Carousel View
struct ArcedCarouselView: View {
    let events: [Event]
    
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    private let cardWidth: CGFloat = 280
    private let cardHeight: CGFloat = 380
    private let spacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let centerX = screenWidth / 2
            
            ZStack {
                if events.isEmpty {
                    // Minimalist placeholder
                    RoundedRectangle(cornerRadius: 24)
                        .fill(OnboardingColors.muted)
                        .frame(width: cardWidth, height: cardHeight)
                        .overlay(
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(OnboardingColors.border)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 32, weight: .light))
                                            .foregroundColor(OnboardingColors.mutedForeground)
                                    )
                                Text("Loading events...")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(OnboardingColors.mutedForeground)
                            }
                        )
                        .position(x: centerX, y: geometry.size.height / 2)
                } else {
                    ForEach(Array(events.prefix(5).enumerated()), id: \.element.id) { index, event in
                        TallEventCard(event: event)
                            .frame(width: cardWidth, height: cardHeight)
                            .modifier(
                                ArcedCardModifier(
                                    index: index,
                                    currentIndex: currentIndex,
                                    dragOffset: dragOffset,
                                    centerX: centerX,
                                    cardWidth: cardWidth,
                                    spacing: spacing
                                )
                            )
                    }
                }
                
                // Minimalist pagination dots
                VStack {
                    Spacer()
                    
                    if !events.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(0..<min(events.count, 5), id: \.self) { index in
                                Capsule()
                                    .fill(currentIndex == index ? OnboardingColors.foreground : OnboardingColors.border)
                                    .frame(width: currentIndex == index ? 20 : 6, height: 2)
                                    .animation(.spring(response: 0.3), value: currentIndex)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if value.translation.width < -threshold && currentIndex < min(events.count, 5) - 1 {
                                currentIndex += 1
                            } else if value.translation.width > threshold && currentIndex > 0 {
                                currentIndex -= 1
                            }
                            dragOffset = 0
                        }
                        
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
            )
        }
    }
}

// MARK: - Arced Card Modifier
struct ArcedCardModifier: ViewModifier {
    let index: Int
    let currentIndex: Int
    let dragOffset: CGFloat
    let centerX: CGFloat
    let cardWidth: CGFloat
    let spacing: CGFloat
    
    func body(content: Content) -> some View {
        let offset = CGFloat(index - currentIndex)
        let totalOffset = (offset * (cardWidth + spacing)) + dragOffset
        
        // Calculate arc effect
        let normalizedOffset = abs(totalOffset) / (cardWidth + spacing)
        let arcHeight = min(normalizedOffset * 40, 60) // Max arc of 60pt
        
        // Calculate scale
        let isCentered = index == currentIndex && abs(dragOffset) < 10
        let scale: CGFloat = isCentered ? 1.0 : 0.85
        
        // Calculate opacity
        let opacity: Double = isCentered ? 1.0 : 0.6
        
        // Calculate rotation for arc effect
        let rotation: Double = totalOffset / cardWidth * 8 // Slight rotation
        
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(
                x: totalOffset,
                y: arcHeight
            )
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0)
            )
            .position(x: centerX, y: 190)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
    }
}

// MARK: - Tall Event Card
struct TallEventCard: View {
    let event: Event
    
    var body: some View {
        VStack(spacing: 0) {
            // Event image with subtle overlay
            ZStack(alignment: .bottom) {
                KFImage(URL(string: event.imageUrl))
                    .placeholder {
                        Rectangle()
                            .fill(OnboardingColors.muted)
                            .overlay(
                                Circle()
                                    .fill(OnboardingColors.border)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 24, weight: .light))
                                            .foregroundColor(OnboardingColors.mutedForeground)
                                    )
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipped()
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.clear,
                        OnboardingColors.background.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .frame(width: 280, height: 280)
            
            // Event details section - monochrome styling
            VStack(alignment: .leading, spacing: 12) {
                Text(event.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(OnboardingColors.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(OnboardingColors.mutedForeground)
                        
                        Text(event.venue)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(OnboardingColors.mutedForeground)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(OnboardingColors.mutedForeground)
                        
                        Text("12th Nov 2025")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(OnboardingColors.mutedForeground)
                            .lineLimit(1)
                    }
                }
            }
            .padding(20)
            .frame(width: 280, alignment: .leading)
            .background(OnboardingColors.muted)
        }
        .background(OnboardingColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(OnboardingColors.border, lineWidth: 1)
        )
        .shadow(color: OnboardingColors.background.opacity(0.5), radius: 30, x: 0, y: 15)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        return dateString
    }
}

// MARK: - Step 1: Location
struct LocationStep: View {
    @ObservedObject var locationManager: OnboardingLocationManager
    @ObservedObject var localPreferences: LocalPreferences

    @State private var isRequestingLocation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon with circular background
                Circle()
                    .fill(OnboardingColors.muted)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(OnboardingColors.foreground)
                    )

                VStack(spacing: 12) {
                    Text("WHERE ARE YOU?")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingColors.foreground)
                        .tracking(1.5)

                    Text("We'll show you events nearby")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(OnboardingColors.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                if let locationName = localPreferences.locationName {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OnboardingColors.foreground)
                            .font(.system(size: 16))
                        Text(locationName)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(OnboardingColors.foreground)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(OnboardingColors.muted)
                    .clipShape(Capsule())
                    .padding(.top, 8)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if localPreferences.locationName == nil {
                    NavigationButton(
                        title: isRequestingLocation ? "REQUESTING..." : "ENABLE LOCATION",
                        style: .primary,
                        action: {
                            requestLocation()
                        }
                    )
                    .disabled(isRequestingLocation)

                    NavigationButton(
                        title: "SKIP FOR NOW",
                        style: .secondary,
                        action: {}
                    )
                } else {
                    NavigationButton(
                        title: "CONTINUE",
                        style: .primary,
                        action: {}
                    )
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    private func requestLocation() {
        isRequestingLocation = true
        locationManager.requestLocation { success in
            if success, let location = locationManager.currentLocation {
                // Reverse geocode
                locationManager.reverseGeocode(location: location) { placemark in
                    if let placemark = placemark {
                        let city = placemark.locality ?? "Unknown"
                        let country = placemark.country ?? ""
                        let locationName = country.isEmpty ? city : "\(city), \(country)"

                        localPreferences.locationName = locationName
                        localPreferences.locationLat = location.coordinate.latitude
                        localPreferences.locationLon = location.coordinate.longitude
                    }
                    isRequestingLocation = false
                }
            } else {
                isRequestingLocation = false
            }
        }
    }
}

// MARK: - Step 2: Genre Selection
struct GenreSelectionStep: View {
    @ObservedObject var localPreferences: LocalPreferences

    private let genres = ["Music", "Comedy", "Theater", "Sports", "Film", "Talks", "Wellness", "Festivals", "Family"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon with circular background
                Circle()
                    .fill(OnboardingColors.muted)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "music.note.list")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(OnboardingColors.foreground)
                    )

                VStack(spacing: 12) {
                    Text("WHAT DO YOU LIKE?")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingColors.foreground)
                        .tracking(1.5)

                    Text("Select your favorite genres")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(OnboardingColors.mutedForeground)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 40)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(genres, id: \.self) { genre in
                    GenreButton(
                        title: genre,
                        isSelected: localPreferences.selectedGenres.contains(genre),
                        action: {
                            toggleGenre(genre)
                        }
                    )
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                NavigationButton(
                    title: "CONTINUE",
                    style: .primary,
                    action: {}
                )
                .opacity(localPreferences.selectedGenres.isEmpty ? 0.5 : 1.0)

                NavigationButton(
                    title: "SKIP FOR NOW",
                    style: .secondary,
                    action: {}
                )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    private func toggleGenre(_ genre: String) {
        if localPreferences.selectedGenres.contains(genre) {
            localPreferences.selectedGenres.removeAll { $0 == genre }
        } else {
            localPreferences.selectedGenres.append(genre)
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Step 3: Notifications
struct NotificationsStep: View {
    @ObservedObject var localPreferences: LocalPreferences

    @State private var isRequestingPermission = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon with circular background
                Circle()
                    .fill(OnboardingColors.muted)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "bell.circle.fill")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(OnboardingColors.foreground)
                    )

                VStack(spacing: 12) {
                    Text("STAY UPDATED")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingColors.foreground)
                        .tracking(1.5)

                    Text("Get notified about events,\ntickets, and reminders")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(OnboardingColors.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                if localPreferences.hasEnabledNotifications {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(OnboardingColors.foreground)
                            .font(.system(size: 16))
                        Text("Notifications enabled")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(OnboardingColors.foreground)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(OnboardingColors.muted)
                    .clipShape(Capsule())
                    .padding(.top, 8)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !localPreferences.hasEnabledNotifications {
                    NavigationButton(
                        title: isRequestingPermission ? "REQUESTING..." : "ENABLE NOTIFICATIONS",
                        style: .primary,
                        action: {
                            requestNotificationPermission()
                        }
                    )
                    .disabled(isRequestingPermission)

                    NavigationButton(
                        title: "SKIP FOR NOW",
                        style: .secondary,
                        action: {}
                    )
                } else {
                    NavigationButton(
                        title: "CONTINUE",
                        style: .primary,
                        action: {}
                    )
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    private func requestNotificationPermission() {
        isRequestingPermission = true

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    localPreferences.hasEnabledNotifications = true
                }
                isRequestingPermission = false
            }
        }
    }
}

// MARK: - Step 4: Complete
struct CompleteStep: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Success icon with animated circle
                Circle()
                    .fill(OnboardingColors.foreground)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(OnboardingColors.background)
                    )

                VStack(spacing: 12) {
                    Text("YOU'RE ALL SET!")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(OnboardingColors.foreground)
                        .tracking(1.5)

                    Text("Start exploring events\nand discover what's next")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(OnboardingColors.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            Spacer()

            NavigationButton(
                title: "LET'S GO",
                style: .primary,
                action: {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    onComplete()
                }
            )
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Supporting Components

// Navigation Button - Monochrome Design
struct NavigationButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void

    enum ButtonStyle {
        case primary
        case secondary
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(style == .primary ? OnboardingColors.background : OnboardingColors.foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(style == .primary ? OnboardingColors.foreground : OnboardingColors.muted)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style == .primary ? Color.clear : OnboardingColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Genre Button - Pill Style
struct GenreButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? OnboardingColors.background : OnboardingColors.foreground)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(isSelected ? OnboardingColors.foreground : OnboardingColors.muted)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.clear : OnboardingColors.border, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Manager
class OnboardingLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private var locationCompletion: ((Bool) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestLocation(completion: @escaping (Bool) -> Void) {
        locationCompletion = completion

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    func reverseGeocode(location: CLLocation, completion: @escaping (CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("❌ Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(placemarks?.first)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationCompletion?(false)
            locationCompletion = nil
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationCompletion?(true)
        locationCompletion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager error: \(error.localizedDescription)")
        locationCompletion?(false)
        locationCompletion = nil
    }
}
