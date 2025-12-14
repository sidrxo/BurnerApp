
import Foundation
import FirebaseFunctions
@_spi(STP) import StripePaymentSheet
import StripeCore
import StripeApplePay
import Combine
import UIKit
import PassKit

@MainActor
class StripePaymentService: NSObject, ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var paymentSheet: PaymentSheet?
    @Published var currentPaymentIntentId: String?
    @Published var isPaymentSheetReady = false
    @Published var paymentMethods: [PaymentMethodInfo] = []
    
    @Published var isPreparing = false
    private var preparedClientSecret: String?
    private var preparedIntentId: String?
    private var preparedEventId: String?
    private var preparationTask: Task<Void, Never>?

    private let functions = Functions.functions(region: "europe-west2")
    
    // ADD THIS: Store reference to AppState
    private let appState: AppState

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

    // UPDATE THIS: Add appState parameter to init
    init(appState: AppState) {
        self.appState = appState
        super.init()
        StripeAPI.defaultPublishableKey = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
    }
    
    func preparePayment(eventId: String) {
        guard !isPreparing else { return }
        if preparedEventId == eventId, preparedIntentId != nil { return }
        
        preparationTask?.cancel()
        
        preparationTask = Task {
            await MainActor.run { self.isPreparing = true }
            do {
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
                guard !Task.isCancelled else {
                    await MainActor.run { self.isPreparing = false }
                    return
                }
                await MainActor.run {
                    self.preparedClientSecret = clientSecret
                    self.preparedIntentId = intentId
                    self.preparedEventId = eventId
                    self.isPreparing = false
                }
                Task {
                    try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000)
                    await self.clearPreparedIntent(ifMatching: intentId)
                }
            } catch {
                await MainActor.run { self.isPreparing = false }
            }
        }
    }
    
    private func clearPreparedIntent(ifMatching intentId: String) async {
        await MainActor.run {
            if self.preparedIntentId == intentId {
                self.preparedClientSecret = nil
                self.preparedIntentId = nil
                self.preparedEventId = nil
            }
        }
    }
    
    func clearPreparedIntent() {
        preparationTask?.cancel()
        preparedClientSecret = nil
        preparedIntentId = nil
        preparedEventId = nil
        isPreparing = false
    }

    private func callStripeFunction(
        _ name: String,
        data: [String: Any]? = nil
    ) async throws -> [String: Any] {
        guard appState.authService.currentUser != nil else {
            throw PaymentError.notAuthenticated
        }
        
        let callable = functions.httpsCallable(name)
        let result: HTTPSCallableResult
        if let data = data {
            result = try await callable.call(data)
        } else {
            result = try await callable.call()
        }
        
        guard let payload = result.data as? [String: Any] else {
            throw PaymentError.invalidResponse
        }
        
        return payload
    }
    
    /// Helper that returns either a pre-created payment intent (when available) or creates a new one.
    private func withPaymentIntent(
        eventId: String,
        usePreparedIfAvailable: Bool = false
    ) async throws -> (clientSecret: String, paymentIntentId: String) {
        if usePreparedIfAvailable,
           let preparedId = preparedIntentId,
           let secret = preparedClientSecret,
           preparedEventId == eventId {
            // Consume the prepared intent
            await MainActor.run {
                self.preparedClientSecret = nil
                self.preparedIntentId = nil
                self.preparedEventId = nil
            }
            return (secret, preparedId)
        } else {
            return try await createPaymentIntent(eventId: eventId)
        }
    }
    
    /// Shared confirmation + ticket creation + haptics handling for non-PaymentSheet flows.
    private func handleConfirmationResult(
        paymentIntent: STPPaymentIntent?,
        error: Error?,
        intentId: String,
        logPrefix: String,
        completion: @escaping (PaymentResult) -> Void
    ) async {
        if let error = error {
            await MainActor.run { self.isProcessing = false }
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
            await MainActor.run { self.isProcessing = false }
            completion(PaymentResult(
                success: false,
                message: "Payment was not completed",
                ticketId: nil
            ))
            return
        }
        
        do {
            let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
            await MainActor.run {
                self.isProcessing = false
                // Success haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
            completion(ticketResult)
        } catch {
            await MainActor.run { self.isProcessing = false }
            
            print("❌ \(logPrefix) Ticket Creation Error: \(error.localizedDescription)")
            
            completion(PaymentResult(
                success: false,
                message: PaymentError.processingError.errorDescription ?? "Payment processing error",
                ticketId: nil
            ))
        }
    }

    func processPayment(eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        guard !isProcessing else { return }
        
        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }
            
            do {
                let (clientSecret, intentId) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: false)
                await MainActor.run { self.currentPaymentIntentId = intentId }
                
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "BURNER"
                configuration.applePay = .init(
                    merchantId: "merchant.BurnerTickets",
                    merchantCountryCode: "GB"
                )
                configuration.defaultBillingDetails.address = .init(country: "GB")
                configuration.allowsDelayedPaymentMethods = false
                
                var appearance = PaymentSheet.Appearance()
                appearance.primaryButton.backgroundColor = .black
                configuration.appearance = appearance
                
                await MainActor.run {
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: clientSecret,
                        configuration: configuration
                    )
                    self.isProcessing = false
                    self.isPaymentSheetReady = true
                }
                
            } catch {
                let nsError = error as NSError
                let msg: String = (nsError.domain == "FIRFunctionsErrorDomain")
                ? ((nsError.userInfo["details"] as? String) ?? nsError.localizedDescription)
                : nsError.localizedDescription

                print("❌ Payment Sheet Setup Error: \(msg)")
                
                await MainActor.run {
                    self.isProcessing = false
                    self.isPaymentSheetReady = false
                    self.errorMessage = msg
                }
                completion(PaymentResult(success: false, message: "Setup failed: \(msg)", ticketId: nil))
            }
        }
    }
    
    // -------------------------
    // Handle Payment Sheet Result
    // -------------------------
    func onPaymentCompletion(result: PaymentSheetResult, paymentIntentId: String, completion: @escaping (PaymentResult) -> Void) {
        Task {
            do {
                switch result {
                case .completed:
                    let ticketResult = try await confirmPurchase(paymentIntentId: paymentIntentId)
                    completion(ticketResult)
                case .canceled:
                    completion(PaymentResult(success: false, message: "Payment was cancelled", ticketId: nil))
                case .failed(let error):
                    completion(PaymentResult(success: false, message: error.localizedDescription, ticketId: nil))
                }
            } catch {
                completion(PaymentResult(success: false, message: error.localizedDescription, ticketId: nil))
            }
            await MainActor.run {
                self.isPaymentSheetReady = false
            }
        }
    }

    // -------------------------
    // Create Payment Intent
    // -------------------------
    private func createPaymentIntent(eventId: String) async throws -> (clientSecret: String, paymentIntentId: String) {
        let data = try await callStripeFunction("createPaymentIntent", data: ["eventId": eventId])
        guard let clientSecret = data["clientSecret"] as? String,
              let paymentIntentId = data["paymentIntentId"] as? String else {
            throw PaymentError.invalidResponse
        }
        return (clientSecret, paymentIntentId)
    }

    // -------------------------
    // Confirm Purchase (Create Ticket) with Retry Logic
    // -------------------------
    private func confirmPurchase(paymentIntentId: String, retryCount: Int = 0) async throws -> PaymentResult {
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

    func processApplePayPayment(
        eventName: String,
        amount: Double,
        eventId: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard !isProcessing else { return }

        Task {
            do {
                // Use prepared intent if available for this event
                let (clientSecret, intentId) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: true)

                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }

                await MainActor.run {
                    ApplePayHandler.shared.startPayment(
                        eventName: eventName,
                        amount: amount,
                        onSuccess: { payment in
                            Task {
                                await MainActor.run {
                                    self.isProcessing = true
                                    self.errorMessage = nil
                                }

                                let apiClient = STPAPIClient.shared
                                apiClient.createPaymentMethod(with: payment) { paymentMethod, error in
                                    Task {
                                        if let error = error {
                                            await MainActor.run { self.isProcessing = false }
                                            let paymentError = PaymentError.from(stripeError: error)
                                            
                                            print("❌ Apple Pay Payment Method Error: \(error.localizedDescription)")
                                            
                                            completion(PaymentResult(
                                                success: false,
                                                message: paymentError.errorDescription ?? error.localizedDescription,
                                                ticketId: nil
                                            ))
                                            return
                                        }

                                        guard let paymentMethod = paymentMethod else {
                                            await MainActor.run { self.isProcessing = false }
                                            completion(PaymentResult(
                                                success: false,
                                                message: "Failed to create payment method",
                                                ticketId: nil
                                            ))
                                            return
                                        }

                                        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                                        paymentIntentParams.paymentMethodId = paymentMethod.stripeId

                                        apiClient.confirmPaymentIntent(with: paymentIntentParams) { confirmResult, confirmError in
                                            Task {
                                                await self.handleConfirmationResult(
                                                    paymentIntent: confirmResult,
                                                    error: confirmError,
                                                    intentId: intentId,
                                                    logPrefix: "Apple Pay",
                                                    completion: completion
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        onFailure: { error in
                            Task {
                                await MainActor.run { self.isProcessing = false }
                                completion(PaymentResult(
                                    success: false,
                                    message: "Apple Pay failed: \(error.localizedDescription)",
                                    ticketId: nil
                                ))
                            }
                        },
                        onCancelled: {
                            Task {
                                await MainActor.run { self.isProcessing = false }
                                completion(PaymentResult(
                                    success: false,
                                    message: "",
                                    ticketId: nil
                                ))
                            }
                        }
                    )
                }

            } catch {
                let nsError = error as NSError
                let errorMessage: String = (nsError.domain == "FIRFunctionsErrorDomain")
                ? ((nsError.userInfo["details"] as? String) ?? nsError.localizedDescription)
                : nsError.localizedDescription

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
            }
        }
    }

    func processCardPayment(cardParams: STPPaymentMethodCardParams, eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        guard !isProcessing else { return }

        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }

            do {
                let (clientSecret, intentId) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: false)
                await MainActor.run { self.currentPaymentIntentId = intentId }

                let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
                let apiClient = STPAPIClient.shared

                let (paymentMethod, pmError) = await withCheckedContinuation { continuation in
                    apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                        continuation.resume(returning: (paymentMethod, error))
                    }
                }

                if let pmError = pmError {
                    await MainActor.run { self.isProcessing = false }
                    let paymentError = PaymentError.from(stripeError: pmError)
                    
                    print("❌ Payment Method Error: \(pmError.localizedDescription)")
                    
                    completion(PaymentResult(success: false, message: paymentError.errorDescription ?? pmError.localizedDescription, ticketId: nil))
                    return
                }

                guard let paymentMethod = paymentMethod else {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(success: false, message: "Failed to create payment method", ticketId: nil))
                    return
                }

                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentMethod.stripeId

                let (confirmResult, confirmError) = await withCheckedContinuation { continuation in
                    apiClient.confirmPaymentIntent(with: paymentIntentParams) { result, error in
                        continuation.resume(returning: (result, error))
                    }
                }

                await handleConfirmationResult(
                    paymentIntent: confirmResult,
                    error: confirmError,
                    intentId: intentId,
                    logPrefix: "Card Payment",
                    completion: completion
                )

            } catch {
                let nsError = error as NSError
                let errorMessage: String = (nsError.domain == "FIRFunctionsErrorDomain")
                ? ((nsError.userInfo["details"] as? String) ?? nsError.localizedDescription)
                : nsError.localizedDescription

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
            }
        }
    }

    func fetchPaymentMethods() async throws {
        let data = try await callStripeFunction("getPaymentMethods")
        
        guard let methods = data["paymentMethods"] as? [[String: Any]] else {
            throw PaymentError.invalidResponse
        }

        let paymentMethodInfos = methods.compactMap { methodData -> PaymentMethodInfo? in
            guard let id = methodData["id"] as? String,
                  let brand = methodData["brand"] as? String,
                  let last4 = methodData["last4"] as? String,
                  let expMonth = methodData["expMonth"] as? Int,
                  let expYear = methodData["expYear"] as? Int,
                  let isDefault = methodData["isDefault"] as? Bool else {
                return nil
            }
            return PaymentMethodInfo(
                id: id,
                brand: brand,
                last4: last4,
                expMonth: expMonth,
                expYear: expYear,
                isDefault: isDefault
            )
        }

        await MainActor.run {
            self.paymentMethods = paymentMethodInfos
        }
    }

    func savePaymentMethod(cardParams: STPPaymentMethodCardParams, setAsDefault: Bool = false) async throws {
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let apiClient = STPAPIClient.shared

        let (paymentMethod, error) = await withCheckedContinuation { continuation in
            apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                continuation.resume(returning: (paymentMethod, error))
            }
        }

        if let error = error { throw error }
        guard let paymentMethod = paymentMethod else { throw PaymentError.paymentFailed }

        let data = try await callStripeFunction("savePaymentMethod", data: [
            "paymentMethodId": paymentMethod.stripeId,
            "setAsDefault": setAsDefault
        ])

        guard let success = data["success"] as? Bool, success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    func deletePaymentMethod(paymentMethodId: String) async throws {
        let data = try await callStripeFunction("deletePaymentMethod", data: [
            "paymentMethodId": paymentMethodId
        ])

        guard let success = data["success"] as? Bool, success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    func setDefaultPaymentMethod(paymentMethodId: String) async throws {
        let data = try await callStripeFunction("setDefaultPaymentMethod", data: [
            "paymentMethodId": paymentMethodId
        ])

        guard let success = data["success"] as? Bool, success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    func processSavedCardPayment(
        paymentMethodId: String,
        eventName: String,
        amount: Double,
        eventId: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard !isProcessing else { return }

        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }

            do {
                let (clientSecret, intentId) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: false)
                await MainActor.run { self.currentPaymentIntentId = intentId }

                let stripe = STPAPIClient.shared
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentMethodId

                let (confirmResult, confirmError) = await withCheckedContinuation { continuation in
                    stripe.confirmPaymentIntent(with: paymentIntentParams) { result, error in
                        continuation.resume(returning: (result, error))
                    }
                }

                await handleConfirmationResult(
                    paymentIntent: confirmResult,
                    error: confirmError,
                    intentId: intentId,
                    logPrefix: "Saved Card",
                    completion: completion
                )

            } catch {
                let nsError = error as NSError
                let errorMessage: String = (nsError.domain == "FIRFunctionsErrorDomain")
                ? ((nsError.userInfo["details"] as? String) ?? nsError.localizedDescription)
                : nsError.localizedDescription

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
            }
        }
    }

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
}
