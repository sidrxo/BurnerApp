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
                    .environmentObject(bookmarkManager)
                    .environmentObject(eventViewModel)
                    .environmentObject(ticketsViewModel)
                    .environmentObject(TabBarVisibility(isDetailViewPresented: $appState.isDetailViewPresented))
                    .environmentObject(appState)
            } else if isLoading {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            } else if let loadError {
                VStack(spacing: 12) {
                    Text("Couldn’t open event").foregroundColor(.white)
                    Text(loadError).foregroundColor(.gray)
                    Button("Retry") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
                .background(Color.black.ignoresSafeArea())
            } else {
                Color.black.ignoresSafeArea().onAppear { Task { await load() } }
            }
        }
        .navigationBarBackButtonHidden(false)
    }

    private func load() async {
        if let e = eventViewModel.events.first(where: { $0.id == eventId }) {
            event = e
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let e = try await eventViewModel.fetchEvent(byId: eventId)
            event = e
        } catch {
            loadError = error.localizedDescription
        }
    }
}
