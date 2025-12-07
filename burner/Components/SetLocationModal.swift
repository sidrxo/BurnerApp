import SwiftUI
import CoreLocation

struct ModalLocationSecondaryButtonStyle: ButtonStyle {
    var backgroundColor: Color = .white
    var foregroundColor: Color = .black
    var borderColor: Color? = nil
    var maxWidth: CGFloat? = .infinity

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .appButton()
            .foregroundColor(foregroundColor)
            .frame(maxWidth: maxWidth)
            .frame(height: 50)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        Capsule().stroke(borderColor, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}



struct SetLocationModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
                .frame(height: 30)

            VStack(spacing: 16) {
                // 1. Use Current Location Button (White background, black text)
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack(spacing: 12) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "location.fill")
                                .appMonospaced(size: 16)
                        }
                        Text(isProcessing ? "LOCATING..." : "USE CURRENT LOCATION")
                            .appButton()
                    }
                }
                .buttonStyle(ModalLocationSecondaryButtonStyle(
                    backgroundColor: .white,
                    foregroundColor: .black,
                    maxWidth: .infinity
                ))
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.5 : 1.0)

                // 2. Search for a City Button (Black background, white text, white border)
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .appMonospaced(size: 16)
                        Text("SEARCH FOR A CITY")
                            .appButton()
                    }
                }
                .buttonStyle(ModalLocationSecondaryButtonStyle(
                    backgroundColor: .black,
                    foregroundColor: .white,
                    borderColor: .white.opacity(0.3),
                    maxWidth: .infinity
                ))
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
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ENTER CITY NAME")
                        .appButton()
                        .foregroundColor(.white.opacity(0.7))
                        .textCase(.uppercase)

                    TextField("e.g., London, New York", text: $cityInput)
                        .appButton()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                if let error = errorMessage {
                    Text(error)
                        .appMonospaced(size: 14)
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
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
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CANCEL") {
                        onDismiss()
                    }
                    .appButton()
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
