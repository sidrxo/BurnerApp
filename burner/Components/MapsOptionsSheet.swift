//
//  MapsOptionsSheet.swift
//  burner
//
//  Created by Sid Rao on 16/11/2025.
//

import SwiftUI
import MapKit

struct MapsOptionsSheet: View {
    let latitude: Double
    let longitude: Double
    let venueName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Open in Maps")
                .appBody()
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top, 30)
                .padding(.bottom, 16)

            VStack(spacing: 12) {
                Button(action: {
                    openInAppleMaps()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "map")
                            .appCard()
                        Text("Apple Maps")
                            .appBody()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appSecondary()
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    openInGoogleMaps()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "globe")
                            .appCard()
                        Text("Google Maps")
                            .appBody()
                        Spacer()
                        Image(systemName: "chevron.right")
                            .appSecondary()
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.black)
    }

    private func openInAppleMaps() {
        let mapItem = MKMapItem(
            placemark: MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            )
        )
        mapItem.name = venueName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private func openInGoogleMaps() {
        if let url = URL(string: "comgooglemaps://?q=\(latitude),\(longitude)&center=\(latitude),\(longitude)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                if let webUrl = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
