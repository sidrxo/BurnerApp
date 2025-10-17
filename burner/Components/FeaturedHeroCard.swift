import SwiftUI
import Kingfisher

struct FeaturedHeroCard: View {
    let event: Event
    @ObservedObject var bookmarkManager: BookmarkManager
    
    private var isBookmarked: Bool {
        guard let eventId = event.id else { return false }
        return bookmarkManager.isBookmarked(eventId)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                KFImage(URL(string: event.imageUrl))
                    .placeholder {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width, height: 500)
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
                                
                                Text("\(event.date.formatted(.dateTime.weekday().day().month())) • \(event.venue)")
        .appBody()                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("£\(String(format: "%.2f", event.price))")
        .appBody()                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            Button(action: {
                                Task {
                                    await bookmarkManager.toggleBookmark(for: event)
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
                .frame(width: geometry.size.width, height: 500)
            }
        }
        .frame(height: 500)
    }
}
