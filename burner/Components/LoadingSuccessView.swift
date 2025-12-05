import SwiftUI

struct LoadingSuccessView: View {
    @Binding var isLoading: Bool
    @State private var showSuccess = false
    @State private var fillProgress: CGFloat = 0
    @State private var checkmarkProgress: CGFloat = 0
    @State private var expandingRingScale: CGFloat = 1.0
    @State private var expandingRingOpacity: Double = 0.0
    @State private var fadeOut = false
    
    let size: CGFloat
    let lineWidth: CGFloat
    let color: Color
    
    init(
        isLoading: Binding<Bool>,
        size: CGFloat = 120,
        lineWidth: CGFloat = 12,
        color: Color = .white
    ) {
        self._isLoading = isLoading
        self.size = size
        self.lineWidth = lineWidth
        self.color = color
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                // Custom loading indicator
                CustomLoadingIndicator(size: size)
            } else {
                // Success animation
                ZStack {
                    // Expanding ring effect
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: size, height: size)
                        .scaleEffect(expandingRingScale)
                        .opacity(expandingRingOpacity)
                    
                    // Circle stroke outline
                    Circle()
                        .stroke(color, lineWidth: lineWidth)
                        .frame(width: size, height: size)
                    
                    // Filled circle that scales up
                    Circle()
                        .fill(color)
                        .frame(width: size * fillProgress, height: size * fillProgress)
                    
                    // Checkmark
                    CheckmarkShape()
                        .trim(from: 0, to: checkmarkProgress)
                        .stroke(Color.black, style: StrokeStyle(lineWidth: lineWidth))
                        .frame(width: size * 0.7, height: size * 0.7)
                }
                .opacity(fadeOut ? 0 : 1)
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if !newValue && !showSuccess {
                triggerSuccessAnimation()
            }
        }
    }
    
    private func triggerSuccessAnimation() {
        showSuccess = true
        
        // Fill the circle
        withAnimation(.easeOut(duration: 0.4)) {
            fillProgress = 1.0
        }
        
        // Draw checkmark after circle fills
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                checkmarkProgress = 1.0
            }
        }
        
        // Expanding ring effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            expandingRingOpacity = 0.8
            withAnimation(.easeOut(duration: 0.6)) {
                expandingRingScale = 1.5
                expandingRingOpacity = 0.0
            }
        }
        
        // Fade out after showing checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                fadeOut = true
            }
        }
    }
}

// MARK: - Custom Loading Indicator
/// Custom white circular loading indicator
struct CustomLoadingIndicator: View {
    @State private var isAnimating = false
    let size: CGFloat

    init(size: CGFloat = 120) {
        self.size = size
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.white, lineWidth: 8)
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}


struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Starting point (left point of checkmark)
        path.move(to: CGPoint(x: width * 0.15, y: height * 0.5))
        
        // Middle point (bottom of checkmark)
        path.addLine(to: CGPoint(x: width * 0.4, y: height * 0.75))
        
        // End point (right point of checkmark)
        path.addLine(to: CGPoint(x: width * 0.85, y: height * 0.25))
        
        return path
    }
}

// MARK: - Demo View
struct LoadingSuccessDemo: View {
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 40) {
            LoadingSuccessView(
                isLoading: $isLoading,
                size: 120,
                lineWidth: 12,
                color: .white
            )
            
            Button(action: {
                isLoading.toggle()
                
                // Reset after animation completes
                if !isLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isLoading = true
                    }
                }
            }) {
                Text(isLoading ? "Complete Loading" : "Start Loading")
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

#Preview {
    LoadingSuccessDemo()
}
