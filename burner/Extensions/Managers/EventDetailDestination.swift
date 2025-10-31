//
//  EventDetailDestination.swift
//  burner
//
//  Created by Sid Rao on 31/10/2025.
//


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
                        Button("Retry") {
                            loadError = nil
                            Task { await load() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.white)
                    }
                }
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Loading event...")
                            .foregroundColor(.white)
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
        print("🔍 EventDetailDestination: Loading event with ID: \(eventId)")

        // First check if event is already loaded in memory
        if let e = eventViewModel.events.first(where: { $0.id == eventId }) {
            print("✅ Found event in cache: \(e.title)")
            event = e
            return
        }

        print("📡 Fetching event from server...")
        isLoading = true
        defer { isLoading = false }

        do {
            let e = try await eventViewModel.fetchEvent(byId: eventId)
            print("✅ Successfully fetched event: \(e.title)")
            event = e
        } catch {
            print("❌ Failed to fetch event: \(error.localizedDescription)")
            loadError = error.localizedDescription
        }
    }
}
