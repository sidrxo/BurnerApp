import Foundation
import FirebaseAuth
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
    
    // ✅ NEW: Payment Intent Pre-creation Properties
    @Published var isPreparing = false
    private var preparedClientSecret: String?
    private var preparedIntentId: String?
    private var preparedEventId: String?
    private var preparationTask: Task<Void, Never>?

    private let functions = Functions.functions(region: "europe-west2")

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

    override init() {
        super.init()
        // TODO: Move this to an env/remote-config before production.
        StripeAPI.defaultPublishableKey = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"

        if StripeAPI.defaultPublishableKey == "PK_TEST" {
            print("⚠️ WARNING: Stripe publishable key not set! Get it from https://dashboard.stripe.com/test/apikeys")
        }
    }
    
    // -------------------------
    // ✅ NEW: Payment Intent Pre-creation
    // -------------------------
    
    /// Pre-creates a payment intent in the background to improve Apple Pay UX
    /// This should be called when the purchase view appears, not when the button is tapped
    func preparePayment(eventId: String) {
        // Don't prepare if already preparing or if we have a prepared intent for this event
        guard !isPreparing else {
            print("⚠️ Already preparing payment, skipping")
            return
        }
        
        // If we already have a prepared intent for this event, don't create another
        if preparedEventId == eventId, preparedIntentId != nil {
            print("✅ Payment intent already prepared for event: \(eventId)")
            return
        }
        
        // Cancel any existing preparation task
        preparationTask?.cancel()
        
        // Start new preparation
        preparationTask = Task {
            await MainActor.run { self.isPreparing = true }
            
            do {
                print("🔵 Pre-creating payment intent for event: \(eventId)")
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
                
                // Only save if we weren't cancelled
                guard !Task.isCancelled else {
                    print("⚠️ Payment preparation cancelled")
                    await MainActor.run { self.isPreparing = false }
                    return
                }
                
                await MainActor.run {
                    self.preparedClientSecret = clientSecret
                    self.preparedIntentId = intentId
                    self.preparedEventId = eventId
                    self.isPreparing = false
                }
                
                print("✅ Payment intent pre-created successfully: \(intentId)")
                
                // Schedule cleanup after 10 minutes (payment intents expire after 24h, but we refresh earlier)
                Task {
                    try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000) // 10 minutes
                    await self.clearPreparedIntent(ifMatching: intentId)
                }
                
            } catch {
                print("⚠️ Failed to pre-create payment intent: \(error.localizedDescription)")
                await MainActor.run { self.isPreparing = false }
            }
        }
    }
    
    /// Clears the prepared payment intent if it matches the given ID
    private func clearPreparedIntent(ifMatching intentId: String) async {
        await MainActor.run {
            if self.preparedIntentId == intentId {
                print("🧹 Clearing expired prepared payment intent: \(intentId)")
                self.preparedClientSecret = nil
                self.preparedIntentId = nil
                self.preparedEventId = nil
            }
        }
    }
    
    /// Clears any prepared payment intent (call this when leaving the purchase screen)
    func clearPreparedIntent() {
        preparationTask?.cancel()
        preparedClientSecret = nil
        preparedIntentId = nil
        preparedEventId = nil
        isPreparing = false
    }

    // -------------------------
    // Process Payment with Payment Sheet
    // -------------------------
    func processPayment(eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        guard !isProcessing else {
            print("⚠️ Payment already in progress, ignoring duplicate call")
            return
        }
        
        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }
            
            do {
                print("🔵 Creating payment intent for event: \(eventId)")
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
                print("✅ Payment intent created: \(intentId)")
                
                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }
                
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Burner"
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
                
            } catch let error as NSError {
                if error.domain == "FIRFunctionsErrorDomain" {
                    let msg = (error.userInfo["details"] as? String) ?? error.localizedDescription
                    await MainActor.run {
                        self.isProcessing = false
                        self.isPaymentSheetReady = false
                        self.errorMessage = msg
                        completion(PaymentResult(success: false, message: msg, ticketId: nil))
                    }
                } else {
                    await MainActor.run {
                        self.isProcessing = false
                        self.isPaymentSheetReady = false
                        self.errorMessage = error.localizedDescription
                        completion(PaymentResult(success: false, message: "Setup failed: \(error.localizedDescription)", ticketId: nil))
                    }
                }
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
        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }
        
        do {
            let result = try await functions.httpsCallable("createPaymentIntent").call(["eventId": eventId])
            guard let data = result.data as? [String: Any],
                  let clientSecret = data["clientSecret"] as? String,
                  let paymentIntentId = data["paymentIntentId"] as? String else {
                throw PaymentError.invalidResponse
            }
            return (clientSecret, paymentIntentId)
        } catch {
            throw error
        }
    }

    // -------------------------
    // Confirm Purchase (Create Ticket)
    // -------------------------
    private func confirmPurchase(paymentIntentId: String) async throws -> PaymentResult {
        let result = try await functions.httpsCallable("confirmPurchase").call(["paymentIntentId": paymentIntentId])
        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool else {
            throw PaymentError.invalidResponse
        }
        let message = data["message"] as? String ?? "Purchase completed"
        let ticketId = data["ticketId"] as? String
        return PaymentResult(success: success, message: message, ticketId: ticketId)
    }

    // -------------------------
    // ✅ UPDATED: Process Apple Pay Payment (Custom Flow) — now with pre-creation support
    // -------------------------
    func processApplePayPayment(
        eventName: String,
        amount: Double,
        eventId: String,
        trace: PaymentTrace? = nil,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard !isProcessing else {
            trace?.mark("blocked.isProcessing")
            print("⚠️ Payment already in progress, ignoring duplicate call")
            return
        }

        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }

            do {
                // ✅ OPTIMIZATION: Use prepared intent if available for this event
                let (clientSecret, intentId): (String, String)
                
                if let prepared = preparedIntentId,
                   let secret = preparedClientSecret,
                   preparedEventId == eventId {
                    // Use the pre-created payment intent
                    print("✅ Using pre-created payment intent: \(prepared)")
                    trace?.mark("using.preparedIntent", extra: "intentId=\(prepared)")
                    clientSecret = secret
                    intentId = prepared
                    
                    // Clear the prepared state immediately so it's not reused
                    await MainActor.run {
                        self.preparedClientSecret = nil
                        self.preparedIntentId = nil
                        self.preparedEventId = nil
                    }
                } else {
                    // Fallback: create payment intent on demand
                    print("⚠️ No prepared intent available, creating on demand")
                    trace?.mark("createPaymentIntent.begin")
                    let result = try await createPaymentIntent(eventId: eventId)
                    clientSecret = result.0
                    intentId = result.1
                    trace?.mark("createPaymentIntent.end", extra: "intentId=\(intentId)")
                }

                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }

                trace?.mark("ApplePayHandler.start")
                await MainActor.run {
                    ApplePayHandler.shared.startPayment(
                        eventName: eventName,
                        amount: amount,
                        onSuccess: { payment in
                            trace?.mark("applePay.authorized")

                            Task {
                                let apiClient = STPAPIClient.shared

                                trace?.mark("createPaymentMethod.begin")
                                apiClient.createPaymentMethod(with: payment) { paymentMethod, error in
                                    Task {
                                        if let error = error {
                                            trace?.mark("createPaymentMethod.error", extra: error.localizedDescription)
                                            await MainActor.run { self.isProcessing = false }
                                            completion(PaymentResult(
                                                success: false,
                                                message: "Failed to process Apple Pay: \(error.localizedDescription)",
                                                ticketId: nil
                                            ))
                                            return
                                        }

                                        guard let paymentMethod = paymentMethod else {
                                            trace?.mark("createPaymentMethod.nil")
                                            await MainActor.run { self.isProcessing = false }
                                            completion(PaymentResult(
                                                success: false,
                                                message: "Failed to create payment method",
                                                ticketId: nil
                                            ))
                                            return
                                        }
                                        trace?.mark("createPaymentMethod.end", extra: "pm=\(paymentMethod.stripeId)")

                                        // Confirm the payment intent
                                        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                                        paymentIntentParams.paymentMethodId = paymentMethod.stripeId

                                        trace?.mark("confirmPaymentIntent.begin")
                                        apiClient.confirmPaymentIntent(with: paymentIntentParams) { confirmResult, confirmError in
                                            Task {
                                                if let confirmError = confirmError {
                                                    trace?.mark("confirmPaymentIntent.error", extra: confirmError.localizedDescription)
                                                    await MainActor.run { self.isProcessing = false }
                                                    completion(PaymentResult(
                                                        success: false,
                                                        message: "Payment failed: \(confirmError.localizedDescription)",
                                                        ticketId: nil
                                                    ))
                                                    return
                                                }

                                                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
                                                    trace?.mark("confirmPaymentIntent.succeeded")
                                                    // Create ticket on backend
                                                    do {
                                                        trace?.mark("confirmPurchase.begin")
                                                        let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
                                                        trace?.mark("confirmPurchase.end", extra: "success=\(ticketResult.success) ticketId=\(ticketResult.ticketId ?? "nil")")
                                                        await MainActor.run { self.isProcessing = false }
                                                        completion(ticketResult)
                                                    } catch {
                                                        trace?.mark("confirmPurchase.error", extra: error.localizedDescription)
                                                        await MainActor.run { self.isProcessing = false }
                                                        completion(PaymentResult(
                                                            success: false,
                                                            message: "Payment succeeded but ticket creation failed: \(error.localizedDescription)",
                                                            ticketId: nil
                                                        ))
                                                    }
                                                } else {
                                                    trace?.mark("confirmPaymentIntent.notSucceeded", extra: "status=\(String(confirmResult?.status.rawValue ?? -1))")
                                                    await MainActor.run { self.isProcessing = false }
                                                    completion(PaymentResult(
                                                        success: false,
                                                        message: "Payment was not completed",
                                                        ticketId: nil
                                                    ))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        },
                        onFailure: { error in
                            trace?.mark("applePay.failed", extra: error.localizedDescription)
                            Task {
                                await MainActor.run { self.isProcessing = false }
                                completion(PaymentResult(
                                    success: false,
                                    message: "Apple Pay failed: \(error.localizedDescription)",
                                    ticketId: nil
                                ))
                            }
                        }
                    )
                }

            } catch let error as NSError {
                trace?.mark("setup.error", extra: error.localizedDescription)
                let errorMessage: String
                if error.domain == "FIRFunctionsErrorDomain" {
                    errorMessage = (error.userInfo["details"] as? String) ?? error.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
            }
        }
    }

    // -------------------------
    // Process Card Payment
    // -------------------------
    func processCardPayment(cardParams: STPPaymentMethodCardParams, eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        guard !isProcessing else {
            print("⚠️ Payment already in progress, ignoring duplicate call")
            return
        }

        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }

            do {
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
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
                    completion(PaymentResult(success: false, message: "Failed to process card: \(pmError.localizedDescription)", ticketId: nil))
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

                if let confirmError = confirmError {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(success: false, message: "Payment failed: \(confirmError.localizedDescription)", ticketId: nil))
                    return
                }

                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
                    do {
                        let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
                        await MainActor.run { self.isProcessing = false }
                        completion(ticketResult)
                    } catch {
                        await MainActor.run { self.isProcessing = false }
                        completion(PaymentResult(success: false, message: "Payment succeeded but ticket creation failed: \(error.localizedDescription)", ticketId: nil))
                    }
                } else {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(success: false, message: "Payment was not completed", ticketId: nil))
                }

            } catch let error as NSError {
                let errorMessage: String
                if error.domain == "FIRFunctionsErrorDomain" {
                    errorMessage = (error.userInfo["details"] as? String) ?? error.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
            }
        }
    }

    // -------------------------
    // Fetch Payment Methods
    // -------------------------
    func fetchPaymentMethods() async throws {
        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }

        let result = try await functions.httpsCallable("getPaymentMethods").call()
        guard let data = result.data as? [String: Any],
              let methods = data["paymentMethods"] as? [[String: Any]] else {
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
        guard Auth.auth().currentUser != nil else { throw PaymentError.notAuthenticated }

        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let apiClient = STPAPIClient.shared

        let (paymentMethod, error) = await withCheckedContinuation { continuation in
            apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                continuation.resume(returning: (paymentMethod, error))
            }
        }

        if let error = error { throw error }
        guard let paymentMethod = paymentMethod else { throw PaymentError.paymentFailed }

        let result = try await functions.httpsCallable("savePaymentMethod").call([
            "paymentMethodId": paymentMethod.stripeId,
            "setAsDefault": setAsDefault
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    func deletePaymentMethod(paymentMethodId: String) async throws {
        guard Auth.auth().currentUser != nil else { throw PaymentError.notAuthenticated }

        let result = try await functions.httpsCallable("deletePaymentMethod").call([
            "paymentMethodId": paymentMethodId
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    func setDefaultPaymentMethod(paymentMethodId: String) async throws {
        guard Auth.auth().currentUser != nil else { throw PaymentError.notAuthenticated }

        let result = try await functions.httpsCallable("setDefaultPaymentMethod").call([
            "paymentMethodId": paymentMethodId
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    // -------------------------
    // Saved Card Flow
    // -------------------------
    func processSavedCardPayment(
        paymentMethodId: String,
        eventName: String,
        amount: Double,
        eventId: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard !isProcessing else {
            print("⚠️ Payment already in progress, ignoring duplicate call")
            return
        }

        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }

            do {
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
                await MainActor.run { self.currentPaymentIntentId = intentId }

                let stripe = STPAPIClient.shared
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentMethodId

                let (confirmResult, confirmError) = await withCheckedContinuation { continuation in
                    stripe.confirmPaymentIntent(with: paymentIntentParams) { result, error in
                        continuation.resume(returning: (result, error))
                    }
                }

                if let confirmError = confirmError {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(
                        success: false,
                        message: "Payment failed: \(confirmError.localizedDescription)",
                        ticketId: nil
                    ))
                    return
                }

                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
                    let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
                    await MainActor.run { self.isProcessing = false }
                    completion(ticketResult)
                } else {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(
                        success: false,
                        message: "Payment was not completed",
                        ticketId: nil
                    ))
                }

            } catch let error as NSError {
                let errorMessage: String
                if error.domain == "FIRFunctionsErrorDomain" {
                    errorMessage = (error.userInfo["details"] as? String) ?? error.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
            }
        }
    }

    // -------------------------
    // Payment Errors
    // -------------------------
    enum PaymentError: LocalizedError {
        case notAuthenticated
        case invalidResponse
        case paymentFailed
        case cancelled

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Please sign in to purchase tickets"
            case .invalidResponse:
                return "Invalid response from server"
            case .paymentFailed:
                return "Payment failed. Please try again"
            case .cancelled:
                return "Payment was cancelled"
            }
        }
    }
}

// MARK: - Authentication Context Helper
@MainActor
class AuthenticationContext: NSObject, STPAuthenticationContext {
    nonisolated func authenticationPresentingViewController() -> UIViewController {
        var viewController: UIViewController!

        DispatchQueue.main.sync {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                viewController = MainActor.assumeIsolated {
                    UIViewController()
                }
                return
            }

            func getTopmostViewController(from vc: UIViewController) -> UIViewController {
                if let presented = vc.presentedViewController {
                    return getTopmostViewController(from: presented)
                }
                return vc
            }

            viewController = getTopmostViewController(from: rootViewController)
        }

        return viewController
    }
}
