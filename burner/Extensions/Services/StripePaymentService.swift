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
class StripePaymentService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var paymentSheet: PaymentSheet?
    @Published var currentPaymentIntentId: String?
    @Published var isPaymentSheetReady = false

    
    private let functions = Functions.functions(region: "us-central1")

    struct PaymentResult {
        let success: Bool
        let message: String
        let ticketId: String?
    }

    init() {
        // Configure Stripe with your publishable key
        // TODO: Replace with your actual Stripe publishable key
        StripeAPI.defaultPublishableKey = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
        
        // Log if key is not set
        if StripeAPI.defaultPublishableKey == "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe" {
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
                    } else if let userInfo = error.userInfo as? [String: Any] {
                        print("❌ Firebase error userInfo: \(userInfo)")
                        errorMessage = error.localizedDescription
                    } else {
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
                                do {
                                    // Create payment method params from Apple Pay
                                    let paymentMethodParams = STPPaymentMethodParams(applePay: payment)

                                    print("🔵 Confirming PaymentIntent with Apple Pay payment method")

                                    // Confirm the payment intent
                                    let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
                                    paymentIntentParams.paymentMethodParams = paymentMethodParams

                                    let paymentHandler = STPPaymentHandler.shared()

                                    paymentHandler.confirmPayment(paymentIntentParams, with: self) { status, paymentIntent, error in
                                        Task {
                                            if let error = error {
                                                print("❌ Payment confirmation failed: \(error)")
                                                await MainActor.run {
                                                    self.isProcessing = false
                                                    completion(PaymentResult(
                                                        success: false,
                                                        message: "Payment failed: \(error.localizedDescription)",
                                                        ticketId: nil
                                                    ))
                                                }
                                                return
                                            }

                                            if status == .succeeded {
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
                                                print("❌ Payment not succeeded, status: \(status.rawValue)")
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

                                } catch {
                                    print("❌ Error setting up payment confirmation: \(error)")
                                    await MainActor.run {
                                        self.isProcessing = false
                                        completion(PaymentResult(
                                            success: false,
                                            message: "Payment setup failed: \(error.localizedDescription)",
                                            ticketId: nil
                                        ))
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

// MARK: - STPAuthenticationContext
extension StripePaymentService: STPAuthenticationContext {
    nonisolated func authenticationPresentingViewController() -> UIViewController {
        // Get the topmost view controller for presenting authentication UI
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return UIViewController()
        }

        func getTopmostViewController(from viewController: UIViewController) -> UIViewController {
            if let presented = viewController.presentedViewController {
                return getTopmostViewController(from: presented)
            }
            return viewController
        }

        return getTopmostViewController(from: rootViewController)
    }
}
