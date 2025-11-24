//
//  OnboardingFlowView.swift
//  burner
//
//  5-step onboarding flow: Welcome → Location → Genres → Notifications → Complete
//

import SwiftUI
import CoreLocation
import UserNotifications
import Kingfisher

struct OnboardingFlowView: View {
    @ObservedObject var onboardingManager: OnboardingManager
    @EnvironmentObject var appState: AppState

    @StateObject private var localPreferences = LocalPreferences()
    @StateObject private var locationManager = OnboardingLocationManager()

    @State private var currentStep = 0

    private let totalSteps = 5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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

            // Progress indicator (for steps 1-3 only)
            if currentStep > 0 && currentStep < 4 {
                VStack {
                    HStack(spacing: 4) {
                        ForEach(1...3, id: \.self) { index in
                            Rectangle()
                                .fill(currentStep >= index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 30, height: 3)
                                .clipShape(Capsule())
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

            VStack(spacing: 20) {
                Text("EXPERIENCE THE MUSIC")
                    .font(.custom("Avenir", size: 32).weight(.black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .tracking(1)
                    .padding(.horizontal, 40)

                Text("Discover events, buy tickets,\nand focus on what matters")
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)

            // Featured Events Carousel
            FeaturedEventsCarouselView(events: appState.eventViewModel.featuredEvents)
                .frame(height: 280)

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

// MARK: - Step 1: Location
struct LocationStep: View {
    @ObservedObject var locationManager: OnboardingLocationManager
    @ObservedObject var localPreferences: LocalPreferences

    @State private var isRequestingLocation = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("WHERE ARE YOU?")
                    .font(.custom("Avenir", size: 28).weight(.black))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("We'll show you events nearby")
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let locationName = localPreferences.locationName {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(locationName)
                            .font(.custom("Avenir", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
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
                        title: "SKIP",
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

            VStack(spacing: 20) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("WHAT DO YOU LIKE?")
                    .font(.custom("Avenir", size: 28).weight(.black))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Select your favorite genres")
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
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

                NavigationButton(
                    title: "SKIP",
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

            VStack(spacing: 20) {
                Image(systemName: "bell.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("STAY UPDATED")
                    .font(.custom("Avenir", size: 28).weight(.black))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Get notified about events,\ntickets, and reminders")
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if localPreferences.hasEnabledNotifications {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications enabled")
                            .font(.custom("Avenir", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
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
                        title: "SKIP",
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

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)

                Text("YOU'RE ALL SET!")
                    .font(.custom("Avenir", size: 32).weight(.black))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("Start exploring events\nand discover what's next")
                    .font(.custom("Avenir", size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
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

// Navigation Button
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
                .font(.custom("Avenir", size: 17).weight(.bold))
                .foregroundColor(style == .primary ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(style == .primary ? Color.white : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Genre Button
struct GenreButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Avenir", size: 14).weight(.semibold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.white : Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Featured Events Carousel View
struct FeaturedEventsCarouselView: View {
    let events: [Event]

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 16) {
            if events.isEmpty {
                // Placeholder when no featured events
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "music.note")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Loading events...")
                                .font(.custom("Avenir", size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
                    .padding(.horizontal, 40)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(events.prefix(5).enumerated()), id: \.element.id) { index, event in
                        FeaturedEventCard(event: event)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 220)

                // Pagination dots
                HStack(spacing: 8) {
                    ForEach(0..<min(events.count, 5), id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}

// Featured Event Card
struct FeaturedEventCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event image
            KFImage(URL(string: event.imageUrl))
                .placeholder {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.custom("Avenir", size: 16).weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(event.venue)
                    .font(.custom("Avenir", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 40)
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
