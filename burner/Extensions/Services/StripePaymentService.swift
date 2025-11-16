import Foundation
import FirebaseAuth
import FirebaseFunctions
@_spi(STP) import StripePaymentSheet
import StripeCore
import StripeApplePay
import Combine
import UIKit
import PassKit

/// Orchestrates payment flows by coordinating specialized payment services
@MainActor
class StripePaymentService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var paymentSheet: PaymentSheet?
    @Published var currentPaymentIntentId: String?
    @Published var isPaymentSheetReady = false
    @Published var paymentMethods: [PaymentMethodInfo] {
        get { paymentMethodRepository.paymentMethods }
        set { paymentMethodRepository.paymentMethods = newValue }
    }
    @Published var isPreparing: Bool {
        get { paymentIntentCoordinator.isPreparing }
        set { paymentIntentCoordinator.isPreparing = newValue }
    }

    // MARK: - Dependencies
    private let paymentIntentCoordinator = PaymentIntentCoordinator()
    private let paymentMethodRepository = PaymentMethodRepository()
    private let paymentProcessor = PaymentProcessor()
    private let applePayService = ApplePayService.shared

    override init() {
        super.init()
        StripeAPI.defaultPublishableKey = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
    }

    // MARK: - Payment Intent Preparation

    func preparePayment(eventId: String) {
        paymentIntentCoordinator.preparePayment(eventId: eventId)
    }

    func clearPreparedIntent() {
        paymentIntentCoordinator.clearPreparedIntent()
    }

    // MARK: - Payment Sheet Flow

    func processPayment(
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
                let (clientSecret, intentId) = try await paymentIntentCoordinator.getPaymentIntent(
                    eventId: eventId,
                    usePreparedIfAvailable: false
                )
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

    func onPaymentCompletion(
        result: PaymentSheetResult,
        paymentIntentId: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        Task {
            do {
                switch result {
                case .completed:
                    let ticketResult = try await paymentProcessor.confirmPurchase(paymentIntentId: paymentIntentId)
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

    // MARK: - Apple Pay Flow

    func processApplePayPayment(
        eventName: String,
        amount: Double,
        eventId: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        guard !isProcessing else { return }

        Task {
            do {
                let (clientSecret, intentId) = try await paymentIntentCoordinator.getPaymentIntent(
                    eventId: eventId,
                    usePreparedIfAvailable: true
                )

                await MainActor.run {
                    self.currentPaymentIntentId = intentId
                }

                await MainActor.run {
                    self.applePayService.startPayment(
                        eventName: eventName,
                        amount: amount,
                        onSuccess: { payment in
                            Task {
                                await MainActor.run {
                                    self.isProcessing = true
                                    self.errorMessage = nil
                                }

                                self.applePayService.processApplePayPayment(
                                    payment: payment,
                                    clientSecret: clientSecret
                                ) { paymentIntent, error in
                                    Task {
                                        await self.paymentProcessor.handleConfirmationResult(
                                            paymentIntent: paymentIntent,
                                            error: error,
                                            intentId: intentId,
                                            logPrefix: "Apple Pay",
                                            completion: { result in
                                                Task { @MainActor in
                                                    self.isProcessing = false
                                                    completion(result)
                                                }
                                            }
                                        )
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

    // MARK: - Manual Card Entry Flow

    func processCardPayment(
        cardParams: STPPaymentMethodCardParams,
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
                let (clientSecret, intentId) = try await paymentIntentCoordinator.getPaymentIntent(
                    eventId: eventId,
                    usePreparedIfAvailable: false
                )
                await MainActor.run { self.currentPaymentIntentId = intentId }

                await paymentProcessor.processCardPayment(
                    cardParams: cardParams,
                    clientSecret: clientSecret
                ) { paymentIntent, error in
                    Task {
                        await self.paymentProcessor.handleConfirmationResult(
                            paymentIntent: paymentIntent,
                            error: error,
                            intentId: intentId,
                            logPrefix: "Card Payment",
                            completion: { result in
                                Task { @MainActor in
                                    self.isProcessing = false
                                    completion(result)
                                }
                            }
                        )
                    }
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

    // MARK: - Saved Card Flow

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
                let (clientSecret, intentId) = try await paymentIntentCoordinator.getPaymentIntent(
                    eventId: eventId,
                    usePreparedIfAvailable: false
                )
                await MainActor.run { self.currentPaymentIntentId = intentId }

                await paymentProcessor.processSavedCardPayment(
                    paymentMethodId: paymentMethodId,
                    clientSecret: clientSecret
                ) { paymentIntent, error in
                    Task {
                        await self.paymentProcessor.handleConfirmationResult(
                            paymentIntent: paymentIntent,
                            error: error,
                            intentId: intentId,
                            logPrefix: "Saved Card",
                            completion: { result in
                                Task { @MainActor in
                                    self.isProcessing = false
                                    completion(result)
                                }
                            }
                        )
                    }
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

    // MARK: - Payment Method CRUD

    func fetchPaymentMethods() async throws {
        try await paymentMethodRepository.fetchPaymentMethods()
    }

    func savePaymentMethod(cardParams: STPPaymentMethodCardParams, setAsDefault: Bool = false) async throws {
        try await paymentMethodRepository.savePaymentMethod(cardParams: cardParams, setAsDefault: setAsDefault)
    }

    func deletePaymentMethod(paymentMethodId: String) async throws {
        try await paymentMethodRepository.deletePaymentMethod(paymentMethodId: paymentMethodId)
    }

    func setDefaultPaymentMethod(paymentMethodId: String) async throws {
        try await paymentMethodRepository.setDefaultPaymentMethod(paymentMethodId: paymentMethodId)
    }
}
