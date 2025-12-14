//
//  LocalPreferences.swift
//  burner
//
//  Store user preferences locally before sign-in
//

import Foundation
import Combine

@MainActor
class LocalPreferences: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedGenres: [String] = [] {
        didSet { saveToUserDefaults() }
    }

    @Published var locationName: String? = nil {
        didSet { saveToUserDefaults() }
    }

    @Published var locationLat: Double? = nil {
        didSet { saveToUserDefaults() }
    }

    @Published var locationLon: Double? = nil {
        didSet { saveToUserDefaults() }
    }

    @Published var hasEnabledNotifications: Bool = false {
        didSet { saveToUserDefaults() }
    }

    // MARK: - UserDefaults Keys
    private let selectedGenresKey = "localPreferences_selectedGenres"
    private let locationNameKey = "localPreferences_locationName"
    private let locationLatKey = "localPreferences_locationLat"
    private let locationLonKey = "localPreferences_locationLon"
    private let hasEnabledNotificationsKey = "localPreferences_hasEnabledNotifications"

    // MARK: - Computed Properties
    var hasGenres: Bool {
        return !selectedGenres.isEmpty
    }

    var hasLocation: Bool {
        return locationName != nil && locationLat != nil && locationLon != nil
    }

    var hasAnyPreferences: Bool {
        return hasGenres || hasLocation || hasEnabledNotifications
    }

    // MARK: - Initialization
    init() {
        loadFromUserDefaults()
    }

    // MARK: - Save to UserDefaults
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard

        // Save genres
        defaults.set(selectedGenres, forKey: selectedGenresKey)

        // Save location
        defaults.set(locationName, forKey: locationNameKey)
        if let lat = locationLat {
            defaults.set(lat, forKey: locationLatKey)
        } else {
            defaults.removeObject(forKey: locationLatKey)
        }
        if let lon = locationLon {
            defaults.set(lon, forKey: locationLonKey)
        } else {
            defaults.removeObject(forKey: locationLonKey)
        }

        // Save notifications
        defaults.set(hasEnabledNotifications, forKey: hasEnabledNotificationsKey)

        defaults.synchronize()
    }

    // MARK: - Load from UserDefaults
    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard

        // Load genres
        if let genres = defaults.array(forKey: selectedGenresKey) as? [String] {
            selectedGenres = genres
        }

        // Load location
        locationName = defaults.string(forKey: locationNameKey)
        if defaults.object(forKey: locationLatKey) != nil {
            locationLat = defaults.double(forKey: locationLatKey)
        }
        if defaults.object(forKey: locationLonKey) != nil {
            locationLon = defaults.double(forKey: locationLonKey)
        }

        // Load notifications
        hasEnabledNotifications = defaults.bool(forKey: hasEnabledNotificationsKey)

    }

    // MARK: - Reset
    func reset() {
        selectedGenres = []
        locationName = nil
        locationLat = nil
        locationLon = nil
        hasEnabledNotifications = false

        // Clear from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: selectedGenresKey)
        defaults.removeObject(forKey: locationNameKey)
        defaults.removeObject(forKey: locationLatKey)
        defaults.removeObject(forKey: locationLonKey)
        defaults.removeObject(forKey: hasEnabledNotificationsKey)
        defaults.synchronize()
    }
}
