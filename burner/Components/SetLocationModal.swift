import SwiftUI
import CoreLocation

// MARK: - LOCAL Modal Button Style (No Stroke, Lighter Fill, 50pt Height)

/// Dedicated style for the SetLocationModal: Translucent background, NO stroke/outline,
/// fixed 50pt height without relying on global padding settings.
struct ModalLocationSecondaryButtonStyle: ButtonStyle {
    // Background opacity changed from 0.05 to 0.1 for a slightly lighter look
    var backgroundColor: Color = Color.white.opacity(0.05)
    var foregroundColor: Color = .white
    var maxWidth: CGFloat? = .infinity
    
    // NOTE: This style achieves 50pt height because it doesn't add vertical padding
    // and explicitly sets the container height.

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foregroundColor)
            .frame(maxWidth: maxWidth)
            .frame(height: 50) // Explicitly set the container height to 50pt
            .background(backgroundColor)
            .clipShape(Capsule())
            // NO STROKE OVERLAY
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}


// MARK: - SetLocationModal View

struct SetLocationModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            
            // Removed "Set Your Location" title for cleaner UX.
            Spacer()
                .frame(height: 30)

            // Buttons — now 50pts tall, centered, with translucent background, NO STROKE
            VStack(spacing: 16) {
                // 1. Use Current Location Button
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack(spacing: 12) { // Centering icon and text
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            // Icon added back
                            Image(systemName: "location.fill")
                                .appBody()
                        }
                        Text(isProcessing ? "LOCATING..." : "USE CURRENT LOCATION")
                            .appBody()
                    }
                }
                .buttonStyle(ModalLocationSecondaryButtonStyle(maxWidth: .infinity))
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.5 : 1.0)
                
                // 2. Search for a City Button
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 12) { // Centering icon and text
                        // Icon added back
                        Image(systemName: "magnifyingglass")
                            .appBody()
                        Text("SEARCH FOR A CITY")
                            .appBody()
                    }
                }
                .buttonStyle(ModalLocationSecondaryButtonStyle(maxWidth: .infinity))
            }
            .padding(.horizontal, 24)

            // Optional error (kept minimal; below buttons)
            if let error = errorMessage {
                Text(error)
                    .appCaption()
                    .foregroundColor(.red)
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
        .background(Color.black)
        // Detent adjusted to a smaller height (170) to fit content tightly
        .presentationDetents([.height(170)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingManualEntry) {
            ManualCityEntryView(locationManager: appState.userLocationManager, onDismiss: {
                showingManualEntry = false
                dismiss()
            })
        }
    }

    private func requestCurrentLocation() {
        isProcessing = true
        errorMessage = nil

        appState.userLocationManager.requestCurrentLocation { result in
            isProcessing = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Manual City Entry View
struct ManualCityEntryView: View {
    @ObservedObject var locationManager: UserLocationManager
    let onDismiss: () -> Void
    
    @State private var cityInput = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter City Name")
                        .appBody()
                        .foregroundColor(.white)
                    
                    TextField("e.g., London, New York", text: $cityInput)
                        .appBody()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isFocused)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if let error = errorMessage {
                    Text(error)
                        .appCaption()
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Updated Save Location Button using BurnerButton (Primary Style)
                BurnerButton(
                    isProcessing ? "SAVING..." : "SAVE LOCATION",
                    style: .primary,
                    maxWidth: .infinity
                ) {
                    geocodeCity()
                }
                .disabled(cityInput.isEmpty || isProcessing)
                .opacity((cityInput.isEmpty || isProcessing) ? 0.5 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
    
    private func geocodeCity() {
        isProcessing = true
        errorMessage = nil

        locationManager.geocodeCity(cityInput) { result in
            isProcessing = false

            switch result {
            case .success:
                onDismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
