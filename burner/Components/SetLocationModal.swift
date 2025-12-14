import SwiftUI
import CoreLocation

struct ModalLocationSecondaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var borderColor: Color? = nil
    var maxWidth: CGFloat? = .infinity

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appButton()
            .foregroundColor(foregroundColor)
            .frame(maxWidth: maxWidth)
            .frame(height: 50)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        Capsule().stroke(borderColor, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SetLocationModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
                .frame(height: 30)

            VStack(spacing: 16) {
                // 1. Use Current Location Button (White background, black text)
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack(spacing: 12) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "location.fill")
                                .appMonospaced(size: 16)
                        }
                        Text(isProcessing ? "LOCATING..." : "USE CURRENT LOCATION")
                            .appButton()
                    }
                }
                .buttonStyle(ModalLocationSecondaryButtonStyle(
                    backgroundColor: .white,
                    foregroundColor: .black,
                    maxWidth: .infinity
                ))
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.5 : 1.0)

                // 2. Search for a City Button (Black background, white text, white border)
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .appMonospaced(size: 16)
                        Text("SEARCH FOR A CITY")
                            .appButton()
                    }
                }
                .buttonStyle(ModalLocationSecondaryButtonStyle(
                    backgroundColor: .black,
                    foregroundColor: .white,
                    borderColor: .white.opacity(0.3),
                    maxWidth: .infinity
                ))
            }
            .padding(.horizontal, 24)

            // Optional error (kept minimal; below buttons)
            if let error = errorMessage {
                Text(error)
                    .appCaption()
                    .foregroundColor(.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(Color.black)
        .presentationDetents([.height(170)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingManualEntry) {
            ManualCityEntryView(locationManager: appState.userLocationManager, onDismiss: {
                showingManualEntry = false
                dismiss()
            })
        }
    }

    private func requestCurrentLocation() {
        isProcessing = true
        errorMessage = nil

        appState.userLocationManager.requestCurrentLocation { result in
            isProcessing = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - City Data Model
struct CityLocation: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let region: String
    let latitude: Double
    let longitude: Double
    
    var displayName: String {
        name
    }
    
    var fullDisplayName: String {
        "\(name), \(region)"
    }
}

// MARK: - UK Cities Only (England only)
extension CityLocation {
    static let ukCities: [CityLocation] = [
        // England - Major Cities
        CityLocation(name: "London", region: "England", latitude: 51.5074, longitude: -0.1278),
        CityLocation(name: "Manchester", region: "England", latitude: 53.4808, longitude: -2.2426),
        CityLocation(name: "Birmingham", region: "England", latitude: 52.4862, longitude: -1.8904),
        CityLocation(name: "Liverpool", region: "England", latitude: 53.4084, longitude: -2.9916),
        CityLocation(name: "Leeds", region: "England", latitude: 53.8008, longitude: -1.5491),
        CityLocation(name: "Bristol", region: "England", latitude: 51.4545, longitude: -2.5879),
        CityLocation(name: "Newcastle upon Tyne", region: "England", latitude: 54.9783, longitude: -1.6178),
        CityLocation(name: "Sheffield", region: "England", latitude: 53.3811, longitude: -1.4701),
        CityLocation(name: "Nottingham", region: "England", latitude: 52.9548, longitude: -1.1581),
        CityLocation(name: "Leicester", region: "England", latitude: 52.6369, longitude: -1.1398),
        CityLocation(name: "Southampton", region: "England", latitude: 50.9097, longitude: -1.4044),
        CityLocation(name: "Brighton", region: "England", latitude: 50.8225, longitude: -0.1372),
        CityLocation(name: "Plymouth", region: "England", latitude: 50.3755, longitude: -4.1427),
        CityLocation(name: "Reading", region: "England", latitude: 51.4543, longitude: -0.9781),
        CityLocation(name: "Derby", region: "England", latitude: 52.9225, longitude: -1.4746),
        CityLocation(name: "Coventry", region: "England", latitude: 52.4068, longitude: -1.5197),
        CityLocation(name: "Portsmouth", region: "England", latitude: 50.8198, longitude: -1.0880),
        CityLocation(name: "Bournemouth", region: "England", latitude: 50.7192, longitude: -1.8808),
        CityLocation(name: "Swindon", region: "England", latitude: 51.5558, longitude: -1.7797),
        CityLocation(name: "Milton Keynes", region: "England", latitude: 52.0406, longitude: -0.7594),
        CityLocation(name: "Norwich", region: "England", latitude: 52.6309, longitude: 1.2974),
        CityLocation(name: "Cambridge", region: "England", latitude: 52.2053, longitude: 0.1218),
        CityLocation(name: "Oxford", region: "England", latitude: 51.7520, longitude: -1.2577),
        CityLocation(name: "Bath", region: "England", latitude: 51.3758, longitude: -2.3599),
        CityLocation(name: "York", region: "England", latitude: 53.9600, longitude: -1.0873),
        CityLocation(name: "Exeter", region: "England", latitude: 50.7184, longitude: -3.5339),
        CityLocation(name: "Canterbury", region: "England", latitude: 51.2802, longitude: 1.0789),
        CityLocation(name: "Durham", region: "England", latitude: 54.7761, longitude: -1.5733),
        CityLocation(name: "Winchester", region: "England", latitude: 51.0632, longitude: -1.3080),
        CityLocation(name: "Chester", region: "England", latitude: 53.1905, longitude: -2.8908),
        CityLocation(name: "Carlisle", region: "England", latitude: 54.8951, longitude: -2.9382),
        CityLocation(name: "Lancaster", region: "England", latitude: 54.0466, longitude: -2.8007),
        CityLocation(name: "Lincoln", region: "England", latitude: 53.2307, longitude: -0.5406),
        CityLocation(name: "Peterborough", region: "England", latitude: 52.5695, longitude: -0.2405),
        CityLocation(name: "Ipswich", region: "England", latitude: 52.0594, longitude: 1.1556),
        CityLocation(name: "Colchester", region: "England", latitude: 51.8860, longitude: 0.9035),
        CityLocation(name: "Chelmsford", region: "England", latitude: 51.7356, longitude: 0.4685),
        CityLocation(name: "Gloucester", region: "England", latitude: 51.8642, longitude: -2.2382),
        CityLocation(name: "Worcester", region: "England", latitude: 52.1936, longitude: -2.2210),
        CityLocation(name: "Hereford", region: "England", latitude: 52.0565, longitude: -2.7160),
        CityLocation(name: "Salisbury", region: "England", latitude: 51.0689, longitude: -1.7948),
        CityLocation(name: "Truro", region: "England", latitude: 50.2632, longitude: -5.0510),
    ].sorted { $0.name < $1.name }
}

// MARK: - Manual City Entry View with UK Cities List
struct ManualCityEntryView: View {
    @ObservedObject var locationManager: UserLocationManager
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var isProcessing = false
    @State private var selectedCityName: String?
    @FocusState private var isFocused: Bool
    
    private var filteredCities: [CityLocation] {
        if searchText.isEmpty {
            return CityLocation.ukCities
        } else {
            return CityLocation.ukCities.filter { city in
                city.name.localizedCaseInsensitiveContains(searchText) ||
                city.region.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Input Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECT YOUR CITY")
                        .appSecondary()
                        .foregroundColor(.white.opacity(0.7))
                        .textCase(.uppercase)

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .appMonospaced(size: 16)
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("Search UK cities...", text: $searchText)
                            .appBody()
                            .foregroundColor(.white)
                            .focused($isFocused)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .appMonospaced(size: 16)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Results count
                HStack {
                    Text("\(filteredCities.count) \(filteredCities.count == 1 ? "city" : "cities")")
                        .appCaption()
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

                // City List
                if filteredCities.isEmpty {
                    // No results state
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 60)
                        
                        Text("No cities found")
                            .appBody()
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Try a different search term")
                            .appCaption()
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCities) { city in
                                Button(action: {
                                    selectCity(city)
                                }) {
                                    HStack(spacing: 12) {
                                        Text(city.name)
                                            .appBody()
                                            .foregroundColor(.white)

                                        Spacer()

                                        if isProcessing && selectedCityName == city.name {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(Color.white.opacity(0.02))
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(isProcessing)
                                
                                if city != filteredCities.last {
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .appBody()
                    .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func selectCity(_ city: CityLocation) {
        selectedCityName = city.name
        isProcessing = true

        let userLocation = UserLocation(
            latitude: city.latitude,
            longitude: city.longitude,
            name: city.name,
            timestamp: Date()
        )

        locationManager.saveLocationDirectly(userLocation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isProcessing = false
            onDismiss()
        }
    }
}
