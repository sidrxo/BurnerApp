import SwiftUI
import CoreLocation

struct HelloWorldModal: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    // ✅ Use the shared location manager from AppState instead of creating a new one
    
    @State private var showingManualEntry = false
    @State private var cityInput = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator (visual cue)
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Text("Set Your Location")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 20)

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            VStack(spacing: 0) {
                // Current Location Button
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack(spacing: 12) {
                        if isProcessing && !showingManualEntry {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        }
                        Text("Current Location")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.05))
                }
                .disabled(isProcessing)

                Divider()
                    .background(Color.gray.opacity(0.2))
                    .padding(.leading, 48)

                // Manual Entry Button
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                        Text("Search for a City")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color.white.opacity(0.05))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(Color.black)
        .presentationDetents([.height(180)])
        .presentationDragIndicator(.hidden)
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
            case .success(let location):
                print("📍 HelloWorldModal: Location set successfully: \(location.name)")
                dismiss()
            case .failure(let error):
                print("📍 HelloWorldModal: Location error: \(error.localizedDescription)")
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
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter City Name")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    TextField("e.g., London, New York", text: $cityInput)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .focused($isFocused)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }
                
                Button(action: {
                    geocodeCity()
                }) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    } else {
                        Text("Save Location")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(cityInput.isEmpty ? Color.gray : Color.white)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .padding(.horizontal, 20)
                .disabled(cityInput.isEmpty || isProcessing)
                
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Enter City")
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
        
        print("📍 ManualCityEntryView: Geocoding city: \(cityInput)")
        
        locationManager.geocodeCity(cityInput) { result in
            isProcessing = false
            
            switch result {
            case .success(let location):
                print("📍 ManualCityEntryView: City geocoded successfully: \(location.name)")
                onDismiss()
            case .failure(let error):
                print("📍 ManualCityEntryView: Geocoding error: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    Text("Background")
        .sheet(isPresented: .constant(true)) {
            HelloWorldModal()
                .environmentObject(AppState())
        }
}
