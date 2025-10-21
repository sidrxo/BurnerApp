import SwiftUI
import UIKit
@_spi(STP) import StripePaymentSheet
import StripeUICore

// MARK: - Card Input View
struct CardInputView: View {
    @Binding var cardParams: STPPaymentMethodCardParams?
    @Binding var isValid: Bool

    var body: some View {
        CardTextField(cardParams: $cardParams, isValid: $isValid)
            .frame(height: 50)
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Card Text Field (UIKit Bridge)
struct CardTextField: UIViewRepresentable {
    @Binding var cardParams: STPPaymentMethodCardParams?
    @Binding var isValid: Bool

    func makeUIView(context: Context) -> STPCardFormView {
        let cardFormView = STPCardFormView(billingAddressCollection: .automatic)
        cardFormView.backgroundColor = .clear
        cardFormView.delegate = context.coordinator
        return cardFormView
    }

    func updateUIView(_ uiView: STPCardFormView, context: Context) {
        // Update UI if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, STPCardFormViewDelegate {
        var parent: CardTextField

        init(_ parent: CardTextField) {
            self.parent = parent
        }

        func cardFormView(_ form: STPCardFormView, didChangeToStateComplete complete: Bool) {
            parent.isValid = complete

            if complete {
                // Create card params from the form
                let cardParams = form.cardParams
                parent.cardParams = cardParams
            } else {
                parent.cardParams = nil
            }
        }
    }
}
