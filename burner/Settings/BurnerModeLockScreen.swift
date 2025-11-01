import SwiftUI
import Combine

struct BurnerModeLockScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var currentTime = Date()
    @State private var showExitConfirmation = false
    @State private var opacity: Double = 0 // For fade-in animation
    
    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }
    
    // Timer to update current time every second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
                    
                    // Current time display
                    VStack(spacing: 8) {
                        Text("CURRENT TIME")
                            .appCaption()
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        Text(currentTime, style: .time)
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
                    
                    // Exit button
                    Button(action: {
                        withAnimation {
                            showExitConfirmation = true
                        }
                    }) {
                        Text("Need your phone?\nTap here to go back.")
                            .appCaption()
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .tracking(1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            // Custom alert overlay
            if showExitConfirmation {
                CustomAlertView(
                    title: "Exit Burner Mode?",
                    description: "Are you sure you want to return to the app?",
                    cancelAction: {
                        withAnimation {
                            showExitConfirmation = false
                        }
                    },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        withAnimation {
                            showExitConfirmation = false
                        }
                        exitBurnerMode()
                    },
                    primaryActionTitle: "Exit",
                    customContent: EmptyView()
                )
            }
        }
        .opacity(opacity) // Apply fade-in effect
        .statusBarHidden(true)
        .preferredColorScheme(.dark) // Force dark mode for the alert
        .onReceive(timer) { input in
            currentTime = input
        }
        .onAppear {
            // Prevent screen from dimming
            UIApplication.shared.isIdleTimerDisabled = true
            
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

    private func exitBurnerMode() {
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
