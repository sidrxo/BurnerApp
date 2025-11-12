import Foundation
import CoreLocation
import Combine

struct UserLocation: Codable {
    let latitude: Double
    let longitude: Double
    let name: String
    let timestamp: Date
}

@MainActor
class UserLocationManager: NSObject, ObservableObject {
    @Published var savedLocation: UserLocation?
    @Published var currentCLLocation: CLLocation?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var locationCompletion: ((Result<UserLocation, Error>) -> Void)?
    
    private let userDefaultsKey = "userSavedLocation"
    private var hasCalledCompletion = false
    
    // ✅ UX delay - 0.6 seconds for better feedback
    private let uxDelay: TimeInterval = 0.6
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100
        loadSavedLocation()
    }
    
    // MARK: - Load Saved Location
    func loadSavedLocation() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let location = try? JSONDecoder().decode(UserLocation.self, from: data) else {
            return
        }
        savedLocation = location
        currentCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
    }
    
    // MARK: - Save Location
    private func saveLocation(_ location: UserLocation) {
        savedLocation = location
        currentCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        if let encoded = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    
    
    // MARK: - Clear Location
    func clearLocation() {
        savedLocation = nil
        currentCLLocation = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Request Current Location
    func requestCurrentLocation(completion: @escaping (Result<UserLocation, Error>) -> Void) {
        hasCalledCompletion = false
        self.locationCompletion = completion
        
        let status = locationManager.authorizationStatus
        
        // Check if we have a recent cached location
        if let cachedLocation = locationManager.location {
            let age = Date().timeIntervalSince(cachedLocation.timestamp)
            // If cached location is less than 5 minutes old, use it immediately
            if age < 300 {
                handleLocationUpdate(cachedLocation)
                return
            }
        }
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(.failure(LocationError.accessDenied))
        @unknown default:
            completion(.failure(LocationError.unknown))
        }
    }
    
    // MARK: - Handle Location Update
    private func handleLocationUpdate(_ location: CLLocation) {
        guard !hasCalledCompletion else { return }
        hasCalledCompletion = true
        
        // Save immediately with "Current Location" as placeholder
        let immediateLocation = UserLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: "Current Location",
            timestamp: Date()
        )
        
        saveLocation(immediateLocation)
        
        // Capture delay before crossing concurrency boundary
        let delay = uxDelay
        let completionHandler = locationCompletion
        // Clear stored completion so we don't retain it longer than needed
        locationCompletion = nil
        
        // Add UX delay for smooth feedback using Swift concurrency
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            completionHandler?(.success(immediateLocation))
        }
        
        // Reverse geocode in background to get city name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let self else { return }
            let cityName = placemarks?.first?.locality ??
                           placemarks?.first?.name ??
                           "Current Location"
            
            let updatedLocation = UserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: cityName,
                timestamp: Date()
            )
            
            Task { @MainActor in
                self.saveLocation(updatedLocation)
            }
        }
    }
    
    // MARK: - Reset Location
    func resetLocation() {
        // Clear all stored location data
        savedLocation = nil
        currentCLLocation = nil
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        
        // Cancel any pending completion handlers
        locationCompletion = nil
        hasCalledCompletion = false
        
        // Stop any ongoing location updates
        locationManager.stopUpdatingLocation()
        
        // Cancel any ongoing geocoding operations
        geocoder.cancelGeocode()
    }
    
    // MARK: - Geocode City
    func geocodeCity(_ cityName: String, completion: @escaping (Result<UserLocation, Error>) -> Void) {
        geocoder.geocodeAddressString(cityName) { [weak self] placemarks, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(.failure(LocationError.geocodingFailed))
                return
            }
            
            let resolvedName = placemark.locality ?? placemark.name ?? cityName
            let userLocation = UserLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: resolvedName,
                timestamp: Date()
            )
            
            // Capture needed values before hopping across concurrency boundaries
            let delay = self?.uxDelay ?? 0.6
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if let self {
                    self.saveLocation(userLocation)
                }
                completion(.success(userLocation))
            }
        }
    }
    
    enum LocationError: LocalizedError {
        case accessDenied
        case geocodingFailed
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Location access denied. Please enable location services in Settings."
            case .geocodingFailed:
                return "Could not find that city. Please try again."
            case .unknown:
                return "An unknown error occurred."
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension UserLocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.handleLocationUpdate(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            let completion = self.locationCompletion
            self.locationCompletion = nil
            completion?(.failure(error))
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied:
                let completion = self.locationCompletion
                self.locationCompletion = nil
                completion?(.failure(LocationError.accessDenied))
            default:
                break
            }
        }
    }
}
