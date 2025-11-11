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
            Text("Set Your Location")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 20)
                .padding(.bottom, 16)
            
            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            
            VStack(spacing: 12) {
                // Current Location Button
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack {
                        if isProcessing && !showingManualEntry {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                        }
                        Text("Use Current Location")
                            .font(.system(size: 16))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing)
                
                // Manual Entry Button
                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                        Text("Manually Enter City")
                            .font(.system(size: 16))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 20)
            
            // Show current saved location if exists
            if let savedLocation = appState.userLocationManager.savedLocation {
                VStack(spacing: 8) {
                    Text("Current Location")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(savedLocation.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        print("📍 HelloWorldModal: Clear button tapped")
                        appState.userLocationManager.clearLocation()
                        dismiss()
                    }) {
                        Text("Clear Location")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 16)
            }
            
            Spacer()
        }
        .background(Color.black)
        .presentationDetents([.height(showingManualEntry ? 350 : 250)])
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
