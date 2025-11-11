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
                    Task { await load() }
                }
            }
        }
        .navigationBarBackButtonHidden(false)
    }

    private func load() async {
        // Validate eventId
        guard !eventId.isEmpty else {
            await MainActor.run {
                loadError = "Invalid event ID"
            }
            return
        }

        // First check if event is already loaded in memory
        if let e = eventViewModel.events.first(where: { $0.id == eventId }) {
            await MainActor.run {
                event = e
            }
            return
        }

        await MainActor.run {
            isLoading = true
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            let e = try await eventViewModel.fetchEvent(byId: eventId)
            await MainActor.run {
                event = e
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
            }
        }
    }
}
