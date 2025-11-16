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
            ZStack {
                // Base Image with Matched Transition Source
                Group {
                    KFImage(URL(string: event.imageUrl))
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .if(namespace != nil && event.id != nil) { view in
                    view.matchedGeometryEffect(id: "heroImage-\(event.id!)", in: namespace!)
                }
                .if(namespace != nil && event.id != nil) { view in
                    view.matchedTransitionSource(id: "heroImage-\(event.id!)", in: namespace!) { source in
                        source
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                }
                .overlay(
                    // Progressive Blur Overlay (top to bottom fade)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.white.opacity(0.15), location: 0.0),
                                    .init(color: Color.clear, location: 0.3)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .blur(radius: 20)
                        .opacity(0.6)
                )

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
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
                                
                                // ✅ Safe unwrapping of optional date
                                if let startTime = event.startTime {
                                    Text("\(startTime.formatted(.dateTime.weekday().day().month())) • \(event.venue)")
                                        .appBody()
                                        .foregroundColor(.white.opacity(0.8))
                                } else {
                                    Text("- • \(event.venue)")
                                        .appBody()
                                        .foregroundColor(.white.opacity(0.8))
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
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isBookmarked)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(width: geometry.size.width, height: 400)
            }
        }
        .frame(height: 400)
    }
}
