import Foundation

struct PaymentMethodInfo: Identifiable {
    let id: String
    let brand: String
    let last4: String
    let expMonth: Int
    let expYear: Int
    let isDefault: Bool
}

struct PaymentResult {
    let success: Bool
    let message: String
    let ticketId: String?
}
