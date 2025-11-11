import SwiftUI
import CoreLocation

struct LocationPromptModal: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingManualEntry = false
    @State private var cityInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isRequestingLocation = false

    let onDismiss: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                // Handle bar - more prominent like Apple Maps
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height > 50 && !isRequestingLocation && !isLoading {
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        onDismiss()
                                    }
                                }
                            }
                    )

                if showingManualEntry {
                    manualEntryView
                } else {
                    defaultView
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(red: 28/255, green: 28/255, blue: 30/255))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom))
        .onChange(of: locationManager.currentLocation) { oldValue, newValue in
            if isRequestingLocation, let location = newValue {
                print("📍 LocationPromptModal: Location received: \(location.coordinate.latitude), \(location.coordinate.longitude)")

                locationManager.validateUKLocation(coordinate: location.coordinate) { isUK in
                    Task { @MainActor in
                        if isUK {
                            print("📍 LocationPromptModal: Location is in UK, saving...")
                            isRequestingLocation = false
                            locationManager.saveLocationPreference(.coordinate(location.coordinate))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss()
                            }
                        } else {
                            isRequestingLocation = false
                            locationManager.errorMessage = "Your current location is outside the UK"
                        }
                    }
                }
            }
        }
        .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
            print("📍 LocationPromptModal: Auth status changed from \(oldValue.rawValue) to \(newValue.rawValue)")

            if newValue == .denied || newValue == .restricted {
                isRequestingLocation = false
                locationManager.errorMessage = "Location access denied. Please enable it in Settings."
            } else if (newValue == .authorizedWhenInUse || newValue == .authorizedAlways) && isRequestingLocation {
                locationManager.startUpdatingLocation()
            }
        }
    }

    // MARK: - Default View

    private var defaultView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Find Events Near You")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Choose how you'd like to discover nearby events")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            VStack(spacing: 0) {
                // Use Current Location
                Button {
                    requestLocationPermission()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)

                            if isRequestingLocation {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(isRequestingLocation ? "Getting Location..." : "Use Current Location")
                            .font(.system(size: 17))
                            .foregroundColor(.white)

                        Spacer()

                        if !isRequestingLocation {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 44/255, green: 44/255, blue: 46/255))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRequestingLocation)

                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.leading, 66)

                // Manual Entry
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingManualEntry = true
                    }
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)

                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Text("Enter City or Town")
                            .font(.system(size: 17))
                            .foregroundColor(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(red: 44/255, green: 44/255, blue: 46/255))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)

            if let error = locationManager.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 16)
            }

            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    onDismiss()
                }
            } label: {
                Text("Not Now")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Manual Entry View

    private var manualEntryView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Enter Your Location")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text("Type the name of your city or town in the UK")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 8) {
                TextField("e.g., London, Manchester, Edinburgh", text: $cityInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(16)
                    .background(Color(red: 44/255, green: 44/255, blue: 46/255))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.white)
                    .font(.system(size: 17))
                    .autocapitalization(.words)
                    .disabled(isLoading)

                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                Button {
                    confirmCityLocation()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                        }

                        Text(isLoading ? "Validating..." : "Confirm Location")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(cityInput.isEmpty || isLoading ? Color.gray.opacity(0.3) : Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(cityInput.isEmpty || isLoading)
                .buttonStyle(PlainButtonStyle())

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingManualEntry = false
                        cityInput = ""
                        errorMessage = nil
                    }
                } label: {
                    Text("Back")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Actions

    private func requestLocationPermission() {
        print("📍 LocationPromptModal: Request location permission tapped")
        isRequestingLocation = true
        locationManager.errorMessage = nil

        let status = locationManager.authorizationStatus

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestLocationPermission()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if isRequestingLocation {
                isRequestingLocation = false
                if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
                    locationManager.errorMessage = "Location access denied. Go to Settings > Privacy > Location Services."
                } else if locationManager.currentLocation == nil {
                    locationManager.errorMessage = "Could not get your location. Try again or enter your city manually."
                }
            }
        }
    }

    private func confirmCityLocation() {
        guard !cityInput.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        let trimmedCity = cityInput.trimmingCharacters(in: .whitespaces)

        locationManager.geocodeCity(trimmedCity) { result in
            Task { @MainActor in
                isLoading = false
                switch result {
                case .success:
                    locationManager.saveLocationPreference(.city(trimmedCity))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                case .failure:
                    errorMessage = "Could not find '\(trimmedCity)' in the UK. Please try again."
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        LocationPromptModal { print("Dismissed") }
            .environmentObject(LocationManager())
    }
    .preferredColorScheme(.dark)
}
