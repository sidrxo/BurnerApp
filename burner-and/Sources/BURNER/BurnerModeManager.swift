//
//  BurnerModeManager.swift
//  burner-and
//
//  Created by Sid Rao on 09/12/2025.
//


import Foundation
import Combine

// A "Fake" manager that allows the rest of the app to compile on Android
@MainActor
class BurnerModeManager: ObservableObject {
    @Published var isLocked = false
    @Published var isSetupValid = true // Always valid on Android for MVP
    @Published var selectedApps = FamilyActivitySelectionStub() 
    @Published var hasCompletedSetup = true
    
    func checkSetupCompliance() -> Bool { return true }
    func enable(appState: AppState) async throws { isLocked = true }
    func disable() { isLocked = false }
    func clearAllSelections() {}
    func checkAndScheduleEventDayReminder(tickets: [Ticket]) {}
    
    // Stub for the selection object
    struct FamilyActivitySelectionStub: Codable {
        var applicationTokens: Set<String> = []
        var categoryTokens: Set<String> = []
    }
}