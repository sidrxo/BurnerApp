import SwiftUI

struct TerminalLoadingScreen: View {
    let onComplete: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var displayedLines: [String] = []
    @State private var hasStartedFetching = false

    // Terminal phrases for loading
    private let terminalPhrases = [
        "$ initializing burner...",
        "✓ system ready",
        "$ connecting to firebase...",
        "✓ connection established",
        "$ fetching event database...",
        "✓ events loaded",
        "$ loading images...",
        "✓ images cached",
        "$ configuring experience...",
        "✓ ready to explore"
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(displayedLines, id: \.self) { line in
                        Text(line)
                            .appMonospaced(size: 14)
                            .foregroundColor(line.hasPrefix("✓") ? .green : .white.opacity(0.8))
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
        }
        .onAppear {
            startLoadingSequence()
        }
    }

    private func startLoadingSequence() {
        guard !hasStartedFetching else { return }
        hasStartedFetching = true

        // Start fetching events in background
        appState.loadInitialData()

        // Randomly select phrases to display
        let selectedPhrases = terminalPhrases.shuffled().prefix(8)

        for (index, phrase) in selectedPhrases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                withAnimation(.easeIn(duration: 0.1)) {
                    displayedLines.append(phrase)
                }
            }
        }

        // Complete after all lines are shown
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(selectedPhrases.count) * 0.2 + 0.5) {
            onComplete()
        }
    }
}
