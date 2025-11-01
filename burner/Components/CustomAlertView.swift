import SwiftUI

struct CustomAlertView<Content: View>: View {

    @Environment(\.colorScheme) var colorScheme

    let title: String
    let description: String

    var cancelAction: (() -> Void)?
    var cancelActionTitle: String?

    var primaryAction: (() -> Void)?
    var primaryActionTitle: String?

    var customContent: Content?

    init(title: String,
         description: String,
         cancelAction: (() -> Void)? = nil,
         cancelActionTitle: String? = nil,
         primaryAction: (() -> Void)? = nil,
         primaryActionTitle: String? = nil,
         customContent: Content? = EmptyView()) {
        self.title = title
        self.description = description
        self.cancelAction = cancelAction
        self.cancelActionTitle = cancelActionTitle
        self.primaryAction = primaryAction
        self.primaryActionTitle = primaryActionTitle
        self.customContent = customContent
    }

    var body: some View {
        HStack {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 19)
                    .padding(.bottom, 2)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 19)

                customContent

                Divider()
                    .background(Color.white.opacity(0.2))

                HStack {
                    if let cancelAction, let cancelActionTitle {
                        Button { cancelAction() } label: {
                            Text(cancelActionTitle)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        }
                    }

                    if cancelActionTitle != nil && primaryActionTitle != nil {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }

                    if let primaryAction, let primaryActionTitle {
                        Button { primaryAction() } label: {
                            Text(primaryActionTitle)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                        }
                    }
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, maxHeight: 44, alignment: .center)
            }
            .frame(minWidth: 0, maxWidth: 270, alignment: .center)
            .background(Color(white: 0.11).opacity(0.98))
            .cornerRadius(14)
            .padding([.trailing, .leading], 50)
        }
        .zIndex(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            colorScheme == .dark
            ? Color(red: 0, green: 0, blue: 0, opacity: 0.4)
            : Color(red: 1, green: 1, blue: 1, opacity: 0.4)
        )
    }
}



#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()
        
        CustomAlertView(
            title: "Sign In Required",
            description: "You need to be signed in to buy tickets.",
            cancelAction: {
                // Cancel action
            },
            cancelActionTitle: "Cancel",
            primaryAction: {
                // Primary action
            },
            primaryActionTitle: "Sign In",
            customContent: EmptyView()
        )
    }
    .preferredColorScheme(.dark)
}
