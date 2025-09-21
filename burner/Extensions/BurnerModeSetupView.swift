import SwiftUI
import FamilyControls

struct BurnerModeSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var burnerModeManager: BurnerModeManager
    @State private var selection = FamilyActivitySelection()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Choose Apps to Block")
                        .appFont(size: 24, weight: .bold)
                        .foregroundColor(.white)
                    
                    Text("Select apps you want to block during Burner Mode. Phone, Messages, and Maps will always remain accessible.")
                        .appFont(size: 16)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Info about current limitations
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            Text("Setup Mode")
                                .appFont(size: 14, weight: .semibold)
                                .foregroundColor(.orange)
                        }
                        Text("Currently in setup mode. App blocking will activate once additional permissions are approved.")
                            .appFont(size: 12)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }
                
                FamilyActivityPicker(selection: $selection)
                    .padding()
                
                Spacer()
                
                Button("Save Configuration") {
                    burnerModeManager.updateBlockedApps(selection)
                    presentationMode.wrappedValue.dismiss()
                }
                .appFont(size: 17, weight: .semibold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color.black)
            .navigationTitle("Burner Mode Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.orange)
            )
        }
        .onAppear {
            selection = burnerModeManager.blockedAppsSelection
        }
    }
}
