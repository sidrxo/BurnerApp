//
//  to.swift
//  burner
//
//  Created by Sid Rao on 24/12/2025.
//


import Shared
import Foundation

extension Shared.AuthService {
    // Computed property to fake the old 'currentUser' check
    // If you need the actual User object, KMP needs to return it.
    // For now, checking if ID exists is often enough for "is logged in" checks.
    var currentUser: UserPlaceholder? {
        if let id = self.getCurrentUserId() {
            return UserPlaceholder(id: id)
        }
        return nil
    }
}

// Simple struct to satisfy 'currentUser.id' checks
struct UserPlaceholder {
    let id: String
    var email: String? = "" // Placeholder
}