import SwiftUI

// MARK: - Extensions & Helpers (Inlined for reliability)

extension Color {
    init(hex: Int, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct LabeledCardView<Content: View, Background: View>: View {
    enum Mode {
        case fullBleed
        case horizontalBleed
        case topLabel
    }

    let title: String
    let subtitle: String
    let mode: Mode
    let content: () -> Content
    let background: () -> Background

    init(
        title: String,
        subtitle: String,
        mode: Mode = .fullBleed,
        @ViewBuilder content: @escaping () -> Content
    ) where Background == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.mode = mode
        self.content = content
        self.background = { EmptyView() }
    }

    init(
        title: String,
        subtitle: String,
        mode: Mode = .fullBleed,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder background: @escaping () -> Background
    ) {
        self.title = title
        self.subtitle = subtitle
        self.mode = mode
        self.content = content
        self.background = background
    }

    var body: some View {
        ZStack {
            if mode == .topLabel {
                background()
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 5){
                        Text(title)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                    content()
                }
            } else {
                bleeds
            }
        }
        .mask(RoundedRectangle(cornerRadius: 20))
    }
    
    var bleeds: some View {
        Group {
            Rectangle().foregroundStyle(.background.secondary)

            if mode == .fullBleed {
                background()
                content()
            }

            VStack(alignment: .leading, spacing: 0) {
                if mode == .horizontalBleed {
                    ZStack(alignment: .center) {
                        background()
                        content()
                    }
                } else {
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .padding(.bottom, 5)
                .background(Material.ultraThin)
            }
            .frame(maxWidth: .infinity, alignment: .bottomLeading)
        }
    }
}

// MARK: - Main Home View

struct HomeView: View {
    var onSelectCourse: (Course) -> Void
    var onCalibrate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .kerning(1)
                    
                    Text("Daily Practice")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 20)
                .padding(.horizontal, 4)
                
                // Calibration Card (Mini)
                Button(action: onCalibrate) {
                    HStack {
                        Image(systemName: "hand.raised.fingers.spread")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                        
                        VStack(alignment: .leading) {
                            Text("Calibration")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Adjust for your hand size")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                }
                
                // Course List
                LazyVStack(spacing: 24) {
                    ForEach(Course.allCourses) { course in
                        Button(action: { onSelectCourse(course) }) {
                            CourseCard(course: course)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
            .padding(16)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Data Models
struct Course: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let theme: CourseTheme
}

enum CourseTheme {
    case sunrise
    case deepOcean
    case forest
    case nebula
}

extension Course {
    static let allCourses = [
        Course(title: "Morning Awakening", subtitle: "Gentle stretches to start your day", theme: .sunrise),
        Course(title: "Deep Focus", subtitle: "Rhythmic patterns for concentration", theme: .deepOcean),
        Course(title: "Hand Yoga", subtitle: "Flexibility and dexterity training", theme: .forest),
        Course(title: "Cosmic Flow", subtitle: "Explore complex generative patterns", theme: .nebula)
    ]
}

// MARK: - Components
struct CourseCard: View {
    let course: Course
    
    var body: some View {
        LabeledCardView(
            title: course.title,
            subtitle: course.subtitle,
            mode: .fullBleed
        ) {
            // Generative Art Pattern
            GenerativePatternView(theme: course.theme)
        } background: {
            EmptyView()
        }
        .frame(height: 320)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

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

extension CourseTheme {
    var baseColor: Color {
        switch self {
        case .sunrise: return Color(hex: 0xFF8C00).opacity(0.3)
        case .deepOcean: return Color(hex: 0x001B4B)
        case .forest: return Color(hex: 0x0A2F1F)
        case .nebula: return Color(hex: 0x2A003B)
        }
    }
    
    var colors: [Color] {
        switch self {
        case .sunrise:
            return [.orange, .yellow, .red, .pink]
        case .deepOcean:
            return [.blue, .cyan, .indigo, .purple]
        case .forest:
            return [.green, .mint, .teal, .brown]
        case .nebula:
            return [.purple, .pink, .indigo, .blue]
        }
    }
}

#Preview {
    HomeView(onSelectCourse: { _ in }, onCalibrate: {})
        .preferredColorScheme(.dark)
}
