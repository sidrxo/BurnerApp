//
//  TicketRowView.swift
//  burner
//
//  Created by Sid Rao on 19/09/2025.
//


import SwiftUI
import Kingfisher

struct TicketRowView: View {
    let ticketWithEvent: TicketWithEventData
    let isPast: Bool
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let url = URL(string: ticketWithEvent.event.imageUrl), !ticketWithEvent.event.imageUrl.isEmpty {
                KFImage(url)
                    .placeholder {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ticketWithEvent.event.name)
                    .appFont(size: 16, weight: .semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(ticketWithEvent.event.venue)
                    .appFont(size: 14)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(ticketWithEvent.event.date.formatted(date: .abbreviated, time: .shortened))
                        .appFont(size: 12)
                        .foregroundColor(.gray)
                }
                HStack(spacing: 8) {
                    if ticketWithEvent.ticket.status == "cancelled" {
                        Text("Cancelled")
                            .appFont(size: 12, weight: .medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else if isPast {
                        Text("Past Event")
                            .appFont(size: 12, weight: .medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                if !isPast && ticketWithEvent.ticket.status == "confirmed" {
                    Image(systemName: "qrcode")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                } else if isPast {
                    Text("Attended")
                        .appFont(size: 12, weight: .medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            if !isPast && ticketWithEvent.ticket.status == "confirmed" {
                Button("Cancel Ticket", role: .destructive) {
                    onCancel()
                }
            }
        }
    }
}