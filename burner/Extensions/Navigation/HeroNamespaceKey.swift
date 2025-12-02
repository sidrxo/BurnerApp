//
//  HeroNamespaceKey.swift
//  burner
//
//  Created by Claude for hero transitions
//

import SwiftUI

// MARK: - Hero Namespace Environment Key
struct HeroNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var heroNamespace: Namespace.ID? {
        get { self[HeroNamespaceKey.self] }
        set { self[HeroNamespaceKey.self] = newValue }
    }
}

// MARK: - Settings Transition Namespace Environment Key
struct SettingsTransitionNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var settingsTransitionNamespace: Namespace.ID? {
        get { self[SettingsTransitionNamespaceKey.self] }
        set { self[SettingsTransitionNamespaceKey.self] = newValue }
    }
}
