import SwiftUI

/// Manual ticket entry sheet for scanner
struct ManualEntrySheet: View {
    @Binding var isPresented: Bool
    @Binding var ticketNumber: String
    let onSubmit: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 20) {
                Text("Enter Ticket Number")
                    .appSectionHeader()
                    .foregroundColor(.white)

                TextField("Ticket Number", text: $ticketNumber)
                    .padding(12)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("CANCEL") {
                        dismiss()
                    }
                    .appBody()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("SUBMIT") {
                        submit()
                    }
                    .appBody()
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(ticketNumber.isEmpty)
                    .opacity(ticketNumber.isEmpty ? 0.5 : 1.0)
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 40)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func dismiss() {
        isPresented = false
        ticketNumber = ""
    }

    private func submit() {
        guard !ticketNumber.isEmpty else { return }
        isPresented = false
        onSubmit(ticketNumber)
        ticketNumber = ""
    }
}
