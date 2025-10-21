import SwiftUI
import UIKit
@_spi(STP) import StripePaymentSheet
import StripeUICore
import StripePaymentsUI

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

    func makeUIView(context: Context) -> STPPaymentCardTextField {
        let cardTextField = STPPaymentCardTextField()
        cardTextField.borderWidth = 0
        cardTextField.backgroundColor = .clear
        cardTextField.textColor = .white
        cardTextField.placeholderColor = .gray
        cardTextField.borderColor = .clear
        cardTextField.delegate = context.coordinator

        // Customize appearance
        cardTextField.font = UIFont.systemFont(ofSize: 16)
        cardTextField.postalCodeEntryEnabled = true

        return cardTextField
    }

    func updateUIView(_ uiView: STPPaymentCardTextField, context: Context) {
        // Update UI if needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, STPPaymentCardTextFieldDelegate {
        var parent: CardTextField

        init(_ parent: CardTextField) {
            self.parent = parent
        }

        func paymentCardTextFieldDidChange(_ textField: STPPaymentCardTextField) {
            parent.isValid = textField.isValid

            if textField.isValid {
                // Create card params from the text field
                let cardParams = STPPaymentMethodCardParams()
                cardParams.number = textField.cardNumber
                cardParams.expMonth = NSNumber(value: textField.expirationMonth)
                cardParams.expYear = NSNumber(value: textField.expirationYear)
                cardParams.cvc = textField.cvc

                parent.cardParams = cardParams
            } else {
                parent.cardParams = nil
            }
        }
    }
}
