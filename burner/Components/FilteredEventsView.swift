//
//  FilteredEventsView.swift
//  burner
//
//  Created by Sid Rao on 20/10/2025.
//


import SwiftUI
import Kingfisher

// MARK: - Filtered Events View
struct FilteredEventsView: View {
    let title: String
    let events: [Event]
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header with back button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.appIcon)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(title)
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible spacer for symmetry
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            .padding(.bottom, 20)
            
            if events.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(events) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                UnifiedEventRow(
                                    event: event,
                                    bookmarkManager: bookmarkManager
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.appLargeIcon)
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Events Found")
                    .appSectionHeader()
                    .foregroundColor(.white)
                
                Text("No events available in this category")
                    .appBody()
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationStack {
        FilteredEventsView(
            title: "Techno",
            events: []
        )
        .environmentObject(AppState().bookmarkManager)
    }
    .preferredColorScheme(.dark)
}