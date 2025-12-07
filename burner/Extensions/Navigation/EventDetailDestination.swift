// EventDetailDestination.swift
import SwiftUI

struct EventDetailDestination: View {
    @EnvironmentObject var eventViewModel: EventViewModel
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var ticketsViewModel: TicketsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.heroNamespace) private var heroNamespace

    let eventId: String
    
    // REMOVED: @State private var event: Event?
    // ADDED: Computed property that always gets latest event
    private var event: Event? {
        eventViewModel.events.first(where: { $0.id == eventId })
    }
    
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var hasAttemptedFetch = false

    var body: some View {
        Group {
            if event != nil {
                // CHANGE: Pass eventId instead of event object
                EventDetailView(eventId: eventId, namespace: heroNamespace)
            } else if isLoading {
                loadingView
            } else if let loadError = loadError {
                errorView(error: loadError)
            } else {
                loadingView
                    .onAppear {
                        if !hasAttemptedFetch {
                            Task { await load() }
                        }
                    }
            }
        }
        .navigationBarBackButtonHidden(false)
        // ADDED: Watch for changes to eventViewModel.events
        .onChange(of: eventViewModel.events.count) { _, _ in
            // If we were loading and now the event appears, stop loading
            if isLoading && event != nil {
                isLoading = false
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                Text(hasAttemptedFetch ? "Loading event..." : "Preparing event...")
                    .foregroundColor(.white)
                Text("Event ID: \(eventId)")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
    }
    
    private func errorView(error: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("Couldn't open event")
                    .foregroundColor(.white)
                    .font(.headline)
                Text(error)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("Event ID: \(eventId)")
                    .foregroundColor(.gray)
                    .font(.caption)
                    .padding(.top, 8)
                Button("Retry") {
                    self.loadError = nil
                    self.hasAttemptedFetch = false
                    Task { await load() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.white)
            }
            .padding()
        }
    }

    private func load() async {
        // Validate eventId
        guard !eventId.isEmpty else {
            await MainActor.run {
                loadError = "Invalid event ID"
                hasAttemptedFetch = true
            }
            return
        }

        // Check if event is already loaded in memory
        if event != nil {
            await MainActor.run {
                hasAttemptedFetch = true
            }
            return
        }

        await MainActor.run {
            isLoading = true
            hasAttemptedFetch = true
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            // Fetch event from Firestore. The ViewModel handles adding it to the 'events' array.
            _ = try await eventViewModel.fetchEvent(byId: eventId)
            
            // SIMPLIFICATION: No need for post-fetch check, as the ViewModel handles insertion/update.

        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
            }
        }
    }
}
