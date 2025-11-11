import Foundation
import os

#if DEBUG
final class PaymentTrace {
    static let log = OSLog(subsystem: "com.burner.app", category: "Payments")
    static var useSignposts = false

    private let name: String
    private let id: String
    private let startedAt = ContinuousClock.now
    private var lastMark: ContinuousClock.Instant

    init(name: String, context: [String: CustomStringConvertible] = [:]) {
        self.name = name
        self.id = String(UUID().uuidString.prefix(8))
        self.lastMark = startedAt
        mark("START", extra: context.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
    }

    @discardableResult
    func mark(_ label: String, extra: String? = nil) -> Duration {
        let now = ContinuousClock.now
        let total: Duration = now - startedAt
        let delta: Duration = now - lastMark
        lastMark = now

        let msg = "[\(name)#\(id)] \(label)  +\(delta.ms)ms  t=\(total.ms)ms" + (extra.map { " | \($0)" } ?? "")
        if Self.useSignposts {
            let spid = OSSignpostID(log: Self.log)
            // Use a literal StaticString for the name
            os_signpost(.event, log: Self.log, name: "PaymentTrace", signpostID: spid, "%{public}s", msg)
        } else {
            print("⏱️ \(msg)")
        }
        return total
    }

    func finish(success: Bool, message: String? = nil) {
        mark(success ? "FINISH ✅" : "FINISH ❌", extra: message)
    }
}

private extension Duration {
    var ms: String {
        let c = components
        let secMs  = Double(c.seconds) * 1000.0
        let attoMs = Double(c.attoseconds) / 1_000_000_000_000_000.0
        return String(format: "%.1f", secMs + attoMs)
    }
}
#else
final class PaymentTrace {
    init(name: String, context: [String: CustomStringConvertible] = [:]) {}
    @discardableResult func mark(_ label: String, extra: String? = nil) -> Any? { nil }
    func finish(success: Bool, message: String? = nil) {}
}
#endif
