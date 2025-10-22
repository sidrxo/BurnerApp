import SwiftUI

struct BurnerModeLockScreen: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    private var burnerManager: BurnerModeManager {
        appState.burnerManager
    }

    var body: some View {
        ZStack {
            // Background with blue glow effect
            Color.black
                .ignoresSafeArea()

            // Blue glow overlay
            Rectangle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.15),
                            Color.blue.opacity(0.05),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 100,
                        endRadius: 500
                    )
                )
                .ignoresSafeArea()

            // Edge glow effect
            VStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 3)

                Spacer()

                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.blue.opacity(0.4)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 3)
            }
            .ignoresSafeArea()

            HStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.4),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 3)

                Spacer()

                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.blue.opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 3)
            }
            .ignoresSafeArea()

            // Content
            VStack(spacing: 40) {
                Spacer()

                // Padlock icon with glow
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 16) {
                    Text("Locked")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text("Burner Mode is active")
                        .appBody()
                        .foregroundColor(.gray)
                }

                // Exit button
                Button(action: {
                    exitBurnerMode()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .font(.appIcon)

                        Text("Exit Burner Mode")
                            .appBody()
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.white.opacity(0.9)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }

    private func exitBurnerMode() {
        burnerManager.disable()
        dismiss()
    }
}

#Preview {
    BurnerModeLockScreen()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
