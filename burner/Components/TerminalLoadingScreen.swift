import SwiftUI

struct TerminalLoadingScreen: View {
    let onComplete: () -> Void
    @EnvironmentObject var appState: AppState

    @State private var displayedLines: [String] = []
    @State private var hasStartedLoading = false
    @State private var screenOpacity: Double = 1.0

    private let terminalPhrases: [String] = [
        "$ initializing system...",
        "| searching local caches...",
        "| fetching remote configuration...",
        "$ initializing burner...",
        "| validating security protocols...",
        "| compiling assets...",
        "✓ system ready",
    ]
    
    private let lineDisplayDelay: Double = 0.4
    private let lineAnimationDuration: Double = 0.2
    private let textBufferDelay: Double = 0.8
    private let fadeOutDuration: Double = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // 🌟 MODIFIED VStack ALIGNMENT & FRAME 🌟
                VStack(alignment: .leading, spacing: 6) { // Change from .center to **.leading**
                    // Displayed Lines
                    ForEach(displayedLines, id: \.self) { line in
                        Text(line)
                            .appMonospaced(size: 14)
                            .foregroundColor(.white.opacity(0.8))
                            .transition(.opacity)
                    }
                }
                // 🌟 IMPORTANT: Add .frame(maxWidth: .infinity, alignment: .leading) 🌟
                // This forces the inner VStack to take up the available width and
                // left-align its content, preventing it from resizing and shifting.
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .opacity(screenOpacity)
        .onAppear {
            startLoadingSequence()
        }
    }

    private func startLoadingSequence() {
        // ... (rest of the function is unchanged)
        guard !hasStartedLoading else { return }
        hasStartedLoading = true

        appState.loadInitialData()

        for (index, phrase) in terminalPhrases.enumerated() {
            let delay = Double(index) * lineDisplayDelay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: lineAnimationDuration)) {
                    displayedLines.append(phrase)
                }
            }
        }

        let totalLines = terminalPhrases.count
        let transitionStartDelay = Double(totalLines) * lineDisplayDelay + textBufferDelay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionStartDelay) {
            
            withAnimation(.easeOut(duration: fadeOutDuration)) {
                screenOpacity = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
                onComplete()
            }
        }
    }
}
