import Foundation
import FirebaseAuth
import FirebaseFunctions
@_spi(STP) import StripePaymentSheet
import StripeCore

/// Handles CRUD operations for payment methods
@MainActor
class PaymentMethodRepository: ObservableObject {
    @Published var paymentMethods: [PaymentMethodInfo] = []

    private let functions = Functions.functions(region: "europe-west2")

    // MARK: - Fetch Payment Methods

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

    // MARK: - Save Payment Method

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

    // MARK: - Delete Payment Method

    func deletePaymentMethod(paymentMethodId: String) async throws {
        let data = try await callStripeFunction("deletePaymentMethod", data: [
            "paymentMethodId": paymentMethodId
        ])

        guard let success = data["success"] as? Bool, success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    // MARK: - Set Default Payment Method

    func setDefaultPaymentMethod(paymentMethodId: String) async throws {
        let data = try await callStripeFunction("setDefaultPaymentMethod", data: [
            "paymentMethodId": paymentMethodId
        ])

        guard let success = data["success"] as? Bool, success else {
            throw PaymentError.paymentFailed
        }

        try await fetchPaymentMethods()
    }

    // MARK: - Stripe Function Helper

    private func callStripeFunction(
        _ name: String,
        data: [String: Any]? = nil
    ) async throws -> [String: Any] {
        guard Auth.auth().currentUser != nil else {
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
}
