import Foundation
import FirebaseAuth
import FirebaseFunctions
import PassKit
import Combine

@MainActor
class StripePaymentService: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let functions = Functions.functions(region: "us-central1")
    private var currentPaymentTask: Task<Void, Never>?
    private var paymentCompletion: ((PaymentResult) -> Void)?
    private var currentClientSecret: String?
    private var currentPaymentIntentId: String?

    struct PaymentResult {
        let success: Bool
        let message: String
        let ticketId: String?
    }

    // -------------------------
    // Create Payment Intent
    // -------------------------
    func createPaymentIntent(eventId: String) async throws -> (clientSecret: String, paymentIntentId: String) {
        guard Auth.auth().currentUser != nil else { throw PaymentError.notAuthenticated }
        let result = try await functions.httpsCallable("createPaymentIntent").call(["eventId": eventId])
        guard let data = result.data as? [String: Any],
              let clientSecret = data["clientSecret"] as? String,
              let paymentIntentId = data["paymentIntentId"] as? String else {
            throw PaymentError.invalidResponse
        }
        return (clientSecret, paymentIntentId)
    }

    // -------------------------
    // Apple Pay Payment Flow
    // -------------------------
    func processApplePayPayment(eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        guard !isProcessing else { return }
        currentPaymentTask?.cancel()
        currentPaymentTask = Task {
            do {
                isProcessing = true
                let (clientSecret, paymentIntentId) = try await createPaymentIntent(eventId: eventId)
                currentClientSecret = clientSecret
                currentPaymentIntentId = paymentIntentId
                paymentCompletion = completion
                await presentApplePaySheet(eventName: eventName, amount: amount)
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    completion(PaymentResult(success: false, message: error.localizedDescription, ticketId: nil))
                }
            }
        }
    }

    // -------------------------
    // Present Apple Pay
    // -------------------------
    private func presentApplePaySheet(eventName: String, amount: Double) async {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.BurnerTickets"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .capability3DS
        request.countryCode = "GB"
        request.currencyCode = "GBP"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Ticket: \(eventName)", amount: NSDecimalNumber(value: amount)),
            PKPaymentSummaryItem(label: "Burner", amount: NSDecimalNumber(value: amount))
        ]

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            controller.present { presented in
                if !presented {
                    Task { @MainActor in
                        self.isProcessing = false
                        self.paymentCompletion?(PaymentResult(success: false, message: "Failed to present Apple Pay", ticketId: nil))
                        self.paymentCompletion = nil
                    }
                }
                continuation.resume()
            }
        }
    }

    // -------------------------
    // Confirm Purchase
    // -------------------------
    func confirmPurchase(paymentIntentId: String) async throws -> PaymentResult {
        let result = try await functions.httpsCallable("confirmPurchase").call(["paymentIntentId": paymentIntentId])
        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool else { throw PaymentError.invalidResponse }

        let message = data["message"] as? String ?? "Purchase completed"
        let ticketId = data["ticketId"] as? String
        return PaymentResult(success: success, message: message, ticketId: ticketId)
    }

    // -------------------------
    // Payment Errors
    // -------------------------
    enum PaymentError: LocalizedError {
        case notAuthenticated, invalidResponse, paymentFailed, cancelled
        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "Please sign in to purchase tickets"
            case .invalidResponse: return "Invalid response from server"
            case .paymentFailed: return "Payment failed. Please try again"
            case .cancelled: return "Payment was cancelled"
            }
        }
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate
extension StripePaymentService: PKPaymentAuthorizationControllerDelegate {
    nonisolated func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                                   didAuthorizePayment payment: PKPayment,
                                                   handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        Task { @MainActor in
            do {
                guard let paymentIntentId = self.currentPaymentIntentId else { throw PaymentError.paymentFailed }
                let tokenData = payment.token.paymentData.base64EncodedString()
                
                // Call backend to confirm Apple Pay payment
                let result = try await functions.httpsCallable("confirmApplePayPayment").call([
                    "paymentIntentId": paymentIntentId,
                    "paymentToken": tokenData
                ])
                
                guard let data = result.data as? [String: Any],
                      let status = data["status"] as? String,
                      status == "succeeded" else {
                    throw PaymentError.paymentFailed
                }
                
                // Now call confirmPurchase to create ticket
                let ticketResult = try await confirmPurchase(paymentIntentId: paymentIntentId)
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                
                self.isProcessing = false
                self.paymentCompletion?(ticketResult)
                self.paymentCompletion = nil
            } catch {
                completion(PKPaymentAuthorizationResult(status: .failure, errors: nil))
                self.isProcessing = false
                self.paymentCompletion?(PaymentResult(success: false, message: error.localizedDescription, ticketId: nil))
                self.paymentCompletion = nil
            }
        }
    }

    nonisolated func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
