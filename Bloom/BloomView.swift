import SwiftUI

// MARK: - Game Container
struct BloomView: View {
    var targetSpan: CGFloat = 200 // Default, passed from calibration
    var theme: CourseTheme? = nil // Optional theme to override default black
    var onRecalibrate: () -> Void = {} // Callback to trigger recalibration
    
    @State private var isBlooming = false
    @State private var userTouches: [TouchPoint] = []
    @State private var isProcessingCompletion = false // Lock to prevent double-triggering
    @State private var flowerHue: Angle = .zero
    @State private var containerSize: CGSize = .zero
    
    @State private var flowerOffset: CGSize = .zero
    @State private var flowerIdleScale: CGFloat = 0.5
    
    @State private var currentStepIndex: Int = 0
    @State private var steps: [CourseStep] = []
    
    private var currentPattern: GesturePattern {
        if steps.isEmpty { return .dualTouch(span: targetSpan, angle: 0) }
        return steps[currentStepIndex].pattern
    }
    
    private let tolerance: CGFloat = 40.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                if let theme = theme {
                    CourseBackgroundView(theme: theme)
                        .opacity(0.2) // Heavily dimmed to ensure game elements pop
                } else {
                    Color.black.ignoresSafeArea()
                }
                
                BloomParticles()
                    .allowsHitTesting(false)
                
                FlowerView(isBlooming: isBlooming)
                    .scaleEffect(isBlooming ? 1.0 : flowerIdleScale) // Dynamic idle scale
                    .offset(flowerOffset) // Dynamic position
                    .hueRotation(flowerHue)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: flowerOffset)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isBlooming)
                    .animation(.easeInOut(duration: 1.0), value: flowerIdleScale)
                
                ZStack {
                    let targets = currentPattern.getTargets()
                    ForEach(0..<targets.count, id: \.self) { index in
                        let point = targets[index]
                        TargetRing(isMatched: isBlooming) // Simplified visual feedback
                            .offset(x: point.x, y: point.y)
                            .position(x: geometry.size.width/2, y: geometry.size.height/2) // Center the group
                    }
                }
                
                TouchInputView { touches in
                    self.userTouches = touches
                    checkGameState(in: geometry.size)
                }
                
                TouchParticleOverlay(touches: userTouches)
                    .allowsHitTesting(false)
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onRecalibrate) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(12)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
                .zIndex(20)
                
                // Optional: Course Progress Indicator
                VStack {
                    Spacer()
                    Text(currentPattern.name)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 20)
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                containerSize = geometry.size
                generateCourse(in: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                containerSize = newSize
            }
        }
    }
    
    private func generateCourse(in size: CGSize) {
        // Constrain span to fit the smaller screen dimension with padding
        let maxDimension = min(size.width, size.height) - 100
        let baseSpan = min(targetSpan, maxDimension)
        
        var newSteps: [CourseStep] = []
        let count = 12 // A good length for a session
        
        for i in 0..<count {
            let angle: CGFloat
            let spanFactor: CGFloat
            
            if i == 0 {
                // First step: Standard horizontal
                angle = 0
                spanFactor = 1.0
            } else {
                // Random variations
                // Full 360 degree rotation potential
                angle = CGFloat.random(in: 0...(2 * .pi))
                
                // Vary length between 70% and 110% of base
                // Ensure we don't exceed bounds even with 1.1x
                spanFactor = CGFloat.random(in: 0.7...1.1)
            }
            
            // Calculate final span, clamped to safe area
            let rawSpan = baseSpan * spanFactor
            let finalSpan = min(rawSpan, maxDimension)
            
            newSteps.append(CourseStep(pattern: .dualTouch(span: finalSpan, angle: angle)))
        }
        
        self.steps = newSteps
    }
    
    private func checkGameState(in size: CGSize) {
        // Guard: Don't check inputs if we are already handling a success
        guard !isProcessingCompletion else { return }
        
        let targets = currentPattern.getTargets()
        
        guard userTouches.count >= targets.count else {
            if isBlooming {
                withAnimation { isBlooming = false }
            }
            return
        }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        let absoluteTargets = targets.map { point -> CGPoint in
            return CGPoint(x: center.x + point.x, y: center.y + point.y)
        }
        
        let allTargetsMatched = absoluteTargets.allSatisfy { targetPoint in
            userTouches.contains { touch in
                distance(touch.location, targetPoint) < tolerance
            }
        }
        
        if allTargetsMatched {
            if !isBlooming {
                startStepCompletion()
            }
        } else {
            if isBlooming {
                withAnimation { isBlooming = false }
            }
        }
    }
    
    private func startStepCompletion() {
        isProcessingCompletion = true
        
        // 1. Bloom Feedback
        withAnimation(.easeInOut(duration: 0.5)) {
            isBlooming = true
        }
        
        // 2. Hold Duration
        let duration = steps[currentStepIndex].holdDuration
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            // 3. Reset Bloom
            withAnimation {
                isBlooming = false
            }
            
            // 4. Advance Step Immediately
            // Changing the step here ensures the user's current finger position
            // (which matched the OLD step) won't accidentally match the NEW step
            // in the next frame, unless they are extremely unlucky and the targets overlap perfectly.
            if currentStepIndex < steps.count - 1 {
                currentStepIndex += 1
            } else {
                // Loop course
                generateCourse(in: containerSize) // Regenerate for variety
                currentStepIndex = 0
            }
            
            // Shift flower color & appearance for next step
            withAnimation(.easeInOut(duration: 1.0)) {
                flowerHue += .degrees(Double.random(in: 60...180))
                
                // Randomize idle scale (0.4 to 0.7)
                flowerIdleScale = CGFloat.random(in: 0.4...0.7)
                
                // Randomize position slightly (within +/- 30 points)
                // This keeps it mostly centered but feels "alive"
                flowerOffset = CGSize(
                    width: CGFloat.random(in: -30...30),
                    height: CGFloat.random(in: -30...30)
                )
            }
            
            // 5. Unlock Input after a short transition
            // This forces a momentary pause where no matches occur, preventing "instant" chaining.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProcessingCompletion = false
            }
        }
    }
    
    // Removed old completeStep() in favor of startStepCompletion()
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
        return hypot(p1.x - p2.x, p1.y - p2.y)
    }
}

