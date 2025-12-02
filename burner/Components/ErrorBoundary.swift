// ErrorBoundary.swift
// Implements error boundary pattern for SwiftUI views

import SwiftUI
import Combine

/// Error Boundary View that catches and handles errors at feature boundaries
/// Prevents app crashes and shows fallback UI with retry options
struct ErrorBoundary<Content: View>: View {
    let content: () -> Content
    let errorTitle: String
    let errorMessage: String?
    let onRetry: () -> Void

    @State private var hasError = false
    @State private var errorDetails: String?

    init(
        errorTitle: String = "Something Went Wrong",
        errorMessage: String? = "An unexpected error occurred. Please try again.",
        onRetry: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.errorTitle = errorTitle
        self.errorMessage = errorMessage
        self.onRetry = onRetry
        self.content = content
    }

    var body: some View {
        Group {
            if hasError {
                errorView
            } else {
                content()
                    .onAppear {
                        // Reset error state when view appears
                        hasError = false
                        errorDetails = nil
                    }
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 24) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)

            // Error Title
            Text(errorTitle)
                .appSectionHeader()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Error Message
            if let message = errorMessage {
                Text(message)
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Error Details (Debug Only)
            
            if let details = errorDetails {
                Text("Debug: \(details)")
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            

            // Retry Button
            Button(action: {
                hasError = false
                errorDetails = nil
                onRetry()
            }) {
                Text("TRY AGAIN")
                    .font(.appFont(size: 17))
            }
            .buttonStyle(SecondaryButton(backgroundColor: .white, foregroundColor: .black))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    // MARK: - Error Capture Methods

    /// Manually set error state
    func setError(_ error: Error) {
        hasError = true
        errorDetails = error.localizedDescription

        
    }

    /// Manually set error state with custom message
    func setError(message: String) {
        hasError = true
        errorDetails = message

        
    }
}

// MARK: - Error Boundary Modifier
extension View {
    /// Wraps view in error boundary with automatic error handling
    func errorBoundary(
        errorTitle: String = "Something Went Wrong",
        errorMessage: String? = "An unexpected error occurred. Please try again.",
        onRetry: @escaping () -> Void
    ) -> some View {
        ErrorBoundary(
            errorTitle: errorTitle,
            errorMessage: errorMessage,
            onRetry: onRetry
        ) {
            self
        }
    }
}

// MARK: - Error State Wrapper
/// Observable wrapper for managing error states in features
@MainActor
class ErrorBoundaryState: ObservableObject {
    @Published var hasError = false
    @Published var errorTitle = "Something Went Wrong"
    @Published var errorMessage: String?
    @Published var errorDetails: String?

    func setError(
        _ error: Error,
        title: String = "Something Went Wrong",
        message: String? = nil
    ) {
        hasError = true
        errorTitle = title
        errorMessage = message ?? error.localizedDescription
        errorDetails = error.localizedDescription

        
    }

    func setError(
        title: String = "Something Went Wrong",
        message: String
    ) {
        hasError = true
        errorTitle = title
        errorMessage = message
        errorDetails = nil

        
    }

    func clearError() {
        hasError = false
        errorTitle = "Something Went Wrong"
        errorMessage = nil
        errorDetails = nil
    }
}

// MARK: - Preview
#Preview {
    ErrorBoundary(
        errorTitle: "Network Error",
        errorMessage: "Unable to load events. Please check your connection and try again.",
        onRetry: {
            print("Retry tapped")
        }
    ) {
        Text("Content goes here")
    }
    .preferredColorScheme(.dark)
}
