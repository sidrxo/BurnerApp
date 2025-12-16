import Foundation
import Supabase
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

    private let supabase = SupabaseManager.shared.client
    private let appState: AppState

    struct PaymentMethodInfo: Identifiable, Decodable {
        let id: String
        let brand: String
        let last4: String
        let expMonth: Int
        let expYear: Int
        let isDefault: Bool
        
        enum CodingKeys: String, CodingKey {
            case id, brand, last4
            case expMonth = "exp_month"
            case expYear = "exp_year"
            case isDefault = "is_default"
        }
    }
    
    // MARK: - Request Structs
    
    struct SavePaymentMethodRequest: Encodable {
        let paymentMethodId: String
        let setAsDefault: Bool
        
        enum CodingKeys: String, CodingKey {
            case paymentMethodId = "payment_method_id"
            case setAsDefault = "set_as_default"
        }
    }
    
    struct ConfirmPurchaseRequest: Encodable {
        let paymentIntentId: String
        
        enum CodingKeys: String, CodingKey {
            case paymentIntentId = "payment_intent_id"
        }
    }
    
    struct CreateIntentRequest: Encodable {
        let eventId: String
    }
    
    // UPDATED: Added ticketNumber field
    struct PaymentResult {
        let success: Bool
        let message: String
        let ticketId: String?
        let ticketNumber: String?
        
        init(success: Bool, message: String, ticketId: String? = nil, ticketNumber: String? = nil) {
            self.success = success
            self.message = message
            self.ticketId = ticketId
            self.ticketNumber = ticketNumber
        }
    }
    
    // MARK: - Response Structs
    
    struct CreateIntentResponse: Decodable {
        let clientSecret: String
        let paymentIntentId: String
        let amount: Double
    }
    
    // UPDATED: Added ticketNumber field
    struct ConfirmPurchaseResponse: Decodable {
        let success: Bool
        let ticketId: String?
        let ticketNumber: String?
        let message: String?
        
        enum CodingKeys: String, CodingKey {
            case success, message
            case ticketId = "ticketId"
            case ticketNumber = "ticketNumber"
        }
    }
    
    struct PaymentMethodsResponse: Decodable {
        let paymentMethods: [PaymentMethodInfo]
        
        enum CodingKeys: String, CodingKey {
            case paymentMethods = "payment_methods"
        }
    }
    
    struct GenericResponse: Decodable {
        let success: Bool?
        let message: String?
    }

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
                let (clientSecret, intentId, _) = try await createPaymentIntent(eventId: eventId)
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
    
    private func withPaymentIntent(
        eventId: String,
        usePreparedIfAvailable: Bool = false
    ) async throws -> (clientSecret: String, paymentIntentId: String, amount: Double) {
        if usePreparedIfAvailable,
           let preparedId = preparedIntentId,
           let secret = preparedClientSecret,
           preparedEventId == eventId {
            
            await MainActor.run {
                self.preparedClientSecret = nil
                self.preparedIntentId = nil
                self.preparedEventId = nil
            }
            return try await createPaymentIntent(eventId: eventId)

        } else {
            return try await createPaymentIntent(eventId: eventId)
        }
    }
    
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

            completion(PaymentResult(
                success: false,
                message: paymentError.errorDescription ?? error.localizedDescription,
                ticketId: nil,
                ticketNumber: nil
            ))
            return
        }
       
        guard let paymentIntent = paymentIntent, paymentIntent.status == .succeeded else {
            await MainActor.run { self.isProcessing = false }
            completion(PaymentResult(
                success: false,
                message: "Payment was not completed",
                ticketId: nil,
                ticketNumber: nil
            ))
            return
        }
       
        do {
            let ticketResult = try await self.confirmPurchase(paymentIntentId: intentId)
            await MainActor.run {
                self.isProcessing = false
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
            completion(ticketResult)
        } catch {
            await MainActor.run { self.isProcessing = false }

            completion(PaymentResult(
                success: false,
                message: PaymentError.processingError.errorDescription ?? "Payment processing error",
                ticketId: nil,
                ticketNumber: nil
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
                let (clientSecret, intentId, _) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: false)
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
                let msg = error.localizedDescription

                await MainActor.run {
                    self.isProcessing = false
                    self.isPaymentSheetReady = false
                    self.errorMessage = msg
                }
                completion(PaymentResult(
                    success: false,
                    message: "Setup failed: \(msg)",
                    ticketId: nil,
                    ticketNumber: nil
                ))
            }
        }
    }
    
    func onPaymentCompletion(result: PaymentSheetResult, paymentIntentId: String, completion: @escaping (PaymentResult) -> Void) {
        Task {
            do {
                switch result {
                case .completed:
                    let ticketResult = try await confirmPurchase(paymentIntentId: paymentIntentId)
                    completion(ticketResult)
                case .canceled:
                    completion(PaymentResult(
                        success: false,
                        message: "Payment was cancelled",
                        ticketId: nil,
                        ticketNumber: nil
                    ))
                case .failed(let error):
                    completion(PaymentResult(
                        success: false,
                        message: error.localizedDescription,
                        ticketId: nil,
                        ticketNumber: nil
                    ))
                }
            } catch {
                completion(PaymentResult(
                    success: false,
                    message: error.localizedDescription,
                    ticketId: nil,
                    ticketNumber: nil
                ))
            }
            await MainActor.run {
                self.isPaymentSheetReady = false
            }
        }
    }

    // MARK: - Updated Network Calls
    
    private func createPaymentIntent(eventId: String) async throws -> (clientSecret: String, paymentIntentId: String, amount: Double) {
        guard appState.authService.currentUser != nil else { throw PaymentError.notAuthenticated }
        
        let requestBody = CreateIntentRequest(eventId: eventId)
        
        let response: CreateIntentResponse = try await supabase.functions
            .invoke("create-payment-intent", options: FunctionInvokeOptions(body: requestBody))
        
        return (response.clientSecret, response.paymentIntentId, response.amount)
    }

    // UPDATED: Returns PaymentResult with ticketNumber
    private func confirmPurchase(paymentIntentId: String, retryCount: Int = 0) async throws -> PaymentResult {
        guard appState.authService.currentUser != nil else { throw PaymentError.notAuthenticated }

        let maxRetries = 3
        let baseDelay: UInt64 = 1_000_000_000

        do {
            let requestBody = ConfirmPurchaseRequest(paymentIntentId: paymentIntentId)

            let response: ConfirmPurchaseResponse = try await supabase.functions
                .invoke("confirm-purchase", options: FunctionInvokeOptions(body: requestBody))

            return PaymentResult(
                success: response.success,
                message: response.message ?? "Purchase completed",
                ticketId: response.ticketId,
                ticketNumber: response.ticketNumber
            )

        } catch {
            let nsError = error as NSError
            let isNetworkError = nsError.domain == NSURLErrorDomain ||
                                nsError.code == NSURLErrorNotConnectedToInternet ||
                                nsError.code == NSURLErrorTimedOut ||
                                nsError.code == NSURLErrorNetworkConnectionLost

            if isNetworkError && retryCount < maxRetries {
                let delay = baseDelay * UInt64(pow(2.0, Double(retryCount)))

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
                let (clientSecret, intentId, _) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: true)

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
                                            completion(PaymentResult(
                                                success: false,
                                                message: error.localizedDescription,
                                                ticketId: nil,
                                                ticketNumber: nil
                                            ))
                                            return
                                        }

                                        guard let paymentMethod = paymentMethod else {
                                            await MainActor.run { self.isProcessing = false }
                                            completion(PaymentResult(
                                                success: false,
                                                message: "Failed to create payment method",
                                                ticketId: nil,
                                                ticketNumber: nil
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
                                    ticketId: nil,
                                    ticketNumber: nil
                                ))
                            }
                        },
                        onCancelled: {
                            Task {
                                await MainActor.run { self.isProcessing = false }
                                completion(PaymentResult(
                                    success: false,
                                    message: "",
                                    ticketId: nil,
                                    ticketNumber: nil
                                ))
                            }
                        }
                    )
                }

            } catch {
                let errorMessage = error.localizedDescription
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(
                    success: false,
                    message: errorMessage,
                    ticketId: nil,
                    ticketNumber: nil
                ))
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
                let (clientSecret, intentId, _) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: false)
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
                    completion(PaymentResult(
                        success: false,
                        message: pmError.localizedDescription,
                        ticketId: nil,
                        ticketNumber: nil
                    ))
                    return
                }

                guard let paymentMethod = paymentMethod else {
                    await MainActor.run { self.isProcessing = false }
                    completion(PaymentResult(
                        success: false,
                        message: "Failed to create payment method",
                        ticketId: nil,
                        ticketNumber: nil
                    ))
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
                let errorMessage = error.localizedDescription
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(
                    success: false,
                    message: errorMessage,
                    ticketId: nil,
                    ticketNumber: nil
                ))
            }
        }
    }

    func fetchPaymentMethods() async throws {
        guard appState.authService.currentUser != nil else { return }
        
        let response: PaymentMethodsResponse = try await supabase.functions
            .invoke("get-payment-methods")
            
        await MainActor.run {
            self.paymentMethods = response.paymentMethods
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

            let requestBody = SavePaymentMethodRequest(
                paymentMethodId: paymentMethod.stripeId,
                setAsDefault: setAsDefault
            )

            let _: GenericResponse = try await supabase.functions.invoke(
                "save-payment-method",
                options: FunctionInvokeOptions(body: requestBody)
            )

            try await fetchPaymentMethods()
        }

    func deletePaymentMethod(paymentMethodId: String) async throws {
        let safeBody = ["payment_method_id": paymentMethodId]

        let _: GenericResponse = try await supabase.functions.invoke("delete-payment-method", options: FunctionInvokeOptions(body: safeBody))
        try await fetchPaymentMethods()
    }

    func setDefaultPaymentMethod(paymentMethodId: String) async throws {
        let safeBody = ["payment_method_id": paymentMethodId]
        let _: GenericResponse = try await supabase.functions.invoke("set-default-payment-method", options: FunctionInvokeOptions(body: safeBody))
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
                let (clientSecret, intentId, _) = try await withPaymentIntent(eventId: eventId, usePreparedIfAvailable: false)
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
                let errorMessage = error.localizedDescription
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = errorMessage
                }
                completion(PaymentResult(
                    success: false,
                    message: errorMessage,
                    ticketId: nil,
                    ticketNumber: nil
                ))
            }
        }
    }

    enum PaymentError: LocalizedError {
        case notAuthenticated
        case invalidResponse
        case paymentFailed
        case processingError
        case ticketCreationFailed

      nonisolated var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "Please sign in to purchase tickets"
            case .invalidResponse: return "Invalid response from server."
            case .paymentFailed: return "Payment failed. Please try again"
            case .processingError: return "Payment succeeded but ticket creation failed."
            case .ticketCreationFailed: return "Failed to create ticket."
            }
        }

        static func from(stripeError: Error) -> PaymentError {
            return .paymentFailed
        }
    }
}