struct TargetRing: View {
    var isMatched: Bool
    
    var body: some View {
        Circle()
            .stroke(
                isMatched ? Color.accentColor : Color.white.opacity(0.3),
                style: StrokeStyle(lineWidth: isMatched ? 4 : 2, dash: isMatched ? [] : [5])
            )
            .frame(width: 60, height: 60)
            .shadow(color: isMatched ? Color.accentColor : .clear, radius: 10)
            .animation(.easeInOut, value: isMatched)
    }
}

// MARK: - Visual Component (Original BloomView)
struct FlowerView: View {
    var isBlooming: Bool // Driven by parent
    
    // Palette
    let mainColor = Color.accentColor
    let secondaryColor = Color.purple
    let tertiaryColor = Color.teal
    
    var body: some View {
        ZStack {
            // Ambient Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [mainColor.opacity(0.2), .clear],
                        center: .center,
                        startRadius: 1,
                        endRadius: 300
                    )
                )
                .scaleEffect(isBlooming ? 1.2 : 0.8)
                .opacity(isBlooming ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: isBlooming)
            
            // Flower Layers
            ZStack {
                // Layer 1
                FlowerLayer(
                    petalCount: 12,
                    radius: isBlooming ? 120 : 40,
                    color: secondaryColor,
                    scale: isBlooming ? 1.2 : 0.8,
                    rotationSpeed: 10
                )
                .opacity(0.5)
                .rotationEffect(.degrees(isBlooming ? 30 : -30))
                
                // Layer 2
                FlowerLayer(
                    petalCount: 8,
                    radius: isBlooming ? 90 : 30,
                    color: mainColor,
                    scale: isBlooming ? 1.0 : 0.6,
                    rotationSpeed: -15
                )
                .blendMode(.plusLighter)
                .rotationEffect(.degrees(isBlooming ? -60 : 0))
                
                // Layer 3
                FlowerLayer(
                    petalCount: 6,
                    radius: isBlooming ? 50 : 15,
                    color: tertiaryColor,
                    scale: isBlooming ? 0.8 : 0.4,
                    rotationSpeed: 20
                )
                .blendMode(.plusLighter)
                .rotationEffect(.degrees(isBlooming ? 90 : 0))
                
                // Pistil
                Circle()
                    .fill(Color.white.opacity(isBlooming ? 0.8 : 0.4))
                    .frame(width: 20, height: 20)
                    .blur(radius: 10)
                    .scaleEffect(isBlooming ? 1.5 : 1.0)
            }
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: isBlooming)
        }
    }
}

// MARK: - Subviews & Shapes (Unchanged)

struct FlowerLayer: View {
    let petalCount: Int
    let radius: CGFloat
    let color: Color
    let scale: CGFloat
    let rotationSpeed: Double
    
    var body: some View {
        ZStack {
            ForEach(0..<petalCount, id: \.self) { index in
                PetalShape()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.1)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 80, height: 120)
                    .scaleEffect(x: scale, y: scale, anchor: .bottom)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(index) / Double(petalCount) * 360))
            }
        }
    }
}

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: width / 2, y: 0),
            control1: CGPoint(x: 0, y: height * 0.7),
            control2: CGPoint(x: width * 0.2, y: height * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width * 0.8, y: height * 0.2),
            control2: CGPoint(x: width, y: height * 0.7)
        )
        
        return path
    }
}

#Preview {
    BloomView()
        .preferredColorScheme(.dark)
}
