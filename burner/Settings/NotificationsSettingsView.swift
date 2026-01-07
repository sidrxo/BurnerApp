import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    // AppStorage for persistence
    @AppStorage("notifications_newEvents") private var newEventsEnabled = true
    @AppStorage("notifications_savedEvents") private var savedEventsEnabled = true
    @AppStorage("notifications_recommendations") private var recommendationsEnabled = true
    @AppStorage("notifications_ticketReminders") private var ticketRemindersEnabled = true
    
    // MARK: - Custom Alert State
    
    // Struct to hold the custom alert's data
    struct AlertData {
        let title: String
        let description: String
        let primaryAction: () -> Void
        let primaryActionTitle: String
    }
    
    @State private var customAlertData: AlertData? = nil

    var body: some View {
        ZStack {
            // 1. Base View Content
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Assuming HeaderSection is a custom view defined elsewhere
                HeaderSection(title: "Notifications")

                ScrollView {
                    VStack(spacing: 0) {
                        MenuSection(title: "NOTIFICATION TYPES") {
                            // New Events Toggle
                            ToggleRow(
                                title: "New Events",
                                subtitle: "Get notified when new events are posted",
                                isOn: $newEventsEnabled
                            )
                            .onChange(of: newEventsEnabled) {
                                // Updated onChange syntax (no parameters)
                                if newEventsEnabled {
                                    handleToggleChange(for: $newEventsEnabled)
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 16)

                            // Saved Events Toggle
                            ToggleRow(
                                title: "Saved Events",
                                subtitle: "Updates on events you've bookmarked",
                                isOn: $savedEventsEnabled
                            )
                            .onChange(of: savedEventsEnabled) {
                                // Updated onChange syntax (no parameters)
                                if savedEventsEnabled {
                                    handleToggleChange(for: $savedEventsEnabled)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 16)

                            // Recommendations Toggle
                            ToggleRow(
                                title: "Recommendations",
                                subtitle: "Personalized event suggestions",
                                isOn: $recommendationsEnabled
                            )
                            .onChange(of: recommendationsEnabled) {
                                // Updated onChange syntax (no parameters)
                                if recommendationsEnabled {
                                    handleToggleChange(for: $recommendationsEnabled)
                                }
                            }

                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 16)

                            // Ticket Reminders Toggle
                            ToggleRow(
                                title: "Ticket Reminders",
                                subtitle: "Reminders before events you have tickets for",
                                isOn: $ticketRemindersEnabled
                            )
                            .onChange(of: ticketRemindersEnabled) {
                                // Updated onChange syntax (no parameters)
                                if ticketRemindersEnabled {
                                    handleToggleChange(for: $ticketRemindersEnabled)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            
            // 2. Custom Alert Overlay
            if let alertData = customAlertData {
                CustomAlertView(
                    title: alertData.title,
                    description: alertData.description,
                    cancelAction: {
                        // Dismiss the alert
                        customAlertData = nil
                    },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        // Dismiss the alert and execute the action
                        customAlertData = nil
                        alertData.primaryAction()
                    },
                    primaryActionTitle: alertData.primaryActionTitle,
                    primaryActionColor: .white
                )
                .transition(.opacity)
            }
        }
        .animation(.default, value: customAlertData != nil)
    }

    // MARK: - Notification Handling

    private func handleToggleChange(for toggleBinding: Binding<Bool>) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    print("Notifications are authorized.")
                
                case .denied:
                    // Permission was previously denied. Revert the toggle and show Custom Alert.
                    toggleBinding.wrappedValue = false
                    showPermissionDeniedAlert()
                    print("Notifications denied. Showing custom alert.")
                
                case .notDetermined:
                    // First time asking for permission.
                    requestNotificationAuthorization(for: toggleBinding)
                    
                default:
                    print("Unhandled notification status: \(settings.authorizationStatus.rawValue)")
                }
            }
        }
    }
    
    private func requestNotificationAuthorization(for toggleBinding: Binding<Bool>) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification authorization granted.")
                } else {
                    // User denied the request. Revert the toggle state.
                    toggleBinding.wrappedValue = false
                    print("Notification authorization denied in initial request.")
                }
            }
        }
    }
    
    // Function to set the CustomAlertView data
    private func showPermissionDeniedAlert() {
        customAlertData = AlertData(
            title: "Notifications Required",
            description: "To receive this type of notification, please enable app notifications in your iPhone Settings.",
            primaryAction: {
                // Action: Open iOS Settings
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl)
                }
            },
            primaryActionTitle: "Enable"
        )
    }
}

// MARK: - Reusable Toggle Row View
fileprivate struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .appBody()
                    .foregroundColor(.white)
                Text(subtitle)
                    .appSecondary()
                    .foregroundColor(.gray)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .gray))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
