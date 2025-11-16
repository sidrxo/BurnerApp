import Foundation
import PassKit
import UIKit
@_spi(STP) import StripePaymentSheet
import StripeCore

/// Handles Apple Pay payment flows
@MainActor
class ApplePayService: NSObject, ObservableObject {
    static let shared = ApplePayService()

    private var paymentController: PKPaymentAuthorizationController?
    private var paymentSummaryItems = [PKPaymentSummaryItem]()
    private var onPaymentSuccess: ((PKPayment) -> Void)?
    private var onPaymentFailure: ((Error) -> Void)?
    private var onCancelled: (() -> Void)?
    private var paymentWasAuthorized = false

    private let merchantID = "merchant.BurnerTickets"
    private let currencyCode = "GBP"
    private let countryCode = "GB"

    override private init() {
        super.init()
    }

    // MARK: - Apple Pay Availability

    static func canMakePayments() -> Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    static func canMakePaymentsWithActiveCard() -> Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex, .discover])
    }

    // MARK: - Start Payment

    func startPayment(
        eventName: String,
        amount: Double,
        onSuccess: @escaping (PKPayment) -> Void,
        onFailure: @escaping (Error) -> Void,
        onCancelled: @escaping () -> Void = {}
    ) {
        self.onPaymentSuccess = onSuccess
        self.onPaymentFailure = onFailure
        self.onCancelled = onCancelled
        self.paymentWasAuthorized = false

        // Create payment summary items
        let ticketItem = PKPaymentSummaryItem(
            label: "Ticket: \(eventName)",
            amount: NSDecimalNumber(value: amount),
            type: .final
        )

        let total = PKPaymentSummaryItem(
            label: "Burner",
            amount: NSDecimalNumber(value: amount),
            type: .final
        )

        paymentSummaryItems = [ticketItem, total]

        // Create payment request
        let paymentRequest = PKPaymentRequest()
        paymentRequest.merchantIdentifier = merchantID
        paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        paymentRequest.merchantCapabilities = .threeDSecure
        paymentRequest.countryCode = countryCode
        paymentRequest.currencyCode = currencyCode
        paymentRequest.paymentSummaryItems = paymentSummaryItems

        // Present payment controller
        paymentController = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
        paymentController?.delegate = self
        paymentController?.present(completion: { presented in
            if !presented {
                let error = NSError(
                    domain: "ApplePayError",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to present Apple Pay"]
                )
                onFailure(error)
            }
        })
    }

    // MARK: - Process Apple Pay Payment

    /// Processes an Apple Pay payment by creating a payment method and confirming the intent
    func processApplePayPayment(
        payment: PKPayment,
        clientSecret: String,
        completion: @escaping (STPPaymentIntent?, Error?) -> Void
    ) {
        let apiClient = STPAPIClient.shared
        apiClient.createPaymentMethod(with: payment) { paymentMethod, error in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let paymentMethod = paymentMethod else {
                let error = NSError(
                    domain: "ApplePayError",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create payment method"]
                )
                completion(nil, error)
                return
            }

            let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
            paymentIntentParams.paymentMethodId = paymentMethod.stripeId

            apiClient.confirmPaymentIntent(with: paymentIntentParams) { confirmResult, confirmError in
                completion(confirmResult, confirmError)
            }
        }
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension ApplePayService: PKPaymentAuthorizationControllerDelegate {
    nonisolated func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        Task { @MainActor in
            self.paymentWasAuthorized = true
            self.onPaymentSuccess?(payment)
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
    }

    nonisolated func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        Task { @MainActor in
            controller.dismiss()

            if !self.paymentWasAuthorized {
                self.onCancelled?()
            }
        }
    }
}
