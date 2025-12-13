import SwiftUI
import Vortex
import SwiftData

struct BloomView: View {
    var targetSpan: CGFloat = 200 // Default, passed from calibration
    var course: Course? = nil // Optional course object
    var onRecalibrate: () -> Void = {} // Callback to trigger recalibration
    
    @Environment(\.modelContext) private var modelContext
    
    // Game State
    enum GamePhase {
        case setup
        case playing
        case completed
    }
    
    @State private var phase: GamePhase = .setup
    @State private var totalSets: Double = 12
    
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
                if let theme = course?.theme {
                    CourseBackgroundView(theme: theme)
                        .opacity(0.2) // Heavily dimmed to ensure game elements pop
                } else {
                    Color.black.ignoresSafeArea()
                }
                
                BloomParticles()
                    .allowsHitTesting(false)
                
                switch phase {
                case .setup:
                    CourseSetupView(
                        course: course,
                        totalSets: $totalSets,
                        onStart: {
                            generateCourse(in: containerSize)
                            withAnimation {
                                phase = .playing
                            }
                        },
                        onDismiss: onRecalibrate
                    )
                    .zIndex(30)
                    
                case .playing:
                    gameplayLayer(geometry: geometry)
                    
                case .completed:
                    // Completion state with confetti
                    ZStack {
                        // Confetti Layer
                        VortexViewReader { proxy in
                            VortexView(.confetti) {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 12)
                                    .tag("circle")
                                
                                Rectangle()
                                    .fill(.white)
                                    .frame(width: 12, height: 12)
                                    .tag("square")
                            }
                            .onAppear {
                                // Add a small delay to ensure the proxy is ready and the view is fully active
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    proxy.burst()
                                }
                            }
                        }
                        .ignoresSafeArea()
                        
                        // UI Layer
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Text("Session Complete")
                                .font(.system(size: 40, weight: .bold)) // Larger, bolder title
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Text("Great job! You've completed your daily practice.")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                            
                            Button(action: {
                                onRecalibrate()
                            }) {
                                Text("Done")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .frame(width: 200, height: 56)
                                    .background(Capsule().fill(.white))
                                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            }
                            .padding(.top, 40)
                            
                            Spacer()
                        }
                    }
                    .background(Color.black.opacity(0.6)) // Slight overlay to dim background
                    .transition(.opacity)
                    .zIndex(30)
                    .zIndex(30)
                }
            }
            .onAppear {
                containerSize = geometry.size
                if let defaultSets = course?.defaultSets {
                    totalSets = Double(defaultSets)
                }
                // Don't generate course immediately, wait for setup
            }
            .onChange(of: geometry.size) { _, newSize in
                containerSize = newSize
            }
        }
    }
    
    private func gameplayLayer(geometry: GeometryProxy) -> some View {
        ZStack {
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
                Text("\(currentStepIndex + 1) / \(steps.count)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
            .allowsHitTesting(false)
        }
    }
    
    private func generateCourse(in size: CGSize) {
        // Constrain span to fit the smaller screen dimension with padding
        let maxDimension = min(size.width, size.height) - 100
        let baseSpan = min(targetSpan, maxDimension)
        let baseRadius = baseSpan / 2
        
        var newSteps: [CourseStep] = []
        let count = Int(totalSets)
        let strategy = course?.strategy ?? .chaotic // Default to chaotic for free play
        
        for i in 0..<count {
            switch strategy {
            case .gentle: // Morning Awakening
                // Start with single touches to wake up fingers
                if i < count / 3 {
                    // Single touches moving in a circle
                    let angle = (CGFloat(i) / CGFloat(count/3)) * 2 * .pi
                    newSteps.append(CourseStep(pattern: .singleTouch(radius: baseRadius * 0.8, angle: angle)))
                } else {
                    // Then gentle dual spans
                    let angle = (i % 2 == 0) ? 0 : CGFloat.pi / 2
                    let tilt = CGFloat.random(in: -0.1...0.1)
                    newSteps.append(CourseStep(pattern: .dualTouch(span: baseSpan * 0.9, angle: angle + tilt)))
                }
                
            case .rhythmic: // Deep Focus
                // Structured patterns with 4-way symmetry
                let step = i % 4
                let angle = CGFloat(step) * (.pi / 4)
                
                if i % 3 == 0 {
                    // Every 3rd step is a square to check full hand engagement
                    newSteps.append(CourseStep(pattern: .quadTouch(radius: baseRadius * 0.8, angle: angle)))
                } else {
                    // Cross patterns
                    newSteps.append(CourseStep(pattern: .dualTouch(span: baseSpan, angle: angle)))
                }
                
            case .stretch: // Hand Yoga
                // Complex multi-finger stretches
                let angle = CGFloat(i) * (.pi / 3)
                
                if i % 2 == 0 {
                    // Wide Triangle Stretch
                    newSteps.append(CourseStep(pattern: .triTouch(radius: baseRadius, angle: angle)))
                } else {
                    // Wide Dual Span
                    newSteps.append(CourseStep(pattern: .dualTouch(span: baseSpan * 1.1, angle: angle)))
                }
                
            case .chaotic: // Cosmic Flow / Free Play
                // Full random mix
                let type = Int.random(in: 0...3)
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let scale = CGFloat.random(in: 0.7...1.0)
                
                switch type {
                case 0: // Single
                    newSteps.append(CourseStep(pattern: .singleTouch(radius: baseRadius * scale, angle: angle)))
                case 1: // Dual
                    newSteps.append(CourseStep(pattern: .dualTouch(span: baseSpan * scale, angle: angle)))
                case 2: // Tri
                    newSteps.append(CourseStep(pattern: .triTouch(radius: baseRadius * scale, angle: angle)))
                default: // Quad
                    newSteps.append(CourseStep(pattern: .quadTouch(radius: baseRadius * scale, angle: angle)))
                }
            }
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
            if currentStepIndex < steps.count - 1 {
                currentStepIndex += 1
                
                // Shift flower color & appearance for next step
                withAnimation(.easeInOut(duration: 1.0)) {
                    flowerHue += .degrees(Double.random(in: 60...180))
                    
                    // Randomize idle scale (0.4 to 0.7)
                    flowerIdleScale = CGFloat.random(in: 0.4...0.7)
                    
                    // Randomize position slightly (within +/- 30 points)
                    flowerOffset = CGSize(
                        width: CGFloat.random(in: -30...30),
                        height: CGFloat.random(in: -30...30)
                    )
                }
                
                // 5. Unlock Input after a short transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isProcessingCompletion = false
                }
            } else {
                // Course Complete
                let log = PracticeLog(
                    courseTitle: course?.title ?? "Free Play",
                    setsCompleted: Int(totalSets)
                )
                modelContext.insert(log)
                
                withAnimation {
                    phase = .completed
                }
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

struct CourseSetupView: View {
    let course: Course?
    @Binding var totalSets: Double
    var onStart: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding()
                        .background(Circle().fill(.ultraThinMaterial))
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Text(course?.title ?? "Free Play")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                Text(course?.subtitle ?? "Relax and explore")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("DURATION")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.5))
                
                HStack {
                    Text("\(Int(totalSets)) Sets")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Spacer()
                }
                
                Slider(value: $totalSets, in: 5...30, step: 1)
                    .tint(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)
            
            Button(action: onStart) {
                Text("Begin Practice")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    BloomView()
        .preferredColorScheme(.dark)
}
