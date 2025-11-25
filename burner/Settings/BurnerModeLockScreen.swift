import SwiftUI
import Combine
import AVKit
import AVFoundation

struct BurnerModeLockScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var currentTime = Date()
    @State private var showExitConfirmation = false
    @State private var timerCountdown: Int = 600
    @State private var timerIsActive = false
    @State private var lockScreenOpacity: Double = 0
    @State private var eventEndTime: Date = Date()
    @State private var isExiting = false // Prevent race condition in exit
    @State private var showNFCScanner = false
    @State private var nfcScanMessage = ""

    // Terminal state
    @State private var showTerminal: Bool = true
    @State private var terminalOpacity: Double = 0

    // Check if terminal has already been shown for this burner mode session
    private var hasShownTerminalThisSession: Bool {
        UserDefaults.standard.bool(forKey: "burnerModeTerminalShown")
    }

    private var burnerManager: BurnerModeManager { appState.burnerManager }
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timeUntilEventEnd: TimeInterval { max(0, eventEndTime.timeIntervalSince(currentTime)) }

    private var formattedCountdown: String {
        let hours = Int(timeUntilEventEnd) / 3600
        let minutes = Int(timeUntilEventEnd) / 60 % 60
        let seconds = Int(timeUntilEventEnd) % 60
        return hours > 0
        ? String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        : String(format: "%02d:%02d", minutes, seconds)
    }

    private var formattedTimerCountdown: String {
        let minutes = timerCountdown / 60
        let seconds = timerCountdown % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ZStack {
            // Base black screen so we can truly "fade to black"
            Color.black.ignoresSafeArea()
            
            // LOCK SCREEN LAYER (behind terminal initially)
            lockScreenLayer
                .opacity(lockScreenOpacity)
                .animation(.easeInOut(duration: 1.0), value: lockScreenOpacity)
                .zIndex(1)

            // TERMINAL LAYER (shown first, then fades out)
            if showTerminal {
                TerminalLoadingView(onComplete: handleTerminalComplete)
                    .opacity(terminalOpacity)
                    .zIndex(2)
            }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .onReceive(timer) { input in
            guard !isExiting else { return }

            currentTime = input

            // Auto-end burner mode when event end time is reached
            if currentTime >= eventEndTime && eventEndTime != Date() {
                exitBurnerMode()
                return
            }

            if timerIsActive {
                if timerCountdown > 0 {
                    timerCountdown -= 1
                } else {
                    timerIsActive = false
                    exitBurnerMode()
                }
            }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            setupEventEndTime()

            // Check if terminal has already been shown this session
            if hasShownTerminalThisSession {
                // Skip terminal and go straight to lock screen
                showTerminal = false
                lockScreenOpacity = 1.0
            } else {
                // Fade in terminal immediately
                withAnimation(.easeIn(duration: 0.8)) {
                    terminalOpacity = 1.0
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            timer.upstream.connect().cancel()
        }
    }

    // MARK: - Lock Screen Layer
    private var lockScreenLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.gray.opacity(0.3), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { exitBurnerModeImmediately() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }

                Spacer().frame(maxHeight: 150)

                VStack(spacing: 0) {
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
                    .padding(.bottom, 40)

                    VStack(spacing: 8) {
                        Text("TIME UNTIL EVENT ENDS")
                            .appCaption().fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6)).tracking(1)

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

                    if timerIsActive {
                        VStack(spacing: 8) {
                            Text("UNLOCKING IN")
                                .appCaption().fontWeight(.semibold)
                                .foregroundColor(.red.opacity(0.8)).tracking(1)

                            Text(formattedTimerCountdown)
                                .appFont(size: 32, weight: .bold)
                                .foregroundColor(.red)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 24)
                    }

                    if !timerIsActive {
                        Button(action: { showExitConfirmation = true }) {
                            Text("Need your phone?\nTap here to go back.")
                                .appCaption().fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 22)
                                .padding(.horizontal, 20)
                                .tracking(1)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.opacity)
                        .padding(.top, 24)
                        
                        // NFC Unlock Button (if enabled)
                        if burnerManager.nfcUnlockEnabled && burnerManager.nfcManager.isNFCAvailable() {
                            Button(action: { startNFCUnlock() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "wave.3.right")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Unlock with NFC Tag")
                                        .appCaption().fontWeight(.semibold)
                                }
                                .foregroundColor(.teal)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.teal.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.teal.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .transition(.opacity)
                            .padding(.top, 12)
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            if showExitConfirmation {
                CustomAlertView(
                    title: "Exit BURNER?",
                    description: "Are you sure? A 10-minute timer will start before your phone unlocks.",
                    cancelAction: {
                        withAnimation { showExitConfirmation = false }
                    },
                    cancelActionTitle: "Cancel",
                    primaryAction: {
                        withAnimation {
                            showExitConfirmation = false
                            startExitTimer()
                        }
                    },
                    primaryActionTitle: "Start Timer",
                    customContent: EmptyView()
                )
                .transition(.opacity)
            }
            
            // NFC Scanner Overlay
            if showNFCScanner {
                NFCScannerOverlay(
                    message: nfcScanMessage,
                    onCancel: {
                        burnerManager.nfcManager.stopScanning()
                        showNFCScanner = false
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    // MARK: - Terminal Completion / Transitions
    private func handleTerminalComplete() {
        // Mark terminal as shown for this session
        UserDefaults.standard.set(true, forKey: "burnerModeTerminalShown")

        // 1. Fade terminal to black
        withAnimation(.easeInOut(duration: 0.6)) {
            terminalOpacity = 0.0
        }

        // 2. After terminal fade finishes, fade in lockscreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.8)) {
                lockScreenOpacity = 1.0
            }

            // 3. Remove terminal after lockscreen fade-in is done
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showTerminal = false
            }
        }
    }

    // MARK: - Helper Functions
    private func setupEventEndTime() {
        // SIMPLE: Just retrieve the pre-determined end time that was set when burner mode was activated
        if let stored = UserDefaults.standard.object(forKey: "burnerModeEventEndTime") as? Date {
            eventEndTime = stored
        } else {
            // Fallback - this should only happen if something went wrong during activation
            eventEndTime = Date().addingTimeInterval(4 * 3600)
        }
    }

    private func startExitTimer() {
        timerIsActive = true
        timerCountdown = 600
    }

    private func exitBurnerModeImmediately() {
        exitBurnerMode()
    }

    private func exitBurnerMode() {
        // Prevent multiple concurrent exit calls
        guard !isExiting else { return }
        isExiting = true

        UserDefaults.standard.removeObject(forKey: "burnerModeEventEndTime")
        UserDefaults.standard.removeObject(forKey: "burnerModeTerminalShown")
        withAnimation(.easeOut(duration: 0.3)) { lockScreenOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            burnerManager.disable()
            appState.showingBurnerLockScreen = false
        }
    }
    
    // MARK: - NFC Unlock
    private func startNFCUnlock() {
        showNFCScanner = true
        nfcScanMessage = "Hold your phone near the unlock tag"
        
        burnerManager.nfcManager.startReadingForUnlock {
            // Success - unlock burner mode
            DispatchQueue.main.async {
                showNFCScanner = false
                exitBurnerMode()
            }
        }
    }
}

// MARK: - Terminal Loading View
struct TerminalLoadingView: View {
    @State private var messages: [String] = []
    
    let allMessages = [
        "> CONNECTING TO SERVER...",
        "> AUTHENTICATING USER...",
        "> LOADING EVENTS DATABASE...",
        "> INITIALIZING BURNER PHONE...",
        "> PREPARING INTERFACE...",
        "> READY"
    ]
    
    var onComplete: (() -> Void)? = nil
    var stepDelay: Double = 0.5
    var finalHold: Double = 0.6
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(messages, id: \.self) { message in
                    HStack(spacing: 4) {
                        Text(message)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        if message == messages.last && message != allMessages.last {
                            BlinkingCursor()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
        .onAppear {
            displayMessages()
        }
    }
    
    private func displayMessages() {
        for (index, message) in allMessages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * stepDelay) {
                withAnimation(.easeIn(duration: 0.2)) {
                    messages.append(message)
                }
                
                // Trigger completion after final message
                if index == allMessages.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + finalHold) {
                        onComplete?()
                    }
                }
            }
        }
    }
}

// MARK: - Blinking Cursor
struct BlinkingCursor: View {
    @State private var isVisible = true
    
    var body: some View {
        Text("_")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.teal)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isVisible.toggle()
                }
            }
    }
}

// MARK: - NFC Scanner Overlay
struct NFCScannerOverlay: View {
    let message: String
    let onCancel: () -> Void
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // NFC Icon with pulse animation
                ZStack {
                    Circle()
                        .fill(Color.teal.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.teal)
                }
                .onAppear {
                    pulseScale = 1.2
                }
                
                VStack(spacing: 12) {
                    Text("NFC UNLOCK")
                        .appFont(size: 24, weight: .bold)
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text(message)
                        .appBody()
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: onCancel) {
                    Text("Cancel")
                        .appBody()
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
    }
}
