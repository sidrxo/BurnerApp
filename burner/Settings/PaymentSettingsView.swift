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

    // MARK: - Logging state
    @State private var fetchLogStart: Date? = nil
    @State private var fetchLogStep: Int = 0
    private static let timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss.SSS"
        return df
    }()
    private func startFetchLog(_ reason: String) {
        fetchLogStart = Date()
        fetchLogStep = 0
        logFetch("START fetchPaymentMethods (\(reason))")
    }
    private func logFetch(_ message: String) {
        fetchLogStep += 1
        let now = Date()
        _ = Self.timeFormatter.string(from: now)
        let elapsed = fetchLogStart.map { now.timeIntervalSince($0) } ?? 0
        _ = String(format: "%.3fs", elapsed)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderSection(title: "Payment Methods", includeTopPadding: false, includeHorizontalPadding: false)
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
                                        .background(Color.white.opacity(0.05))
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
                                // Simple empty state
                                VStack(spacing: 12) {
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.top, 28)

                                    Text("No saved payment methods")
                                        .appSectionHeader()
                                        .foregroundColor(.white)

                                    Text("Add a card to speed up checkout.")
                                        .appBody()
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
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

                            // Add button here
                            addPaymentButton
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    }
                }
            }

            if showAlert {
                CustomAlertView(
                    title: alertTitle,
                    description: alertMessage,
                    primaryAction: { showAlert = false },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
                .zIndex(1001)
            }
        }
        .onAppear {
            loadPaymentMethods()
        }
    }

    // MARK: - Add Payment Button
    private var addPaymentButton: some View {
        Button(action: {
            showAddCard = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .appCard()

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

    // MARK: - Fetch methods with logging/timer
    private func loadPaymentMethods(reason: String = "onAppear") {
        guard Auth.auth().currentUser != nil else {
            startFetchLog(reason)
            logFetch("SKIP: No authenticated user")
            return
        }
        guard !isLoading else {
            startFetchLog(reason)
            logFetch("SKIP: Already loading")
            return
        }

        startFetchLog(reason)
        isLoading = true
        logFetch("Calling paymentService.fetchPaymentMethods()")

        Task {
            do {
                try await paymentService.fetchPaymentMethods()
                await MainActor.run {
                    isLoading = false
                    logFetch("SUCCESS: fetched \(paymentService.paymentMethods.count) methods")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    logFetch("ERROR: \(error.localizedDescription)")
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
                // Optional: refresh with logging
                // loadPaymentMethods(reason: "post-save refresh")
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
                // End loading state so our load guard passes
                await MainActor.run {
                    isLoading = false
                }
                // Refresh the payment methods list after deletion with logging
                loadPaymentMethods(reason: "post-delete refresh")
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
                // Optional: refresh with logging
                // loadPaymentMethods(reason: "post-setDefault refresh")
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
                .appSectionHeader()
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.05))
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
                    .appSectionHeader()
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .confirmationDialog(
            "Delete Payment Method",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text("Are you sure you want to delete this payment method?")
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
