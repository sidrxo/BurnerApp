// StripePaymentService.swift

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
    
    // ✅ Payment Intent Pre-creation Properties
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
    }
    
    // -------------------------
    // Payment Intent Pre-creation
    // -------------------------
    /// Pre-creates a payment intent in the background to improve Apple Pay UX.
    /// Call this when the purchase view appears.
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
                // Cleanup after ~10 minutes
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

    // -------------------------
    // Process Payment with Payment Sheet
    // -------------------------
    func processPayment(eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        guard !isProcessing else { return }
        
        Task {
            await MainActor.run {
                self.isProcessing = true
                self.errorMessage = nil
            }
            
            do {
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
                await MainActor.run { self.currentPaymentIntentId = intentId }
                
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
                let msg: String = (error.domain == "FIRFunctionsErrorDomain")
                ? ((error.userInfo["details"] as? String) ?? error.localizedDescription)
                : error.localizedDescription

                #if DEBUG
                print("❌ Payment Sheet Setup Error: \(msg)")
                #endif

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
        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }
        let result = try await functions.httpsCallable("createPaymentIntent").call(["eventId": eventId])
        guard let data = result.data as? [String: Any],
              let clientSecret = data["clientSecret"] as? String,
              let paymentIntentId = data["paymentIntentId"] as? String else {
            throw PaymentError.invalidResponse
        }
        return (clientSecret, paymentIntentId)
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
    // Process Apple Pay Payment (Custom Flow) — uses pre-creation if available
    // -------------------------
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
                let (clientSecret, intentId): (String, String)
                if let prepared = preparedIntentId,
                   let secret = preparedClientSecret,
                   preparedEventId == eventId {
                    clientSecret = secret
                    intentId = prepared
                    await MainActor.run {
                        self.preparedClientSecret = nil
                        self.preparedIntentId = nil
                        self.preparedEventId = nil
                    }
                } else {
                    let result = try await createPaymentIntent(eventId: eventId)
                    clientSecret = result.0
                    intentId = result.1
                }

                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }

                await MainActor.run {
                    ApplePayHandler.shared.startPayment(
                        eventName: eventName,
                        amount: amount,
                        onSuccess: { payment in
                            Task {
                                // Show processing indicator only after user authorizes
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
                                            #if DEBUG
                                            print("❌ Apple Pay Payment Method Error: \(error.localizedDescription)")
                                            #endif
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
                                                if let confirmError = confirmError {
                                                    await MainActor.run { self.isProcessing = false }
                                                    let paymentError = PaymentError.from(stripeError: confirmError)
                                                    #if DEBUG
                                                    print("❌ Apple Pay Confirmation Error: \(confirmError.localizedDescription)")
                                                    #endif
                                                    completion(PaymentResult(
                                                        success: false,
                                                        message: paymentError.errorDescription ?? confirmError.localizedDescription,
                                                        ticketId: nil
                                                    ))
                                                    return
                                                }

                                                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
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
                                                        #if DEBUG
                                                        print("❌ Apple Pay Ticket Creation Error: \(error.localizedDescription)")
                                                        #endif
                                                        completion(PaymentResult(
                                                            success: false,
                                                            message: PaymentError.processingError.errorDescription ?? "Payment processing error",
                                                            ticketId: nil
                                                        ))
                                                    }
                                                } else {
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
                            // User dismissed the Apple Pay sheet - do nothing
                            // Don't call completion, just silently return
                        }
                    )
                }

            } catch let error as NSError {
                let errorMessage: String = (error.domain == "FIRFunctionsErrorDomain")
                ? ((error.userInfo["details"] as? String) ?? error.localizedDescription)
                : error.localizedDescription

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
        guard !isProcessing else { return }

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
                    let paymentError = PaymentError.from(stripeError: pmError)
                    #if DEBUG
                    print("❌ Payment Method Error: \(pmError.localizedDescription)")
                    #endif
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

                if let confirmError = confirmError {
                    await MainActor.run { self.isProcessing = false }
                    let paymentError = PaymentError.from(stripeError: confirmError)
                    #if DEBUG
                    print("❌ Payment Confirmation Error: \(confirmError.localizedDescription)")
                    #endif
                    completion(PaymentResult(success: false, message: paymentError.errorDescription ?? confirmError.localizedDescription, ticketId: nil))
                    return
                }

                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
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
                        #if DEBUG
                        print("❌ Ticket Creation Error: \(error.localizedDescription)")
                        #endif
                        completion(PaymentResult(success: false, message: PaymentError.processingError.errorDescription ?? "Payment processing error", ticketId: nil))
                    }
                } else {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(success: false, message: "Payment was not completed", ticketId: nil))
                }

            } catch let error as NSError {
                let errorMessage: String = (error.domain == "FIRFunctionsErrorDomain")
                ? ((error.userInfo["details"] as? String) ?? error.localizedDescription)
                : error.localizedDescription

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
        guard !isProcessing else { return }

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
                    let paymentError = PaymentError.from(stripeError: confirmError)
                    #if DEBUG
                    print("❌ Saved Card Payment Error: \(confirmError.localizedDescription)")
                    #endif
                    completion(PaymentResult(
                        success: false,
                        message: paymentError.errorDescription ?? confirmError.localizedDescription,
                        ticketId: nil
                    ))
                    return
                }

                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
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
                        #if DEBUG
                        print("❌ Saved Card Ticket Creation Error: \(error.localizedDescription)")
                        #endif
                        completion(PaymentResult(success: false, message: PaymentError.processingError.errorDescription ?? "Payment processing error", ticketId: nil))
                    }
                } else {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(
                        success: false,
                        message: "Payment was not completed",
                        ticketId: nil
                    ))
                }

            } catch let error as NSError {
                let errorMessage: String = (error.domain == "FIRFunctionsErrorDomain")
                ? ((error.userInfo["details"] as? String) ?? error.localizedDescription)
                : error.localizedDescription

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
        case cardDeclined
        case insufficientFunds
        case expiredCard
        case networkError
        case invalidCard
        case processingError
        case ticketCreationFailed
        case eventSoldOut

        var errorDescription: String? {
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
                return AppConstants.ErrorMessages.networkError
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
