import SwiftUI

// MARK: - Animated Backgrounds

struct CourseBackgroundView: View {
    let theme: CourseTheme
    
    var body: some View {
        ZStack {
            // Base Gradient
            LinearGradient(
                colors: [theme.baseColor, theme.colors.last ?? .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated Pattern
            GeometryReader { proxy in
                Group {
                    switch theme {
                    case .sunrise:
                        AnimatedSunrisePattern(colors: theme.colors, size: proxy.size)
                    case .deepOcean:
                        AnimatedOceanPattern(colors: theme.colors, size: proxy.size)
                    case .forest:
                        AnimatedForestPattern(colors: theme.colors, size: proxy.size)
                    case .nebula:
                        AnimatedNebulaPattern(colors: theme.colors, size: proxy.size)
                    }
                }
            }
        }
        // Fade in transition
        .transition(.opacity.animation(.easeInOut(duration: 1.0)))
    }
}

// MARK: - Animated Patterns

struct AnimatedSunrisePattern: View {
    let colors: [Color]
    let size: CGSize
    @State private var rotateSun = false
    @State private var breathe = false
    
    var body: some View {
        ZStack {
            // Rotating Sun Rays
            ForEach(0..<12) { i in
                Capsule()
                    .fill(colors[0].opacity(0.15))
                    .frame(width: 80, height: size.height * 0.8)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(i) * 30))
                    .rotationEffect(.degrees(rotateSun ? 360 : 0))
            }
            
            // Pulsing Core
            Circle()
                .fill(colors[1].opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .scaleEffect(breathe ? 1.1 : 0.9)
                .offset(x: size.width * 0.3, y: size.height * 0.2)
        }
        .onAppear {
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                rotateSun = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

struct AnimatedOceanPattern: View {
    let colors: [Color]
    let size: CGSize
    @State private var waveOffset = false
    
    var body: some View {
        ZStack {
            // Drifting bubbles
            ForEach(0..<10) { i in
                Circle()
                    .fill(colors[1].opacity(0.2))
                    .frame(width: CGFloat.random(in: 20...100))
                    .position(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                    .offset(y: waveOffset ? -100 : 100)
                    .animation(
                        .easeInOut(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i)),
                        value: waveOffset
                    )
            }
            
            // Ripples
            ForEach(0..<3) { i in
                Circle()
                    .stroke(colors[0].opacity(0.1), lineWidth: 40)
                    .frame(width: size.width * 1.5, height: size.width * 1.5)
                    .offset(x: waveOffset ? 20 : -20, y: waveOffset ? 20 : -20)
                    .animation(
                        .easeInOut(duration: 8).repeatForever(autoreverses: true).delay(Double(i)*2),
                        value: waveOffset
                    )
            }
        }
        .onAppear {
            waveOffset = true
        }
    }
}

struct AnimatedForestPattern: View {
    let colors: [Color]
    let size: CGSize
    @State private var wind = false
    
    var body: some View {
        ZStack {
            // Swaying "Trees"
            ForEach(0..<8) { i in
                Capsule()
                    .fill(colors[i % colors.count].opacity(0.15))
                    .frame(width: 100, height: size.height * 0.6)
                    .rotationEffect(.degrees(wind ? 5 : -5), anchor: .bottom)
                    .position(x: size.width * (CGFloat(i) / 8.0), y: size.height)
                    .animation(
                        .easeInOut(duration: Double.random(in: 4...8))
                        .repeatForever(autoreverses: true),
                        value: wind
                    )
            }
            
            // Fireflies
            ForEach(0..<15) { i in
                Circle()
                    .fill(Color.yellow.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: wind ? 30 : -30,
                        y: wind ? -30 : 30
                    )
                    .position(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i)),
                        value: wind
                    )
            }
        }
        .onAppear {
            wind = true
        }
    }
}

struct AnimatedNebulaPattern: View {
    let colors: [Color]
    let size: CGSize
    @State private var rotate = false
    @State private var twinkle = false
    
    var body: some View {
        ZStack {
            // Rotating Galaxy
            ZStack {
                ForEach(0..<6) { i in
                    Capsule()
                        .fill(colors[i % colors.count].opacity(0.1))
                        .frame(width: 40, height: size.width * 1.2)
                        .rotationEffect(.degrees(Double(i) * 30))
                }
            }
            .rotationEffect(.degrees(rotate ? 360 : 0))
            
            // Twinkling Stars
            ForEach(0..<30) { i in
                Circle()
                    .fill(Color.white.opacity(twinkle ? 0.8 : 0.2))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...size.width),
                        y: CGFloat.random(in: 0...size.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 1...3))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: twinkle
                    )
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 120).repeatForever(autoreverses: false)) {
                rotate = true
            }
            twinkle = true
        }
    }
}
import SwiftUI

