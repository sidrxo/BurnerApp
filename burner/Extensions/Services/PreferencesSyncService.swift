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
    func syncLocalPreferencesToFirebase(localPreferences: LocalPreferences) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user, cannot sync preferences")
            return
        }

        let preferencesData = localPreferences.exportDictionary()

        if preferencesData.isEmpty {
            print("⚠️ No local preferences to sync")
            return
        }

        let userRef = db.collection("users").document(userId)

        userRef.setData(["preferences": preferencesData], merge: true) { error in
            if let error = error {
                print("❌ Failed to sync local preferences to Firebase: \(error.localizedDescription)")
            } else {
                print("✅ Local preferences synced to Firebase successfully")
            }
        }
    }

    // MARK: - Load Preferences from Firebase
    func loadPreferencesFromFirebase(completion: @escaping (LocalPreferences?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user, cannot load preferences")
            completion(nil)
            return
        }

        let userRef = db.collection("users").document(userId)

        userRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Failed to load preferences from Firebase: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = snapshot?.data(),
                  let preferencesData = data["preferences"] as? [String: Any] else {
                print("⚠️ No preferences found in Firebase")
                completion(nil)
                return
            }

            // Convert Firebase data to LocalPreferences
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

            print("✅ Preferences loaded from Firebase successfully")
            completion(preferences)
        }
    }

    // MARK: - Merge Preferences (local + Firebase)
    func mergePreferences(localPreferences: LocalPreferences, completion: @escaping () -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user, cannot merge preferences")
            completion()
            return
        }

        // Load Firebase preferences first
        loadPreferencesFromFirebase { [weak self] firebasePreferences in
            guard let self = self else {
                completion()
                return
            }

            // If no Firebase preferences, just sync local to Firebase
            guard let firebasePreferences = firebasePreferences else {
                self.syncLocalPreferencesToFirebase(localPreferences: localPreferences)
                completion()
                return
            }

            // Merge strategy:
            // 1. Genres: Combine both (unique set)
            // 2. Location: Prefer local if exists, otherwise Firebase
            // 3. Notifications: OR them (true if either is true)

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

            // Merge notifications (OR them)
            mergedPreferences.hasEnabledNotifications = localPreferences.hasEnabledNotifications || firebasePreferences.hasEnabledNotifications

            // Save merged result to both local and Firebase
            mergedPreferences.saveToUserDefaults()

            let mergedData = mergedPreferences.exportDictionary()
            let userRef = self.db.collection("users").document(userId)

            userRef.setData(["preferences": mergedData], merge: true) { error in
                if let error = error {
                    print("❌ Failed to save merged preferences to Firebase: \(error.localizedDescription)")
                } else {
                    print("✅ Merged preferences saved to Firebase successfully")
                    print("   - Genres: \(mergedPreferences.selectedGenres.count) selected")
                    print("   - Location: \(mergedPreferences.hasLocation ? "Set" : "Not set")")
                    print("   - Notifications: \(mergedPreferences.hasEnabledNotifications ? "Enabled" : "Disabled")")
                }
                completion()
            }
        }
    }
}
