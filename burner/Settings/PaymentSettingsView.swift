//
//  PaymentSettingsView.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//

import SwiftUI
import FirebaseAuth
@_spi(STP) import StripePaymentSheet

struct PaymentSettingsView: View {
    @StateObject private var paymentService = StripePaymentService()
    @State private var showAddCard = false
    @State private var cardParams: STPPaymentMethodCardParams?
    @State private var isCardValid = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                SettingsHeaderSection(title: "Payment Methods")
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    Spacer()
                } else if showAddCard {
                    // Add card view
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("Add Payment Method")
                                .appSectionHeader()
                                .foregroundColor(.white)
                                .padding(.top, 20)

                            CardInputView(cardParams: $cardParams, isValid: $isCardValid)
                                .padding(.horizontal, 16)

                            HStack(spacing: 12) {
                                Button(action: {
                                    showAddCard = false
                                    cardParams = nil
                                    isCardValid = false
                                }) {
                                    Text("Cancel")
                                        .appBody()
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                        .background(Color.gray.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                Button(action: saveCard) {
                                    Text("Save Card")
                                        .appBody()
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                        .background(isCardValid ? Color.white.opacity(0.15) : Color.gray.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .disabled(!isCardValid)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if paymentService.paymentMethods.isEmpty {
                                VStack(spacing: 12) {
                                    Text("No payment methods")
                                        .appBody()
                                        .foregroundColor(.gray)

                                    Text("Add one to speed up checkout next time.")
                                        .appSecondary()
                                        .foregroundColor(.gray.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 80)
                            } else {
                                ForEach(paymentService.paymentMethods) { method in
                                    PaymentMethodRow(
                                        method: method,
                                        onSetDefault: {
                                            setDefaultPaymentMethod(method.id)
                                        },
                                        onDelete: {
                                            deletePaymentMethod(method.id)
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.85),
                                    Color.black
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()

                            addPaymentButton
                                .padding(.horizontal, 16)
                                .padding(.top, 16)
                                .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadPaymentMethods()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var addPaymentButton: some View {
        Button(action: {
            showAddCard = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))

                Text("Add Payment Method")
                    .appBody()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func loadPaymentMethods() {
        guard Auth.auth().currentUser != nil else {
            return
        }

        isLoading = true
        Task {
            do {
                try await paymentService.fetchPaymentMethods()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to load payment methods: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func saveCard() {
        guard let cardParams = cardParams else { return }

        isLoading = true
        Task {
            do {
                try await paymentService.savePaymentMethod(
                    cardParams: cardParams,
                    setAsDefault: paymentService.paymentMethods.isEmpty
                )
                await MainActor.run {
                    isLoading = false
                    showAddCard = false
                    self.cardParams = nil
                    isCardValid = false
                    alertTitle = "Success"
                    alertMessage = "Payment method added successfully"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to add payment method: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func deletePaymentMethod(_ paymentMethodId: String) {
        isLoading = true
        Task {
            do {
                try await paymentService.deletePaymentMethod(paymentMethodId: paymentMethodId)
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Payment method deleted"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to delete payment method: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    private func setDefaultPaymentMethod(_ paymentMethodId: String) {
        isLoading = true
        Task {
            do {
                try await paymentService.setDefaultPaymentMethod(paymentMethodId: paymentMethodId)
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Success"
                    alertMessage = "Default payment method updated"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertTitle = "Error"
                    alertMessage = "Failed to update default payment method: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Payment Method Row
struct PaymentMethodRow: View {
    let method: StripePaymentService.PaymentMethodInfo
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // Card icon
            Image(systemName: cardIcon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Card info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(method.brand.capitalized)
                        .appBody()
                        .foregroundColor(.white)

                    if method.isDefault {
                        Text("DEFAULT")
                            .appCaption()
                            .foregroundColor(.black)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }

                Text("•••• \(method.last4)")
                    .appBody()
                    .foregroundColor(.gray)

                Text("Expires \(method.expMonth)/\(method.expYear)")
                    .appCaption()
                    .foregroundColor(.gray)
            }

            Spacer()

            // Actions menu
            Menu {
                if !method.isDefault {
                    Button(action: onSetDefault) {
                        Label("Set as Default", systemImage: "star.fill")
                    }
                }

                Button(role: .destructive, action: {
                    showingDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Payment Method"),
                message: Text("Are you sure you want to delete this payment method?"),
                primaryButton: .destructive(Text("Delete")) {
                    onDelete()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var cardIcon: String {
        switch method.brand.lowercased() {
        case "visa":
            return "creditcard.fill"
        case "mastercard":
            return "creditcard.fill"
        case "amex", "american express":
            return "creditcard.fill"
        default:
            return "creditcard.fill"
        }
    }
}
