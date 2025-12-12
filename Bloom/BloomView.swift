import SwiftUI

// MARK: - Game Container
struct BloomView: View {
    var targetSpan: CGFloat = 200 // Default, passed from calibration
    
    @State private var isBlooming = false
    @State private var userTouches: [TouchPoint] = []
    @State private var matchProgress: CGFloat = 0.0
    
    private let tolerance: CGFloat = 40.0 
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                BloomParticles()
                    .allowsHitTesting(false)
                
               FlowerView(isBlooming: isBlooming)
                    .scaleEffect(isBlooming ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isBlooming)
                
                ZStack {
                    // Safe span calculation for display
                    let maxAllowedSpan = geometry.size.width - 100
                    let actualSpan = min(targetSpan, maxAllowedSpan)
                    
                    // Left Target (Thumb?)
                    TargetRing(isMatched: isLeftMatched)
                        .offset(x: -actualSpan / 2)
                    
                    // Right Target (Pinky?)
                    TargetRing(isMatched: isRightMatched)
                        .offset(x: actualSpan / 2)
                }
                
                TouchInputView { touches in
                    self.userTouches = touches
                    checkGameState(in: geometry.size)
                }
                
            }
        }
    }
    
    private func checkGameState(in size: CGSize) {
        // We need at least 2 touches
        guard userTouches.count >= 2 else {
            withAnimation { isBlooming = false }
            return
        }
        
        // Simple logic: Do ANY 2 touches fall within the target zones?
        // We convert touches to view-relative coordinates in TouchInputView.
        // But wait, TouchInputView returns coordinates relative to itself (Fullscreen).
        // Our targets are offset from center (0,0) in a ZStack.
        // We need to normalize coordinates.
        
        // Screen center
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Clamp span to fit screen width with padding
        let maxAllowedSpan = size.width - 100 // 50pt padding on each side
        let actualSpan = min(targetSpan, maxAllowedSpan)
        
        // Target positions in screen space
        let leftTarget = CGPoint(x: center.x - actualSpan/2, y: center.y)
        let rightTarget = CGPoint(x: center.x + actualSpan/2, y: center.y)
        
        var leftHit = false
        var rightHit = false
        
        for touch in userTouches {
            if distance(touch.location, leftTarget) < tolerance { leftHit = true }
            if distance(touch.location, rightTarget) < tolerance { rightHit = true }
        }
        
        let success = leftHit && rightHit
        withAnimation(.easeInOut(duration: 0.5)) {
            isBlooming = success
        }
    }
    
    private var isLeftMatched: Bool {
        return isBlooming
    }
    
    private var isRightMatched: Bool {
        return isBlooming
    }
    
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
