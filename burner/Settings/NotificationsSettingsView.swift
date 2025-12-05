import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("notifications_newEvents") private var newEventsEnabled = true
    @AppStorage("notifications_savedEvents") private var savedEventsEnabled = true
    @AppStorage("notifications_recommendations") private var recommendationsEnabled = true
    @AppStorage("notifications_ticketReminders") private var ticketRemindersEnabled = true

    @State private var notificationsAuthorized = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                HeaderSection(title: "Notifications")

                ScrollView {
                    VStack(spacing: 0) {
                        if !notificationsAuthorized {
                            // Show message if notifications are not authorized
                            VStack(spacing: 16) {
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)

                                Text("Notifications Disabled")
                                    .appBody()
                                    .foregroundColor(.white)

                                Text("Enable notifications in Settings to receive updates about events.")
                                    .appSecondary()
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)

                                Button(action: {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }) {
                                    Text("OPEN SETTINGS")
                                        .appBody()
                                        .foregroundColor(.black)
                                        .frame(maxWidth: 200)
                                        .padding(.vertical, 12)
                                        .background(Color.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 8)
                            }
                            .padding(.bottom, 40)
                        } else {
                            // Show notification toggles
                            MenuSection(title: "NOTIFICATION TYPES") {
                                // New Events
                                Toggle(isOn: $newEventsEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("New Events")
                                            .appBody()
                                            .foregroundColor(.white)
                                        Text("Get notified when new events are posted")
                                            .appSecondary()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .cyan)) // TINT CHANGED TO CYAN
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 16)

                                // Saved Events
                                Toggle(isOn: $savedEventsEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Saved Events")
                                            .appBody()
                                            .foregroundColor(.white)
                                        Text("Updates on events you've bookmarked")
                                            .appSecondary()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .cyan)) // TINT CHANGED TO CYAN
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 16)

                                // Recommendations
                                Toggle(isOn: $recommendationsEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Recommendations")
                                            .appBody()
                                            .foregroundColor(.white)
                                        Text("Personalized event suggestions")
                                            .appSecondary()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .cyan)) // TINT CHANGED TO CYAN
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                                Divider()
                                    .background(Color.white.opacity(0.1))
                                    .padding(.leading, 16)

                                // Ticket Reminders
                                Toggle(isOn: $ticketRemindersEnabled) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Ticket Reminders")
                                            .appBody()
                                            .foregroundColor(.white)
                                        Text("Reminders before events you have tickets for")
                                            .appSecondary()
                                            .foregroundColor(.gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: .cyan)) // TINT CHANGED TO CYAN
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            checkNotificationAuthorization()
        }
    }

    private func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
