//
//  HeroNamespaceKey.swift
//  burner
//
//  Created by Claude for hero transitions
//

import SwiftUI
import Combine


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
