import Foundation
import CoreLocation
import Combine

// MARK: - Location Data Model
struct UserLocationData: Codable {
    let latitude: Double
    let longitude: Double
    let cityName: String?
    let isManualEntry: Bool
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Location Service
@MainActor
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    // MARK: - Published Properties
    @Published var userLocation: CLLocation?
    @Published var locationData: UserLocationData?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var hasLocationPermission: Bool = false
    @Published var hasSeenLocationPrompt: Bool = false

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private var geocoder = CLGeocoder()

    // MARK: - UserDefaults Keys
    private let locationDataKey = "savedUserLocationData"
    private let hasSeenPromptKey = "hasSeenLocationPrompt"

    // MARK: - UK Cities Data
    static let ukCities: [(name: String, latitude: Double, longitude: Double)] = [
        ("London", 51.5074, -0.1278),
        ("Manchester", 53.4808, -2.2426),
        ("Birmingham", 52.4862, -1.8904),
        ("Liverpool", 53.4084, -2.9916),
        ("Leeds", 53.8008, -1.5491),
        ("Sheffield", 53.3811, -1.4701),
        ("Edinburgh", 55.9533, -3.1883),
        ("Glasgow", 55.8642, -4.2518),
        ("Bristol", 51.4545, -2.5879),
        ("Newcastle", 54.9783, -1.6178),
        ("Cardiff", 51.4816, -3.1791),
        ("Belfast", 54.5973, -5.9301),
        ("Nottingham", 52.9548, -1.1581),
        ("Southampton", 50.9097, -1.4044),
        ("Leicester", 52.6369, -1.1398),
        ("Brighton", 50.8225, -0.1372),
        ("Oxford", 51.7520, -1.2577),
        ("Cambridge", 52.2053, 0.1218),
        ("York", 53.9600, -1.0873),
        ("Bath", 51.3781, -2.3597)
    ].sorted { $0.name < $1.name }

    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
        loadSavedLocation()
        loadHasSeenPrompt()
    }

    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = locationManager.authorizationStatus
        updatePermissionStatus()
    }

    private func updatePermissionStatus() {
        hasLocationPermission = authorizationStatus == .authorizedWhenInUse ||
                                authorizationStatus == .authorizedAlways
    }

    // MARK: - Load Saved Data
    private func loadSavedLocation() {
        guard let data = userDefaults.data(forKey: locationDataKey),
              let savedLocation = try? JSONDecoder().decode(UserLocationData.self, from: data) else {
            return
        }

        locationData = savedLocation
        userLocation = savedLocation.clLocation
    }

    private func loadHasSeenPrompt() {
        hasSeenLocationPrompt = userDefaults.bool(forKey: hasSeenPromptKey)
    }

    // MARK: - Save Data
    func saveLocation(_ location: UserLocationData) {
        locationData = location
        userLocation = location.clLocation

        if let encoded = try? JSONEncoder().encode(location) {
            userDefaults.set(encoded, forKey: locationDataKey)
        }
    }

    func markPromptAsSeen() {
        hasSeenLocationPrompt = true
        userDefaults.set(true, forKey: hasSeenPromptKey)
    }

    // MARK: - Location Request
    func requestLocation() {
        print("LocationService: Requesting location, current status: \(authorizationStatus.rawValue)")

        switch authorizationStatus {
        case .notDetermined:
            print("LocationService: Requesting authorization")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationService: Already authorized, requesting location")
            locationManager.requestLocation()
        case .denied, .restricted:
            print("LocationService: Location access denied or restricted")
        @unknown default:
            break
        }
    }

    // MARK: - Manual Location Entry
    func setManualLocation(cityName: String) {
        guard let city = Self.ukCities.first(where: { $0.name == cityName }) else {
            print("LocationService: City not found: \(cityName)")
            return
        }

        let locationData = UserLocationData(
            latitude: city.latitude,
            longitude: city.longitude,
            cityName: cityName,
            isManualEntry: true,
            timestamp: Date()
        )

        saveLocation(locationData)
        print("LocationService: Manual location set to \(cityName)")
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("LocationService: Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        userLocation = location

        // Reverse geocode to get city name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            let cityName = placemarks?.first?.locality

            Task { @MainActor in
                let locationData = UserLocationData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    cityName: cityName,
                    isManualEntry: false,
                    timestamp: Date()
                )

                self.saveLocation(locationData)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationService: Error: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        updatePermissionStatus()

        print("LocationService: Authorization changed to: \(authorizationStatus.rawValue)")

        if authorizationStatus == .authorizedWhenInUse ||
           authorizationStatus == .authorizedAlways {
            print("LocationService: Now authorized, requesting location")
            locationManager.requestLocation()
        }
    }

    // MARK: - Clear Location
    func clearLocation() {
        locationData = nil
        userLocation = nil
        userDefaults.removeObject(forKey: locationDataKey)
    }
}
