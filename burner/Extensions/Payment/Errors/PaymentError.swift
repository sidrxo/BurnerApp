import Foundation

enum PaymentError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case paymentFailed
    case cancelled
    case cardDeclined
    case insufficientFunds
    case expiredCard
    case networkError
    case invalidCard
    case processingError
    case ticketCreationFailed
    case eventSoldOut

    nonisolated var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to purchase tickets"
        case .invalidResponse:
            return "Invalid response from server. Please try again."
        case .paymentFailed:
            return "Payment failed. Please try again"
        case .cancelled:
            return "Payment was cancelled"
        case .cardDeclined:
            return "Card declined. Please try another payment method"
        case .insufficientFunds:
            return "Insufficient funds. Please use another card"
        case .expiredCard:
            return "Card expired. Please update your payment method"
        case .networkError:
            return "Network error. Please check your connection and try again"
        case .invalidCard:
            return "Invalid card details. Please check and try again"
        case .processingError:
            return "Payment succeeded but ticket creation failed. Please contact support."
        case .ticketCreationFailed:
            return "Failed to create ticket. Please contact support if you were charged."
        case .eventSoldOut:
            return "This event is sold out"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .networkError, .processingError, .invalidResponse:
            return true
        default:
            return false
        }
    }

    var requiresSupport: Bool {
        switch self {
        case .processingError, .ticketCreationFailed:
            return true
        default:
            return false
        }
    }

    static func from(stripeError: Error) -> PaymentError {
        let errorString = stripeError.localizedDescription.lowercased()

        if errorString.contains("declined") {
            return .cardDeclined
        } else if errorString.contains("insufficient") {
            return .insufficientFunds
        } else if errorString.contains("expired") {
            return .expiredCard
        } else if errorString.contains("invalid") {
            return .invalidCard
        } else if errorString.contains("network") || errorString.contains("connection") {
            return .networkError
        } else {
            return .paymentFailed
        }
    }
}
