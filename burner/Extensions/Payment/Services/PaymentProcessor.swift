import Foundation
import FirebaseFunctions
@_spi(STP) import StripePaymentSheet
import StripeCore
import UIKit

/// Handles payment confirmation, ticket creation, and shared payment flow logic
@MainActor
class PaymentProcessor: ObservableObject {
    private let functions = Functions.functions(region: "europe-west2")

    // MARK: - Payment Confirmation

    /// Shared confirmation + ticket creation + haptics handling for payment flows
    func handleConfirmationResult(
        paymentIntent: STPPaymentIntent?,
        error: Error?,
        intentId: String,
        logPrefix: String,
        completion: @escaping (PaymentResult) -> Void
    ) async {
        if let error = error {
            let paymentError = PaymentError.from(stripeError: error)
            print("❌ \(logPrefix) Confirmation Error: \(error.localizedDescription)")
            completion(PaymentResult(
                success: false,
                message: paymentError.errorDescription ?? error.localizedDescription,
                ticketId: nil
            ))
            return
        }

        guard let paymentIntent = paymentIntent, paymentIntent.status == .succeeded else {
            completion(PaymentResult(
                success: false,
                message: "Payment was not completed",
                ticketId: nil
            ))
            return
        }

        do {
            let ticketResult = try await confirmPurchase(paymentIntentId: intentId)
            await MainActor.run {
                // Success haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
            completion(ticketResult)
        } catch {
            print("❌ \(logPrefix) Ticket Creation Error: \(error.localizedDescription)")
            completion(PaymentResult(
                success: false,
                message: PaymentError.processingError.errorDescription ?? "Payment processing error",
                ticketId: nil
            ))
        }
    }

    // MARK: - Ticket Creation

    /// Confirms purchase and creates ticket with retry logic
    func confirmPurchase(paymentIntentId: String, retryCount: Int = 0) async throws -> PaymentResult {
        let maxRetries = 3
        let baseDelay: UInt64 = 1_000_000_000 // 1 second in nanoseconds

        do {
            let result = try await functions.httpsCallable("confirmPurchase").call(["paymentIntentId": paymentIntentId])
            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool else {
                throw PaymentError.invalidResponse
            }
            let message = data["message"] as? String ?? "Purchase completed"
            let ticketId = data["ticketId"] as? String
            return PaymentResult(success: success, message: message, ticketId: ticketId)

        } catch {
            // Check if error is network-related and retryable
            let nsError = error as NSError
            let isNetworkError = nsError.domain == NSURLErrorDomain ||
                                nsError.code == NSURLErrorNotConnectedToInternet ||
                                nsError.code == NSURLErrorTimedOut ||
                                nsError.code == NSURLErrorNetworkConnectionLost

            if isNetworkError && retryCount < maxRetries {
                // Exponential backoff: 1s, 2s, 4s
                let delay = baseDelay * UInt64(pow(2.0, Double(retryCount)))
                print("⚠️ [Payment] Network error, retrying (\(retryCount + 1)/\(maxRetries)) after \(delay / 1_000_000_000)s...")

                try await Task.sleep(nanoseconds: delay)
                return try await confirmPurchase(paymentIntentId: paymentIntentId, retryCount: retryCount + 1)
            } else {
                throw error
            }
        }
    }

    // MARK: - Card Payment Processing

    /// Processes a manual card payment
    func processCardPayment(
        cardParams: STPPaymentMethodCardParams,
        clientSecret: String,
        completion: @escaping (STPPaymentIntent?, Error?) -> Void
    ) async {
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let apiClient = STPAPIClient.shared

        let (paymentMethod, pmError) = await withCheckedContinuation { continuation in
            apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                continuation.resume(returning: (paymentMethod, error))
            }
        }

        if let pmError = pmError {
            completion(nil, pmError)
            return
        }

        guard let paymentMethod = paymentMethod else {
            let error = NSError(
                domain: "PaymentProcessor",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create payment method"]
            )
            completion(nil, error)
            return
        }

        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodId = paymentMethod.stripeId

        let (confirmResult, confirmError) = await withCheckedContinuation { continuation in
            apiClient.confirmPaymentIntent(with: paymentIntentParams) { result, error in
                continuation.resume(returning: (result, error))
            }
        }

        completion(confirmResult, confirmError)
    }

    // MARK: - Saved Card Payment Processing

    /// Processes a payment with a saved payment method
    func processSavedCardPayment(
        paymentMethodId: String,
        clientSecret: String,
        completion: @escaping (STPPaymentIntent?, Error?) -> Void
    ) async {
        let stripe = STPAPIClient.shared
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        paymentIntentParams.paymentMethodId = paymentMethodId

        let (confirmResult, confirmError) = await withCheckedContinuation { continuation in
            stripe.confirmPaymentIntent(with: paymentIntentParams) { result, error in
                continuation.resume(returning: (result, error))
            }
        }

        completion(confirmResult, confirmError)
    }
}
