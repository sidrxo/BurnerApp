import SwiftUI
import CoreLocation

struct SetLocationModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var showingManualEntry = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Title — match MapsOptionsSheet
            Text("Set Your Location")
                .appBody()
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top, 30)
                .padding(.bottom, 16)

            // Buttons — same layout & styling as MapsOptionsSheet
            VStack(spacing: 12) {
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack(spacing: 12) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text("Use Current Location")
                            .font(.system(size: 16, design: .monospaced))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)

                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Search for a City")
                            .font(.system(size: 16, design: .monospaced))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
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
        .presentationDetents([.height(200)])
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
                
                // Updated Save Location Button using BurnerButton
                BurnerButton(
                    isProcessing ? "SAVING..." : "SAVE LOCATION",
                    style: .primary,
                    maxWidth: nil
                ) {
                    geocodeCity()
                }
                .buttonStyle(PlainButtonStyle())
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
