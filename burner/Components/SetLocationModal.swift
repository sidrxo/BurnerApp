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
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Buttons — same layout & styling as MapsOptionsSheet
            VStack(spacing: 12) {
                Button(action: {
                    requestCurrentLocation()
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                        }
                        Text("Use Current Location")
                            .appBody()
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

                Button(action: {
                    showingManualEntry = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                        Text("Search for a City")
                            .appBody()
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
        .presentationDetents([.height(200)])              // match MapsOptionsSheet
        .presentationDragIndicator(.visible)              // match MapsOptionsSheet
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
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter City Name")
                        .appBody()
                        .foregroundColor(.white)
                    
                    TextField("e.g., London, New York", text: $cityInput)
                        .appBody()
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
                        .appCaption()
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
                        .appBody()
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
            SetLocationModal()
                .environmentObject(AppState())
        }
}
