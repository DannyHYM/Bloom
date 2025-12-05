import SwiftUI

struct BloomView: View {
    @State private var isBlooming = false
    @State private var breathingPhase = 0.0
    
    // Palette
    let mainColor = Color.accentColor // Uses the system/asset accent
    let secondaryColor = Color.purple
    let tertiaryColor = Color.teal
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color.black.ignoresSafeArea()
            
            // MARK: - Ambient Glow
            // A subtle background pulse that breathes independently
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            mainColor.opacity(0.2),
                            secondaryColor.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 300
                    )
                )
                .scaleEffect(isBlooming ? 1.2 : 0.8)
                .opacity(isBlooming ? 0.6 : 0.3)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: isBlooming)
            
            // MARK: - Flower Composition
            ZStack {
                // Layer 1: Outer/Base petals (Larger, darker, slower)
                FlowerLayer(
                    petalCount: 12,
                    radius: isBlooming ? 120 : 40,
                    color: secondaryColor,
                    scale: isBlooming ? 1.2 : 0.8,
                    rotationSpeed: 10
                )
                .opacity(0.5)
                .rotationEffect(.degrees(isBlooming ? 30 : -30))
                
                // Layer 2: Mid petals (Vibrant, main definition)
                FlowerLayer(
                    petalCount: 8,
                    radius: isBlooming ? 90 : 30,
                    color: mainColor,
                    scale: isBlooming ? 1.0 : 0.6,
                    rotationSpeed: -15
                )
                .blendMode(.plusLighter) // Additive blend for "glow"
                .rotationEffect(.degrees(isBlooming ? -60 : 0))
                
                // Layer 3: Inner Core (Brightest, fastest)
                FlowerLayer(
                    petalCount: 6,
                    radius: isBlooming ? 50 : 15,
                    color: tertiaryColor,
                    scale: isBlooming ? 0.8 : 0.4,
                    rotationSpeed: 20
                )
                .blendMode(.plusLighter)
                .rotationEffect(.degrees(isBlooming ? 90 : 0))
                
                // Center "Pistil" glow
                Circle()
                    .fill(Color.white.opacity(isBlooming ? 0.8 : 0.4))
                    .frame(width: 20, height: 20)
                    .blur(radius: 10)
                    .scaleEffect(isBlooming ? 1.5 : 1.0)
            }
            .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: isBlooming)
        }
        .onAppear {
            isBlooming = true
        }
    }
}

// MARK: - Subviews

struct FlowerLayer: View {
    let petalCount: Int
    let radius: CGFloat
    let color: Color
    let scale: CGFloat
    let rotationSpeed: Double // Just a seed for animation variance
    
    var body: some View {
        ZStack {
            ForEach(0..<petalCount, id: \.self) { index in
                PetalShape()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.8), color.opacity(0.1)],
                            startPoint: .bottom, // Base of petal
                            endPoint: .top       // Tip of petal
                        )
                    )
                    .frame(width: 80, height: 120) // Base size of a petal
                    .scaleEffect(x: scale, y: scale, anchor: .bottom) // Scale from center
                    // 1. Offset to radius (Move OUTWARD)
                    .offset(y: -radius)
                    // 2. Rotate to position in circle
                    .rotationEffect(.degrees(Double(index) / Double(petalCount) * 360))
            }
        }
    }
}

// MARK: - Shapes

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Drawing a teardrop/petal shape
        // Start at bottom center (the anchor point for the flower center)
        path.move(to: CGPoint(x: width / 2, y: height))
        
        // Curve up to the left
        path.addCurve(
            to: CGPoint(x: width / 2, y: 0), // Top tip
            control1: CGPoint(x: 0, y: height * 0.7), // Bulge out
            control2: CGPoint(x: width * 0.2, y: height * 0.2) // Taper in
        )
        
        // Curve back down to the right
        path.addCurve(
            to: CGPoint(x: width / 2, y: height), // Back to bottom center
            control1: CGPoint(x: width * 0.8, y: height * 0.2), // Taper out
            control2: CGPoint(x: width, y: height * 0.7) // Bulge in
        )
        
        return path
    }
}

#Preview {
    BloomView()
        .preferredColorScheme(.dark)
}