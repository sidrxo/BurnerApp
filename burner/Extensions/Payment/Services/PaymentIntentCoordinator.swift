import Foundation
import FirebaseAuth
import FirebaseFunctions

/// Manages payment intent creation, preparation, and lifecycle
@MainActor
class PaymentIntentCoordinator: ObservableObject {
    @Published var isPreparing = false

    private var preparedClientSecret: String?
    private var preparedIntentId: String?
    private var preparedEventId: String?
    private var preparationTask: Task<Void, Never>?

    private let functions = Functions.functions(region: "europe-west2")

    // MARK: - Payment Intent Preparation

    /// Prepares a payment intent in advance to reduce checkout latency
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
                // Auto-expire after 10 minutes
                Task {
                    try? await Task.sleep(nanoseconds: 10 * 60 * 1_000_000_000)
                    await self.clearPreparedIntent(ifMatching: intentId)
                }
            } catch {
                await MainActor.run { self.isPreparing = false }
            }
        }
    }

    /// Clears a specific prepared intent if it matches
    private func clearPreparedIntent(ifMatching intentId: String) async {
        await MainActor.run {
            if self.preparedIntentId == intentId {
                self.preparedClientSecret = nil
                self.preparedIntentId = nil
                self.preparedEventId = nil
            }
        }
    }

    /// Clears all prepared intents
    func clearPreparedIntent() {
        preparationTask?.cancel()
        preparedClientSecret = nil
        preparedIntentId = nil
        preparedEventId = nil
        isPreparing = false
    }

    // MARK: - Payment Intent Management

    /// Returns either a pre-created payment intent or creates a new one
    func getPaymentIntent(
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

    /// Creates a new payment intent via Firebase function
    private func createPaymentIntent(eventId: String) async throws -> (clientSecret: String, paymentIntentId: String) {
        let data = try await callStripeFunction("createPaymentIntent", data: ["eventId": eventId])
        guard let clientSecret = data["clientSecret"] as? String,
              let paymentIntentId = data["paymentIntentId"] as? String else {
            throw PaymentError.invalidResponse
        }
        return (clientSecret, paymentIntentId)
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
