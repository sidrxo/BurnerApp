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
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isRequestingLocation && !isLoading {
                        onDismiss()
                    }
                }

            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.height > 50 && !isRequestingLocation && !isLoading {
                                        onDismiss()
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
                .background(Color(red: 18/255, green: 18/255, blue: 18/255))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .ignoresSafeArea(edges: .bottom)
        }
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
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Find Events Near You")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Text("Choose how you'd like to discover nearby events")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Use Current Location
                Button {
                    requestLocationPermission()
                } label: {
                    HStack(spacing: 16) {
                        if isRequestingLocation {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .frame(width: 40)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.appIcon)
                                .foregroundColor(.white)
                                .frame(width: 40)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isRequestingLocation ? "Getting Location..." : "Use Current Location")
                                .appCard()
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        if !isRequestingLocation {
                            Image(systemName: "chevron.right")
                                .font(.appCaption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(isRequestingLocation ? 0.03 : 0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRequestingLocation)
                
                // Manual Entry
                Button {
                    withAnimation { showingManualEntry = true }
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.appIcon)
                            .foregroundColor(.white)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enter City or Town")
                                .appCard()
                                .foregroundColor(.white)
                            
                
                        }
                        
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.appCaption)
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            
            if let error = locationManager.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.appCaption)
                        .foregroundColor(.red)
                    Text(error)
                        .appCaption()
                        .foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)
            }
            
            Button { onDismiss() } label: {
                Text("Skip for Now")
                    .appBody()
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Manual Entry View
    
    private var manualEntryView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enter Your Location")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Text("Type the name of your city or town in the UK")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("e.g., London, Manchester, Edinburgh", text: $cityInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                    .autocapitalization(.words)
                    .disabled(isLoading)
                    .appBody()
                
                if let error = errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.appCaption)
                            .foregroundColor(.red)
                        Text(error)
                            .appCaption()
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 20)
            
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
                            .appCard()
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(cityInput.isEmpty || isLoading ? Color.gray.opacity(0.3) : Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(cityInput.isEmpty || isLoading)
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    withAnimation {
                        showingManualEntry = false
                        cityInput = ""
                        errorMessage = nil
                    }
                } label: {
                    Text("Back")
                        .appBody()
                        .foregroundColor(.gray)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
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
                case .success(let coordinate):
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
