//
//  ApplePayHandler.swift
//  burner
//
//  Created by Sid Rao on 16/10/2025.
//


import PassKit
import UIKit

class ApplePayHandler: NSObject {
    static let shared = ApplePayHandler()
    
    var paymentController: PKPaymentAuthorizationController?
    var paymentSummaryItems = [PKPaymentSummaryItem]()
    var onPaymentSuccess: ((PKPayment) -> Void)?
    var onPaymentFailure: ((Error) -> Void)?
    
    // Replace with your actual Merchant ID from Apple Developer
    let merchantID = "merchant.BurnerTickets"
    let currencyCode = "GBP"
    let countryCode = "GB"
    
    func startPayment(
        eventName: String,
        amount: Double,
        onSuccess: @escaping (PKPayment) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.onPaymentSuccess = onSuccess
        self.onPaymentFailure = onFailure
        
        // Create payment summary items
        let ticketItem = PKPaymentSummaryItem(
            label: "Ticket: \(eventName)",
            amount: NSDecimalNumber(value: amount),
            type: .final
        )
        
        let total = PKPaymentSummaryItem(
            label: "Burner", // Replace with your app name
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
    
    static func canMakePayments() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments()
    }
    
    static func canMakePaymentsWithActiveCard() -> Bool {
        return PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex, .discover])
    }
}

extension ApplePayHandler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Here you would send the payment token to your backend
        // For now, we'll just call success
        
        // Example: Send payment.token.paymentData to your server
        // let paymentData = payment.token.paymentData
        
        onPaymentSuccess?(payment)
        
        // Complete the payment
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}
