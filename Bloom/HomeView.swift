import SwiftUI

// MARK: - Extensions & Helpers (Inlined for reliability)

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

// MARK: - Components
struct CourseCard: View {
    let course: Course
    
    var body: some View {
        LabeledCardView(
            title: course.title,
            subtitle: course.subtitle,
            mode: .fullBleed
        ) {
            // Static Generative Art Pattern for Thumbnail
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

#Preview {
    HomeView(onSelectCourse: { _ in }, onCalibrate: {})
        .preferredColorScheme(.dark)
}
