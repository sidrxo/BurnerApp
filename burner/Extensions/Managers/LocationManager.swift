import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var userLocation: UserLocation?
    @Published var hasLocationPreference: Bool = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let geocoder = CLGeocoder()
    
    // UserDefaults keys
    private let locationTypeKey = "userLocationType"
    private let latitudeKey = "userLatitude"
    private let longitudeKey = "userLongitude"
    private let cityNameKey = "userCityName"
    
    // Callback for location updates
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Update initial authorization status
        authorizationStatus = locationManager.authorizationStatus
        
        print("📍 LocationManager: Initialized with auth status: \(authorizationStatus.rawValue)")
        
        // Load saved location preference
        loadLocationPreference()
    }
    
    // MARK: - Location Preference Storage
    
    func loadLocationPreference() {
        if let locationType = userDefaults.string(forKey: locationTypeKey) {
            if locationType == "gps" {
                if let lat = userDefaults.object(forKey: latitudeKey) as? Double,
                   let lon = userDefaults.object(forKey: longitudeKey) as? Double {
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    userLocation = .coordinate(coordinate)
                    currentLocation = CLLocation(latitude: lat, longitude: lon)
                    hasLocationPreference = true
                    print("📍 LocationManager: Loaded GPS location: \(lat), \(lon)")
                }
            } else if locationType == "city" {
                if let city = userDefaults.string(forKey: cityNameKey) {
                    userLocation = .city(city)
                    hasLocationPreference = true
                    print("📍 LocationManager: Loaded city location: \(city)")
                    // Geocode the city to get coordinates
                    geocodeCity(city)
                }
            }
        }
    }
    
    func saveLocationPreference(_ location: UserLocation) {
        print("📍 LocationManager: Saving location preference: \(location)")
        userLocation = location
        hasLocationPreference = true
        
        switch location {
        case .coordinate(let coord):
            userDefaults.set("gps", forKey: locationTypeKey)
            userDefaults.set(coord.latitude, forKey: latitudeKey)
            userDefaults.set(coord.longitude, forKey: longitudeKey)
            userDefaults.removeObject(forKey: cityNameKey)
            currentLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            print("📍 LocationManager: Saved GPS location: \(coord.latitude), \(coord.longitude)")
            
        case .city(let cityName):
            userDefaults.set("city", forKey: locationTypeKey)
            userDefaults.set(cityName, forKey: cityNameKey)
            userDefaults.removeObject(forKey: latitudeKey)
            userDefaults.removeObject(forKey: longitudeKey)
            print("📍 LocationManager: Saved city location: \(cityName)")
            // Geocode the city
            geocodeCity(cityName)
        }
    }
    
    func clearLocationPreference() {
        userDefaults.removeObject(forKey: locationTypeKey)
        userDefaults.removeObject(forKey: latitudeKey)
        userDefaults.removeObject(forKey: longitudeKey)
        userDefaults.removeObject(forKey: cityNameKey)
        userLocation = nil
        currentLocation = nil
        hasLocationPreference = false
        print("📍 LocationManager: Cleared location preference")
    }
    
    // MARK: - Location Permissions
    
    func requestLocationPermission() {
        authorizationStatus = locationManager.authorizationStatus
        print("📍 LocationManager: requestLocationPermission called, status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
        case .notDetermined:
            print("📍 LocationManager: Requesting authorization")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 LocationManager: Already authorized, starting updates")
            startUpdatingLocation()
        case .denied, .restricted:
            print("📍 LocationManager: Access denied or restricted")
            errorMessage = "Location access denied. Please enable it in Settings."
        @unknown default:
            break
        }
    }
    
    func requestLocation() {
        authorizationStatus = locationManager.authorizationStatus
        print("📍 LocationManager: requestLocation called, status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
        case .notDetermined:
            print("📍 LocationManager: Requesting authorization for one-time location")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 LocationManager: Requesting one-time location")
            locationManager.requestLocation()
        case .denied, .restricted:
            print("📍 LocationManager: Access denied or restricted")
            errorMessage = "Location access denied. Please enable it in Settings."
        @unknown default:
            break
        }
    }
    
    func startUpdatingLocation() {
        print("📍 LocationManager: Starting continuous location updates")
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        print("📍 LocationManager: Stopping location updates")
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Geocoding
    
    func geocodeCity(_ cityName: String, completion: ((Result<CLLocationCoordinate2D, Error>) -> Void)? = nil) {
        // Add ", UK" to ensure we search within UK
        let searchString = cityName.contains("UK") ? cityName : "\(cityName), UK"
        
        print("📍 LocationManager: Geocoding city: \(searchString)")
        
        geocoder.geocodeAddressString(searchString) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("📍 LocationManager: Geocoding error: \(error.localizedDescription)")
                    self.errorMessage = "Could not find location: \(cityName)"
                    completion?(.failure(error))
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    print("📍 LocationManager: No placemark found")
                    let error = NSError(domain: "LocationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No location found"])
                    self.errorMessage = "Could not find location: \(cityName)"
                    completion?(.failure(error))
                    return
                }
                
                // Verify the location is in the UK
                if let country = placemark.country, country == "United Kingdom" {
                    print("📍 LocationManager: Successfully geocoded to: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    self.currentLocation = location
                    completion?(.success(location.coordinate))
                } else {
                    print("📍 LocationManager: Location not in UK, country: \(placemark.country ?? "unknown")")
                    let error = NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location not in UK"])
                    self.errorMessage = "Please enter a location within the UK"
                    completion?(.failure(error))
                }
            }
        }
    }
    
    func validateUKLocation(coordinate: CLLocationCoordinate2D, completion: @escaping (Bool) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        print("📍 LocationManager: Validating if location is in UK: \(coordinate.latitude), \(coordinate.longitude)")
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            Task { @MainActor in
                if let error = error {
                    print("📍 LocationManager: Reverse geocoding error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let placemark = placemarks?.first,
                   let country = placemark.country {
                    let isUK = country == "United Kingdom"
                    print("📍 LocationManager: Location country: \(country), isUK: \(isUK)")
                    completion(isUK)
                } else {
                    print("📍 LocationManager: No country found in reverse geocoding")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Distance Calculation
    
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    func formattedDistance(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let distance = distance(to: coordinate) else { return nil }
        
        // Convert to miles
        let miles = distance / 1609.34
        
        if miles < 0.1 {
            return "< 0.1 mi"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("📍 LocationManager [Delegate]: Authorization changed to \(status.rawValue)")
        
        Task { @MainActor in
            authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("📍 LocationManager [Delegate]: Authorization granted")
                // Don't auto-start here - let the caller decide
            case .denied, .restricted:
                print("📍 LocationManager [Delegate]: Authorization denied/restricted")
                errorMessage = "Location access denied. Please enable it in Settings."
                stopUpdatingLocation()
            case .notDetermined:
                print("📍 LocationManager [Delegate]: Authorization not determined")
                break
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("📍 LocationManager [Delegate]: No locations in array")
            return
        }
        
        print("📍 LocationManager [Delegate]: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude), accuracy: \(location.horizontalAccuracy)m")
        
        Task { @MainActor in
            // Call the update callback
            onLocationUpdate?(location.coordinate)
            
            // Update current location
            currentLocation = location
            
            // Clear any error
            errorMessage = nil
            
            print("📍 LocationManager [Delegate]: Published location update")
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 LocationManager [Delegate]: Location error: \(error.localizedDescription)")
        
        Task { @MainActor in
            // Check if it's just a "location unknown" error (common and temporary)
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    print("📍 LocationManager [Delegate]: Location temporarily unknown, will retry")
                    // Don't show error for temporary issues
                    return
                case .denied:
                    errorMessage = "Location access denied. Please enable it in Settings."
                case .network:
                    errorMessage = "Network error while getting location. Please check your connection."
                default:
                    errorMessage = "Failed to get location: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "Failed to get location: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - UserLocation Enum

enum UserLocation: Codable, Equatable {
    case coordinate(CLLocationCoordinate2D)
    case city(String)
    
    enum CodingKeys: String, CodingKey {
        case type
        case latitude
        case longitude
        case cityName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        if type == "coordinate" {
            let lat = try container.decode(Double.self, forKey: .latitude)
            let lon = try container.decode(Double.self, forKey: .longitude)
            self = .coordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        } else {
            let city = try container.decode(String.self, forKey: .cityName)
            self = .city(city)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .coordinate(let coord):
            try container.encode("coordinate", forKey: .type)
            try container.encode(coord.latitude, forKey: .latitude)
            try container.encode(coord.longitude, forKey: .longitude)
        case .city(let cityName):
            try container.encode("city", forKey: .type)
            try container.encode(cityName, forKey: .cityName)
        }
    }
    
    // Implement Equatable
    static func == (lhs: UserLocation, rhs: UserLocation) -> Bool {
        switch (lhs, rhs) {
        case (.coordinate(let coord1), .coordinate(let coord2)):
            return coord1.latitude == coord2.latitude && coord1.longitude == coord2.longitude
        case (.city(let city1), .city(let city2)):
            return city1 == city2
        default:
            return false
        }
    }
}

// MARK: - Coordinate Wrapper for Codable Support

// Wrapper struct to handle CLLocationCoordinate2D encoding/decoding
// This avoids declaring conformance on imported types
struct CodableCoordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
