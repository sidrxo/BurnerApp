import Foundation
import SwiftUI
import Combine

@MainActor
class ErrorManager: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false

    // Show error with automatic dismissal
    func showError(_ error: AppError) {
        currentError = error
        showingError = true
    }

    // Show error from string
    func showError(_ message: String, severity: ErrorSeverity = .error) {
        showError(AppError(message: message, severity: severity))
    }

    // Show error from Error
    func showError(_ error: Error, context: String? = nil) {
        let message = context != nil ? "\(context!): \(error.localizedDescription)" : error.localizedDescription
        showError(AppError(message: message, severity: .error))
    }

    // Clear current error
    func clearError() {
        currentError = nil
        showingError = false
    }

    // Log error without showing UI
    func logError(_ error: Error, context: String? = nil) {
        // Error logging removed - errors are handled through UI
    }

    // Log success
    func logSuccess(_ message: String) {
        // Success logging removed - handled through UI
    }
}

// MARK: - App Error Model
struct AppError: Identifiable {
    let id = UUID()
    let message: String
    let severity: ErrorSeverity
    let timestamp = Date()

    init(message: String, severity: ErrorSeverity = .error) {
        self.message = message
        self.severity = severity
    }
}

// MARK: - Error Severity
enum ErrorSeverity {    
    case info
    case warning
    case error
    case critical

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
}
