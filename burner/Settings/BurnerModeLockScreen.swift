import SwiftUI
import Combine

struct BurnerModeLockScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var currentTime = Date()
    @State private var showExitConfirmation = false
    @State private var showTimerAlert = false
    @State private var timerCountdown: Int = 600 // 10 minutes in seconds
    @State private var timerIsActive = false
    @State private var longPressProgress: Double = 0.0
    @State private var isLongPressing = false
    @State private var opacity: Double = 0 // For fade-in animation
    @State private var eventEndTime: Date = Date()

    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }

    // Timer to update current time and countdown every second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Computed property for time remaining till event end
    private var timeUntilEventEnd: TimeInterval {
        max(0, eventEndTime.timeIntervalSince(currentTime))
    }

    private var formattedCountdown: String {
        let hours = Int(timeUntilEventEnd) / 3600
        let minutes = Int(timeUntilEventEnd) / 60 % 60
        let seconds = Int(timeUntilEventEnd) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private var formattedTimerCountdown: String {
        let minutes = timerCountdown / 60
        let seconds = timerCountdown % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {

            Color.black
                .ignoresSafeArea()

            // Animated gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.gray.opacity(0.3),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Content
            VStack(spacing: 0) {
                Spacer()
                    .frame(maxHeight: 200)

                // Main content
                VStack(spacing: 40) {
                    // Main message
                    VStack(spacing: 16) {
                        Text("YOU'RE IN.")
                            .appFont(size: 42, weight: .bold)
                            .foregroundColor(.white)
                            .textCase(.uppercase)
                            .tracking(2)

                        Text("Focus on the moment.")
                            .appFont(size: 22, weight: .medium)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)

                        Text("Put your phone away and be present.")
                            .appBody()
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    // Event countdown display
                    VStack(spacing: 8) {
                        Text("TIME UNTIL EVENT ENDS")
                            .appCaption()
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)

                        Text(formattedCountdown)
                            .appFont(size: 28, weight: .medium)
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )

                    // Exit button with long press
                    ZStack {
                        // Long press progress ring
                        if isLongPressing {
                            Circle()
                                .trim(from: 0, to: longPressProgress)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: longPressProgress)
                        }

                        Button(action: {
                            // Tap action - show timer
                            startExitTimer()
                        }) {
                            Text("Need your phone?\nTap here to go back.")
                                .appCaption()
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .tracking(1)
                                .padding(20)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 10.0)
                                .onEnded { _ in
                                    // Long press completed - exit immediately
                                    isLongPressing = false
                                    longPressProgress = 0.0
                                    exitBurnerMode()
                                }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !isLongPressing {
                                        isLongPressing = true
                                        startLongPressAnimation()
                                    }
                                }
                                .onEnded { _ in
                                    isLongPressing = false
                                    longPressProgress = 0.0
                                }
                        )
                    }

                    // Hint text
                    if isLongPressing {
                        Text("Hold for 10 seconds to exit immediately")
                            .appCaption()
                            .foregroundColor(.white.opacity(0.5))
                            .transition(.opacity)
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Timer alert overlay
            if showTimerAlert {
                CustomAlertView(
                    title: "Exit Timer Active",
                    description: "Your phone will unlock in \(formattedTimerCountdown)\n\nHold the exit button for 10 seconds to unlock immediately.",
                    cancelAction: {
                        withAnimation {
                            showTimerAlert = false
                            timerIsActive = false
                            timerCountdown = 600
                        }
                    },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        // Keep timer running
                        withAnimation {
                            showTimerAlert = false
                        }
                    },
                    primaryActionTitle: "OK",
                    customContent: EmptyView()
                )
                .transition(.opacity)
            }
        }
        .opacity(opacity) // Apply fade-in effect
        .statusBarHidden(true)
        .preferredColorScheme(.dark) // Force dark mode for the alert
        .onReceive(timer) { input in
            currentTime = input

            // Handle exit timer countdown
            if timerIsActive {
                if timerCountdown > 0 {
                    timerCountdown -= 1
                } else {
                    // Timer completed - exit burner mode
                    timerIsActive = false
                    exitBurnerMode()
                }
            }
        }
        .onAppear {
            // Prevent screen from dimming
            UIApplication.shared.isIdleTimerDisabled = true

            // Set random event end time if not set
            setupEventEndTime()

            // Fade in animation
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }
        }
        .onDisappear {
            // Re-enable screen dimming
            UIApplication.shared.isIdleTimerDisabled = false
            timer.upstream.connect().cancel()
        }
    }

    private func setupEventEndTime() {
        // Check if there's a stored event end time
        if let storedEndTime = UserDefaults.standard.object(forKey: "burnerModeEventEndTime") as? Date {
            eventEndTime = storedEndTime
        } else {
            // Generate random end time between 2-4 hours from now
            let randomHours = Double.random(in: 2...4)
            eventEndTime = Date().addingTimeInterval(randomHours * 3600)
            UserDefaults.standard.set(eventEndTime, forKey: "burnerModeEventEndTime")
        }
    }

    private func startExitTimer() {
        withAnimation {
            timerIsActive = true
            timerCountdown = 600 // Reset to 10 minutes
            showTimerAlert = true
        }
    }

    private func startLongPressAnimation() {
        // Animate progress over 10 seconds
        withAnimation(.linear(duration: 10.0)) {
            longPressProgress = 1.0
        }
    }

    private func exitBurnerMode() {
        // Clear stored event end time
        UserDefaults.standard.removeObject(forKey: "burnerModeEventEndTime")

        // Fade out before dismissing
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }

        // Wait for fade out to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            burnerManager.disable()
            appState.showingBurnerLockScreen = false
        }
    }
}

#Preview {
    BurnerModeLockScreen()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
