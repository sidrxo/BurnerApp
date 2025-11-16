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
                // Base image
                KFImage(URL(string: event.imageUrl))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .applyIf(namespace != nil && event.id != nil) { view in
                        view.matchedTransitionSource(id: "heroImage-\(event.id!)", in: namespace!) { source in
                            source
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }

                // Gentle progressive blur overlay
                ZStack {
                    // Variable blur with more gradual progression
                    VariableBlurView(
                        maxBlurRadius: 20, // Reduced back to 20 for subtlety
                        direction: .blurredBottomClearTop,
                        startOffset: 0.7 // Much earlier start for gentler ramp
                    )
                    .frame(width: geometry.size.width, height: imageHeight)
                    
                    // Very subtle gradient to enhance the gentle progression
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.black.opacity(0.05),
                            Color.black.opacity(0.15)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Soft dark overlay for text readability
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // Content
                VStack {
                    HStack {
                        Spacer()
                        Text("FEATURED")
                            .appCaption()
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
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
                                    .appHero()
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
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
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
        }
        .frame(height: 420)
    }
}

// Helper extension remains the same
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
