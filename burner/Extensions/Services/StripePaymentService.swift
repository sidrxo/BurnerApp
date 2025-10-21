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

    private let functions = Functions.functions(region: "us-central1")

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
        // Configure Stripe with your publishable key
        // TODO: Replace with your actual Stripe publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"

        // Log if key is not set
        if StripeAPI.defaultPublishableKey == "PK_TEST" {
            print("⚠️ WARNING: Stripe publishable key not set! Get it from https://dashboard.stripe.com/test/apikeys")
        }
    }

    // -------------------------
    // Process Payment with Payment Sheet
    // -------------------------
    func processPayment(eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
        // Prevent multiple simultaneous calls
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
                
                // Step 1: Create payment intent on backend
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)
                
                print("✅ Payment intent created: \(intentId)")
                
                // Store payment intent ID for later use
                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }
                
                // Step 2: Configure Payment Sheet
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Burner"
                
                // Configure Apple Pay
                configuration.applePay = .init(
                    merchantId: "merchant.BurnerTickets",
                    merchantCountryCode: "GB"
                )
                
                configuration.defaultBillingDetails.address = .init(country: "GB")
                configuration.allowsDelayedPaymentMethods = false
                
                // Configure appearance for better UX
                var appearance = PaymentSheet.Appearance()
                appearance.primaryButton.backgroundColor = .black
                configuration.appearance = appearance
                
                print("✅ Payment Sheet configured with Apple Pay")
                
                // Step 3: Create Payment Sheet
                await MainActor.run {
                    self.paymentSheet = PaymentSheet(
                        paymentIntentClientSecret: clientSecret,
                        configuration: configuration
                    )
                    self.isProcessing = false
                    self.isPaymentSheetReady = true
                    print("✅ Payment Sheet ready to present")
                }
                
            } catch let error as NSError {
                print("❌ Error creating payment: \(error)")
                print("❌ Error domain: \(error.domain)")
                print("❌ Error code: \(error.code)")
                print("❌ Error description: \(error.localizedDescription)")
                
                // Extract Firebase Functions error details
                if error.domain == "FIRFunctionsErrorDomain" {
                    let errorMessage: String
                    if let details = error.userInfo["details"] as? String {
                        errorMessage = details
                        print("❌ Firebase error details: \(details)")
                    } else {
                        print("❌ Firebase error userInfo: \(error.userInfo)")
                        errorMessage = error.localizedDescription
                    }
                    
                    await MainActor.run {
                        self.isProcessing = false
                        self.isPaymentSheetReady = false
                        self.errorMessage = errorMessage
                        completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
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
                    print("✅ Payment completed successfully")
                    print("🔵 Creating ticket for payment: \(paymentIntentId)")
                    
                    // Call backend to create ticket
                    let ticketResult = try await confirmPurchase(paymentIntentId: paymentIntentId)
                    print("✅ Ticket result: \(ticketResult.success)")
                    completion(ticketResult)
                    
                case .canceled:
                    print("⚠️ Payment canceled by user")
                    completion(PaymentResult(success: false, message: "Payment was cancelled", ticketId: nil))
                    
                case .failed(let error):
                    print("❌ Payment failed: \(error.localizedDescription)")
                    completion(PaymentResult(success: false, message: error.localizedDescription, ticketId: nil))
                }
            } catch {
                print("❌ Error in payment completion: \(error.localizedDescription)")
                completion(PaymentResult(success: false, message: error.localizedDescription, ticketId: nil))
            }
            
            // Reset the flag
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
            print("❌ User not authenticated")
            throw PaymentError.notAuthenticated
        }
        
        print("🔵 Calling createPaymentIntent function for event: \(eventId)")
        
        do {
            let result = try await functions.httpsCallable("createPaymentIntent").call(["eventId": eventId])
            
            guard let data = result.data as? [String: Any] else {
                print("❌ Invalid response format from createPaymentIntent")
                throw PaymentError.invalidResponse
            }
            
            print("✅ Response data: \(data)")
            
            guard let clientSecret = data["clientSecret"] as? String,
                  let paymentIntentId = data["paymentIntentId"] as? String else {
                print("❌ Missing clientSecret or paymentIntentId in response")
                print("❌ Response keys: \(data.keys)")
                throw PaymentError.invalidResponse
            }
            
            print("✅ Got client secret and payment intent ID")
            return (clientSecret, paymentIntentId)
            
        } catch let error as NSError {
            print("❌ Firebase function error: \(error)")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            print("❌ Error localizedDescription: \(error.localizedDescription)")
            
            // Try to extract more details from Firebase error
            if let errorData = error.userInfo["details"] as? [String: Any] {
                print("❌ Error details: \(errorData)")
            }
            
            throw error
        }
    }

    // -------------------------
    // Confirm Purchase (Create Ticket)
    // -------------------------
    private func confirmPurchase(paymentIntentId: String) async throws -> PaymentResult {
        print("🔵 Calling confirmPurchase for payment: \(paymentIntentId)")
        
        do {
            let result = try await functions.httpsCallable("confirmPurchase").call(["paymentIntentId": paymentIntentId])
            
            guard let data = result.data as? [String: Any] else {
                print("❌ Invalid response format from confirmPurchase")
                throw PaymentError.invalidResponse
            }
            
            print("✅ confirmPurchase response: \(data)")
            
            guard let success = data["success"] as? Bool else {
                print("❌ Missing 'success' field in response")
                throw PaymentError.invalidResponse
            }

            let message = data["message"] as? String ?? "Purchase completed"
            let ticketId = data["ticketId"] as? String
            
            print("✅ Purchase result - Success: \(success), Ticket ID: \(ticketId ?? "none")")
            
            return PaymentResult(success: success, message: message, ticketId: ticketId)
            
        } catch let error as NSError {
            print("❌ confirmPurchase error: \(error)")
            print("❌ Error domain: \(error.domain)")
            print("❌ Error code: \(error.code)")
            
            if let errorData = error.userInfo["details"] as? [String: Any] {
                print("❌ Error details: \(errorData)")
            }
            
            throw error
        }
    }

    // -------------------------
    // Process Apple Pay Payment (Custom Flow)
    // -------------------------
    func processApplePayPayment(eventName: String, amount: Double, eventId: String, completion: @escaping (PaymentResult) -> Void) {
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
                print("🔵 Creating payment intent for Apple Pay: \(eventId)")

                // Step 1: Create payment intent on backend
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)

                print("✅ Payment intent created for Apple Pay: \(intentId)")

                // Store payment intent ID
                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }

                // Step 2: Present Apple Pay
                await MainActor.run {
                    ApplePayHandler.shared.startPayment(
                        eventName: eventName,
                        amount: amount,
                        onSuccess: { payment in
                            print("✅ Apple Pay authorized successfully")

                            // Step 3: Confirm the PaymentIntent with Stripe using the Apple Pay payment method
                            Task {
                                print("🔵 Confirming PaymentIntent with Apple Pay payment method")

                                // Create API client to confirm payment intent with Apple Pay token
                                let apiClient = STPAPIClient.shared

                                apiClient.createPaymentMethod(with: payment) { paymentMethod, error in
                                    Task {
                                        if let error = error {
                                            print("❌ Failed to create payment method: \(error)")
                                            await MainActor.run {
                                                self.isProcessing = false
                                                completion(PaymentResult(
                                                    success: false,
                                                    message: "Failed to process Apple Pay: \(error.localizedDescription)",
                                                    ticketId: nil
                                                ))
                                            }
                                            return
                                        }

                                        guard let paymentMethod = paymentMethod else {
                                            print("❌ No payment method created")
                                            await MainActor.run {
                                                self.isProcessing = false
                                                completion(PaymentResult(
                                                    success: false,
                                                    message: "Failed to create payment method",
                                                    ticketId: nil
                                                ))
                                            }
                                            return
                                        }

                                        print("✅ Payment method created: \(paymentMethod.stripeId)")

                                        // Now confirm the payment intent with the payment method
                                        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                                        paymentIntentParams.paymentMethodId = paymentMethod.stripeId

                                        apiClient.confirmPaymentIntent(with: paymentIntentParams) { confirmResult, confirmError in
                                            Task {
                                                if let confirmError = confirmError {
                                                    print("❌ Payment confirmation failed: \(confirmError)")
                                                    await MainActor.run {
                                                        self.isProcessing = false
                                                        completion(PaymentResult(
                                                            success: false,
                                                            message: "Payment failed: \(confirmError.localizedDescription)",
                                                            ticketId: nil
                                                        ))
                                                    }
                                                    return
                                                }

                                                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
                                                    print("✅ Payment confirmed successfully")

                                                    // Step 4: Create ticket on backend
                                                    do {
                                                        let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
                                                        await MainActor.run {
                                                            self.isProcessing = false
                                                            completion(ticketResult)
                                                        }
                                                    } catch {
                                                        print("❌ Error creating ticket: \(error)")
                                                        await MainActor.run {
                                                            self.isProcessing = false
                                                            completion(PaymentResult(
                                                                success: false,
                                                                message: "Payment succeeded but ticket creation failed: \(error.localizedDescription)",
                                                                ticketId: nil
                                                            ))
                                                        }
                                                    }
                                                } else {
                                                    print("❌ Payment not succeeded, status: \(String(confirmResult?.status.rawValue ?? -1))")
                                                    await MainActor.run {
                                                        self.isProcessing = false
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
                            }
                        },
                        onFailure: { error in
                            print("❌ Apple Pay failed: \(error)")
                            Task {
                                await MainActor.run {
                                    self.isProcessing = false
                                    completion(PaymentResult(
                                        success: false,
                                        message: "Apple Pay failed: \(error.localizedDescription)",
                                        ticketId: nil
                                    ))
                                }
                            }
                        }
                    )
                }

            } catch let error as NSError {
                print("❌ Error setting up Apple Pay: \(error)")

                let errorMessage: String
                if error.domain == "FIRFunctionsErrorDomain" {
                    if let details = error.userInfo["details"] as? String {
                        errorMessage = details
                    } else {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                    completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
                }
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
                print("🔵 Creating payment intent for card payment: \(eventId)")

                // Step 1: Create payment intent on backend
                let (clientSecret, intentId) = try await createPaymentIntent(eventId: eventId)

                print("✅ Payment intent created for card payment: \(intentId)")

                // Store payment intent ID
                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }

                // Step 2: Create payment method from card params
                let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)

                let apiClient = STPAPIClient.shared

                print("🔵 Creating payment method from card")

                // Create payment method
                let (paymentMethod, pmError) = await withCheckedContinuation { continuation in
                    apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                        continuation.resume(returning: (paymentMethod, error))
                    }
                }

                if let pmError = pmError {
                    print("❌ Failed to create payment method: \(pmError)")
                    await MainActor.run {
                        self.isProcessing = false
                        completion(PaymentResult(
                            success: false,
                            message: "Failed to process card: \(pmError.localizedDescription)",
                            ticketId: nil
                        ))
                    }
                    return
                }

                guard let paymentMethod = paymentMethod else {
                    print("❌ No payment method created")
                    await MainActor.run {
                        self.isProcessing = false
                        completion(PaymentResult(
                            success: false,
                            message: "Failed to create payment method",
                            ticketId: nil
                        ))
                    }
                    return
                }

                print("✅ Payment method created: \(paymentMethod.stripeId)")

                // Step 3: Confirm payment intent with the payment method
                let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                paymentIntentParams.paymentMethodId = paymentMethod.stripeId

                print("🔵 Confirming payment intent")

                let (confirmResult, confirmError) = await withCheckedContinuation { continuation in
                    apiClient.confirmPaymentIntent(with: paymentIntentParams) { result, error in
                        continuation.resume(returning: (result, error))
                    }
                }

                if let confirmError = confirmError {
                    print("❌ Payment confirmation failed: \(confirmError)")
                    await MainActor.run {
                        self.isProcessing = false
                        completion(PaymentResult(
                            success: false,
                            message: "Payment failed: \(confirmError.localizedDescription)",
                            ticketId: nil
                        ))
                    }
                    return
                }

                if let paymentIntent = confirmResult, paymentIntent.status == .succeeded {
                    print("✅ Payment confirmed successfully")

                    // Step 4: Create ticket on backend
                    do {
                        let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
                        await MainActor.run {
                            self.isProcessing = false
                            completion(ticketResult)
                        }
                    } catch {
                        print("❌ Error creating ticket: \(error)")
                        await MainActor.run {
                            self.isProcessing = false
                            completion(PaymentResult(
                                success: false,
                                message: "Payment succeeded but ticket creation failed: \(error.localizedDescription)",
                                ticketId: nil
                            ))
                        }
                    }
                } else {
                    print("❌ Payment not succeeded, status: \(String(confirmResult?.status.rawValue ?? -1))")
                    await MainActor.run {
                        self.isProcessing = false
                        completion(PaymentResult(
                            success: false,
                            message: "Payment was not completed",
                            ticketId: nil
                        ))
                    }
                }

            } catch let error as NSError {
                print("❌ Error setting up card payment: \(error)")

                let errorMessage: String
                if error.domain == "FIRFunctionsErrorDomain" {
                    if let details = error.userInfo["details"] as? String {
                        errorMessage = details
                    } else {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }

                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                    completion(PaymentResult(success: false, message: errorMessage, ticketId: nil))
                }
            }
        }
    }

    // -------------------------
    // Get Payment Methods
    // -------------------------
    func fetchPaymentMethods() async throws {
        print("🔵 Fetching payment methods")

        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }

        let result = try await functions.httpsCallable("getPaymentMethods").call()

        guard let data = result.data as? [String: Any],
              let methods = data["paymentMethods"] as? [[String: Any]] else {
            print("❌ Invalid response from getPaymentMethods")
            throw PaymentError.invalidResponse
        }

        print("✅ Fetched \(methods.count) payment methods")

        await MainActor.run {
            self.paymentMethods = methods.compactMap { methodData in
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
        }
    }

    // -------------------------
    // Save Payment Method
    // -------------------------
    func savePaymentMethod(cardParams: STPPaymentMethodCardParams, setAsDefault: Bool = false) async throws {
        print("🔵 Saving payment method")

        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }

        // Create payment method
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let apiClient = STPAPIClient.shared

        let (paymentMethod, error) = await withCheckedContinuation { continuation in
            apiClient.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
                continuation.resume(returning: (paymentMethod, error))
            }
        }

        if let error = error {
            print("❌ Failed to create payment method: \(error)")
            throw error
        }

        guard let paymentMethod = paymentMethod else {
            print("❌ No payment method created")
            throw PaymentError.paymentFailed
        }

        print("✅ Payment method created: \(paymentMethod.stripeId)")

        // Save to backend
        let result = try await functions.httpsCallable("savePaymentMethod").call([
            "paymentMethodId": paymentMethod.stripeId,
            "setAsDefault": setAsDefault
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success else {
            print("❌ Failed to save payment method")
            throw PaymentError.paymentFailed
        }

        print("✅ Payment method saved successfully")

        // Refresh payment methods
        try await fetchPaymentMethods()
    }

    // -------------------------
    // Delete Payment Method
    // -------------------------
    func deletePaymentMethod(paymentMethodId: String) async throws {
        print("🔵 Deleting payment method: \(paymentMethodId)")

        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }

        let result = try await functions.httpsCallable("deletePaymentMethod").call([
            "paymentMethodId": paymentMethodId
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success else {
            print("❌ Failed to delete payment method")
            throw PaymentError.paymentFailed
        }

        print("✅ Payment method deleted successfully")

        // Refresh payment methods
        try await fetchPaymentMethods()
    }

    // -------------------------
    // Set Default Payment Method
    // -------------------------
    func setDefaultPaymentMethod(paymentMethodId: String) async throws {
        print("🔵 Setting default payment method: \(paymentMethodId)")

        guard Auth.auth().currentUser != nil else {
            throw PaymentError.notAuthenticated
        }

        let result = try await functions.httpsCallable("setDefaultPaymentMethod").call([
            "paymentMethodId": paymentMethodId
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success else {
            print("❌ Failed to set default payment method")
            throw PaymentError.paymentFailed
        }

        print("✅ Default payment method set successfully")

        // Refresh payment methods
        try await fetchPaymentMethods()
    }

    // -------------------------
    // Get Authentication Context for Stripe
    // -------------------------
    func getAuthenticationContext() -> STPAuthenticationContext {
        return AuthenticationContext()
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
        // Get the topmost view controller for presenting authentication UI
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
