import SwiftUI

// MARK: - Custom Alert
struct CustomAlert: View {
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryButtonAction: () -> Void
    let secondaryButtonTitle: String?
    let secondaryButtonAction: (() -> Void)?
    let isDestructive: Bool

    @Environment(\.dismiss) var dismiss

    init(
        title: String,
        message: String,
        primaryButtonTitle: String,
        primaryButtonAction: @escaping () -> Void,
        secondaryButtonTitle: String? = nil,
        secondaryButtonAction: (() -> Void)? = nil,
        isDestructive: Bool = false
    ) {
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryButtonAction = primaryButtonAction
        self.secondaryButtonTitle = secondaryButtonTitle
        self.secondaryButtonAction = secondaryButtonAction
        self.isDestructive = isDestructive
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }

            // Alert content
            VStack(spacing: 0) {
                // Title
                Text(title)
                    .appSectionHeader()
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                // Message
                Text(message)
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                // Buttons
                HStack(spacing: 0) {
                    // Secondary button (if provided)
                    if let secondaryTitle = secondaryButtonTitle {
                        Button(action: {
                            secondaryButtonAction?()
                            dismiss()
                        }) {
                            Text(secondaryTitle)
                                .appBody()
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)
                    }

                    // Primary button
                    Button(action: {
                        primaryButtonAction()
                        dismiss()
                    }) {
                        Text(primaryButtonTitle)
                            .appBody()
                            .fontWeight(.semibold)
                            .foregroundColor(isDestructive ? .red : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
            }
            .frame(width: 280)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Custom Alert Modifier
struct CustomAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryButtonAction: () -> Void
    let secondaryButtonTitle: String?
    let secondaryButtonAction: (() -> Void)?
    let isDestructive: Bool

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                CustomAlert(
                    title: title,
                    message: message,
                    primaryButtonTitle: primaryButtonTitle,
                    primaryButtonAction: primaryButtonAction,
                    secondaryButtonTitle: secondaryButtonTitle,
                    secondaryButtonAction: secondaryButtonAction,
                    isDestructive: isDestructive
                )
                .background(ClearBackgroundView())
                .presentationBackground(.clear)
            }
    }
}

// MARK: - Clear Background View
struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - View Extension
extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        primaryButtonTitle: String,
        primaryButtonAction: @escaping () -> Void,
        secondaryButtonTitle: String? = nil,
        secondaryButtonAction: (() -> Void)? = nil,
        isDestructive: Bool = false
    ) -> some View {
        self.modifier(
            CustomAlertModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                primaryButtonTitle: primaryButtonTitle,
                primaryButtonAction: primaryButtonAction,
                secondaryButtonTitle: secondaryButtonTitle,
                secondaryButtonAction: secondaryButtonAction,
                isDestructive: isDestructive
            )
        )
    }
}

#Preview {
    VStack {
        Text("Preview")
    }
    .customAlert(
        isPresented: .constant(true),
        title: "Sign In Required",
        message: "You need to be signed in to buy tickets.",
        primaryButtonTitle: "Sign In",
        primaryButtonAction: {},
        secondaryButtonTitle: "Cancel",
        secondaryButtonAction: {}
    )
}
