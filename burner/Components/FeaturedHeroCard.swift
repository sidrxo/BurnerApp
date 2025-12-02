import SwiftUI
import Kingfisher
import FirebaseAuth

struct FeaturedHeroCard: View {
    let event: Event
    @ObservedObject var bookmarkManager: BookmarkManager
    @Binding var showingSignInAlert: Bool
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: NavigationCoordinator
    var namespace: Namespace.ID?

    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }

    var body: some View {
        GeometryReader { geometry in
            let imageHeight: CGFloat = 420

            ZStack(alignment: .top) {
                // 1. Base image
                KFImage(URL(string: event.imageUrl))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                // 2. The Blur + Gradient Stack
                ZStack {
                    // Custom Variable Blur (The internal curve now starts higher)
                    VariableBlurView(
                        maxBlurRadius: 20,
                        direction: .blurredBottomClearTop
                    )
                    .frame(width: geometry.size.width, height: imageHeight)
                    
                    // Darkening Gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.6)
                        ]),
                        // EDITED: Raised the start point to match the higher blur transition
                        startPoint: UnitPoint(x: 0.5, y: 0.3),
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // 3. Content
                VStack {
                    HStack {
                        Spacer()
                        Text("FEATURED")
                            .appCaption()
                            .tracking(1.5)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)

                    Spacer()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(event.name)
    
                                    .appPageHeader()
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                if let startTime = event.startTime {
                                    Text("\(startTime.formatted(.dateTime.weekday().day().month())) • \(event.venue)")
                                        .appBody()
                                        .foregroundColor(.white.opacity(0.9))
                                } else {
                                    Text("- • \(event.venue)")
                                        .appBody()
                                        .foregroundColor(.white.opacity(0.9))
                                }

                                Text("£\(String(format: "%.2f", event.price))")
                                    .appBody()
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            Button(action: {
                                if Auth.auth().currentUser == nil {
                                    showingSignInAlert = true
                                } else {
                                    Task {
                                        await bookmarkManager.toggleBookmark(for: event)
                                    }
                                }
                            }) {
                                Image(systemName: isBookmarked ? "heart.fill" : "heart")
                                    .appSectionHeader()
                                    .foregroundColor(isBookmarked ? .white : .white.opacity(0.7))
                                    .scaleEffect(isBookmarked ? 1.1 : 1.0)
                                    .animation(
                                        .spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0),
                                        value: isBookmarked
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(width: geometry.size.width, height: imageHeight)
            }
            .applyIf(namespace != nil && event.id != nil) { view in
                view.matchedTransitionSource(id: "heroImage-\(event.id!)", in: namespace!) { source in
                    source.clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .frame(height: 420)
    }
}

extension View {
    @ViewBuilder
    func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
