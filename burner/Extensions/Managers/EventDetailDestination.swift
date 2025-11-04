import SwiftUI

struct EventDetailDestination: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var appState: AppState

    let eventId: String
    @State private var event: Event?
    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        Group {
            if let event {
                EventDetailView(event: event)
            } else if isLoading {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Loading event...")
                            .foregroundColor(.white)
                        Text("Event ID: \(eventId)")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            } else if let loadError {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Couldn't open event")
                            .foregroundColor(.white)
                            .font(.headline)
                        Text(loadError)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("Event ID: \(eventId)")
                            .foregroundColor(.gray)
                            .font(.caption)
                            .padding(.top, 8)
                        Button("Retry") {
                            self.loadError = nil
                            Task { await load() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                    }
                    .padding()
                }
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Preparing event...")
                            .foregroundColor(.white)
                        Text("Event ID: \(eventId)")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .onAppear {
                    print("🟢 EventDetailDestination.onAppear - Starting load for eventId: \(eventId)")
                    Task { await load() }
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            print("🟢 EventDetailDestination VIEW appeared with eventId: \(eventId)")
        }
        .onDisappear {
            print("🔴 EventDetailDestination VIEW disappeared")
        }
    }

    private func load() async {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 EventDetailDestination.load() START")
        print("   Event ID: \(eventId)")
        // Removed Thread.isMainThread check as it's not safe in async context
        
        // Validate eventId
        guard !eventId.isEmpty else {
            print("❌ Event ID is empty!")
            await MainActor.run {
                loadError = "Invalid event ID"
            }
            return
        }

        // First check if event is already loaded in memory
        print("📦 Checking cache... EventViewModel has \(eventViewModel.events.count) events")
        if let e = eventViewModel.events.first(where: { $0.id == eventId }) {
            print("✅ Found event in cache:")
            print("   Name: \(e.name)")
            print("   Venue: \(e.venue)")
            await MainActor.run {
                event = e
            }
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }

        print("⚠️ Event not in cache, fetching from server...")
        print("   Available event IDs in cache: \(eventViewModel.events.compactMap { $0.id }.prefix(5))")
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
                print("🏁 EventDetailDestination.load() COMPLETE")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            }
        }

        do {
            print("📡 Calling eventViewModel.fetchEvent(byId: \(eventId))...")
            let e = try await eventViewModel.fetchEvent(byId: eventId)
            print("✅ Successfully fetched event:")
            print("   Name: \(e.name)")
            print("   Venue: \(e.venue)")
            print("   Price: £\(e.price)")
            await MainActor.run {
                event = e
            }
        } catch {
            print("❌ Failed to fetch event:")
            print("   Error: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Localized: \(error.localizedDescription)")
            await MainActor.run {
                loadError = error.localizedDescription
            }
        }
    }
}
