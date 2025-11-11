import SwiftUI
import CoreLocation

struct LocationSelectionSheet: View {
    @ObservedObject var locationService: LocationService
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedTab: LocationTab = .currentLocation
    @FocusState private var isSearchFocused: Bool

    enum LocationTab {
        case currentLocation, manualEntry
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header

                // Tab Selection
                tabSelector

                // Content
                if selectedTab == .currentLocation {
                    currentLocationContent
                } else {
                    manualEntryContent
                }

                Spacer()
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)

            HStack {
                Text("SET YOUR LOCATION")
                    .appSectionHeader()
                    .foregroundColor(.white)

                Spacer()

                CloseButton {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Text("Find events happening near you")
                .appSecondary()
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .currentLocation
                    isSearchFocused = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.appIcon)
                    Text("USE LOCATION")
                        .appCaption()
                }
                .foregroundColor(selectedTab == .currentLocation ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(selectedTab == .currentLocation ? Color.white : Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .manualEntry
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.appIcon)
                    Text("ENTER CITY")
                        .appCaption()
                }
                .foregroundColor(selectedTab == .manualEntry ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(selectedTab == .manualEntry ? Color.white : Color.gray.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Current Location Content
    private var currentLocationContent: some View {
        VStack(spacing: 20) {
            // Current location status
            if let locationData = locationService.locationData, !locationData.isManualEntry {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)

                    Text("Location Set")
                        .appBody()
                        .foregroundColor(.white)

                    if let cityName = locationData.cityName {
                        Text(cityName)
                            .appSectionHeader()
                            .foregroundColor(.white)
                    }

                    Text("Updated \(locationData.timestamp.formatted(.relative(presentation: .named)))")
                        .appCaption()
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                Button(action: {
                    locationService.requestLocation()
                }) {
                    Text("Update Location")
                        .font(.appFont(size: 17))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

            } else {
                VStack(spacing: 20) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("DISCOVER NEARBY EVENTS")
                            .appSectionHeader()
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text("Allow location access to see events near you")
                            .appSecondary()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Button(action: {
                        locationService.requestLocation()
                        locationService.markPromptAsSeen()

                        // Dismiss after a short delay to allow permission prompt
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }) {
                        Text("Use My Location")
                            .font(.appFont(size: 17))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 60)
            }
        }
    }

    // MARK: - Manual Entry Content
    private var manualEntryContent: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.appIcon)
                    .foregroundColor(.gray)

                TextField("Search UK cities", text: $searchText)
                    .appBody()
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.appIcon)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 22/255, green: 22/255, blue: 23/255))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // City list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredCities, id: \.name) { city in
                        Button(action: {
                            selectCity(city.name)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(city.name)
                                        .appBody()
                                        .foregroundColor(.white)

                                    if let currentCity = locationService.locationData?.cityName,
                                       currentCity == city.name {
                                        Text("Current location")
                                            .appCaption()
                                            .foregroundColor(.green)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.appIcon)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.clear)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .background(Color.gray.opacity(0.2))
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
    }

    // MARK: - Filtered Cities
    private var filteredCities: [(name: String, latitude: Double, longitude: Double)] {
        if searchText.isEmpty {
            return LocationService.ukCities
        } else {
            return LocationService.ukCities.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Select City
    private func selectCity(_ cityName: String) {
        locationService.setManualLocation(cityName: cityName)
        locationService.markPromptAsSeen()

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Dismiss sheet
        dismiss()
    }
}

#Preview {
    LocationSelectionSheet(locationService: LocationService())
        .preferredColorScheme(.dark)
}