struct GenerativePatternView: View {
    let theme: CourseTheme
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background Base
                LinearGradient(
                    colors: [theme.baseColor, theme.colors.last ?? .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Pattern Layer
                switch theme {
                case .sunrise:
                    SunrisePattern(colors: theme.colors)
                case .deepOcean:
                    OceanPattern(colors: theme.colors)
                case .forest:
                    ForestPattern(colors: theme.colors)
                case .nebula:
                    NebulaPattern(colors: theme.colors)
                }
            }
            .drawingGroup() // Optimize rendering for complex shapes
        }
    }
}

// MARK: - Theme Patterns

struct SunrisePattern: View {
    let colors: [Color]
    
    var body: some View {
        ZStack {
            // Sun Burst
            ForEach(0..<12) { i in
                Capsule()
                    .fill(colors[0].opacity(0.3))
                    .frame(width: 60, height: 400)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            
            // Blooming Flower
            ForEach(0..<8) { i in
                Circle()
                    .fill(colors[1].opacity(0.4))
                    .frame(width: 150, height: 150)
                    .offset(x: 40)
                    .rotationEffect(.degrees(Double(i) * 45))
                    .blendMode(.plusLighter)
            }
            
            // Core
            Circle()
                .fill(colors[0])
                .frame(width: 80, height: 80)
                .blur(radius: 20)
        }
        .offset(x: 100, y: 100)
    }
}

struct OceanPattern: View {
    let colors: [Color]
    
    var body: some View {
        ZStack {
            // Waves/Currents
            ForEach(0..<5) { i in
                Circle()
                    .stroke(colors[0].opacity(0.3), lineWidth: 40)
                    .frame(width: 300 + CGFloat(i * 100), height: 300 + CGFloat(i * 100))
                    .offset(x: -100, y: 100)
                    .blur(radius: 20)
            }
            
            // Bubbles
            ForEach(0..<15) { i in
                Circle()
                    .fill(colors[1].opacity(0.6))
                    .frame(width: CGFloat.random(in: 10...30))
                    .position(
                        x: CGFloat.random(in: 50...300),
                        y: CGFloat.random(in: 50...400)
                    )
                    .blur(radius: 2)
            }
            
            // Abstract Jellyfish/Coral
            ForEach(0..<3) { i in
                Circle()
                    .fill(colors[2].opacity(0.4))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle().stroke(colors[1], lineWidth: 2)
                    )
                    .offset(
                        x: CGFloat(i * 80 - 100),
                        y: CGFloat(i * -50)
                    )
                    .blur(radius: 10)
            }
        }
    }
}

struct ForestPattern: View {
    let colors: [Color]
    
    var body: some View {
        ZStack {
            // Abstract Ferns/Leaves
            ForEach(0..<15) { i in
                Capsule()
                    .fill(colors[i % colors.count].opacity(0.4))
                    .frame(width: 40, height: 200)
                    .overlay(
                        Capsule().stroke(colors[0].opacity(0.5), lineWidth: 1)
                    )
                    .rotationEffect(.degrees(Double.random(in: -45...45)))
                    .offset(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -100...200)
                    )
            }
            
            // Fireflies
            ForEach(0..<10) { _ in
                Circle()
                    .fill(Color.yellow.opacity(0.8))
                    .frame(width: 4, height: 4)
                    .shadow(color: .yellow, radius: 4)
                    .position(
                        x: CGFloat.random(in: 0...300),
                        y: CGFloat.random(in: 0...400)
                    )
            }
        }
    }
}

struct NebulaPattern: View {
    let colors: [Color]
    
    var body: some View {
        ZStack {
            // Spiral Galaxy
            ForEach(0..<20) { i in
                Capsule()
                    .fill(colors[i % colors.count].opacity(0.3))
                    .frame(width: 10, height: 200)
                    .offset(y: -100)
                    .rotationEffect(.degrees(Double(i) * 18))
                    .scaleEffect(x: 1, y: 1 - CGFloat(i)/40)
                    .blendMode(.plusLighter)
            }
            .rotationEffect(.degrees(45))
            
            // Stars
            StarsView()
            
            // Cosmic Dust
            Circle()
                .fill(colors[0].opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: -50, y: -50)
        }
    }
}

struct StarsView: View {
    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<40) { _ in
                Circle()
                    .fill(Color.white)
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...proxy.size.width),
                        y: CGFloat.random(in: 0...proxy.size.height)
                    )
                    .opacity(Double.random(in: 0.2...0.9))
            }
        }
    }
}
