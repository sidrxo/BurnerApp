//
//  PreferencesSyncService.swift
//  burner
//
//  Sync preferences between UserDefaults and Firebase
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class PreferencesSyncService {
    private let db = Firestore.firestore()

    // MARK: - Sync Local Preferences to Firebase
    func syncLocalPreferencesToFirebase(localPreferences: LocalPreferences) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        let preferencesData = localPreferences.exportDictionary()

        if preferencesData.isEmpty {
            return
        }

        let userRef = db.collection("users").document(userId)

        do {
            try await userRef.setData(["preferences": preferencesData], merge: true)
        } catch {
        }
    }

    // MARK: - Load Preferences from Firebase
    func loadPreferencesFromFirebase() async -> LocalPreferences? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }

        let userRef = db.collection("users").document(userId)

        do {
            let snapshot = try await userRef.getDocument()
            
            guard let data = snapshot.data(),
                  let preferencesData = data["preferences"] as? [String: Any] else {
                return nil
            }

            // ✅ Safe to initialize because we are back on the MainActor after 'await'
            let preferences = LocalPreferences()

            // Load genres
            if let genres = preferencesData["genres"] as? [String] {
                preferences.selectedGenres = genres
            }

            // Load location
            if let location = preferencesData["location"] as? [String: Any],
               let name = location["name"] as? String,
               let lat = location["lat"] as? Double,
               let lon = location["lon"] as? Double {
                preferences.locationName = name
                preferences.locationLat = lat
                preferences.locationLon = lon
            }

            // Load notifications
            if let notificationsEnabled = preferencesData["notificationsEnabled"] as? Bool {
                preferences.hasEnabledNotifications = notificationsEnabled
            }

            return preferences

        } catch {
            return nil
        }
    }

    // MARK: - Merge Preferences (local + Firebase)
    func mergePreferences(localPreferences: LocalPreferences) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        // 1. Load Firebase preferences
        let firebasePreferences = await loadPreferencesFromFirebase()

        // 2. If no Firebase data, just sync local up
        guard let firebasePreferences = firebasePreferences else {
            await syncLocalPreferencesToFirebase(localPreferences: localPreferences)
            return
        }

        // 3. Merge Strategy
        let mergedPreferences = LocalPreferences()

        // Merge genres (unique set)
        let combinedGenres = Array(Set(localPreferences.selectedGenres + firebasePreferences.selectedGenres))
        mergedPreferences.selectedGenres = combinedGenres

        // Merge location (prefer local)
        if localPreferences.hasLocation {
            mergedPreferences.locationName = localPreferences.locationName
            mergedPreferences.locationLat = localPreferences.locationLat
            mergedPreferences.locationLon = localPreferences.locationLon
        } else if firebasePreferences.hasLocation {
            mergedPreferences.locationName = firebasePreferences.locationName
            mergedPreferences.locationLat = firebasePreferences.locationLat
            mergedPreferences.locationLon = firebasePreferences.locationLon
        }

        // Merge notifications (OR logic)
        mergedPreferences.hasEnabledNotifications = localPreferences.hasEnabledNotifications || firebasePreferences.hasEnabledNotifications

        // 4. Save merged result
        mergedPreferences.saveToUserDefaults()

        // 5. Sync merged result back to Firebase
        let mergedData = mergedPreferences.exportDictionary()
        let userRef = self.db.collection("users").document(userId)

        do {
            try await userRef.setData(["preferences": mergedData], merge: true)
        } catch {
        }
    }
}
