import SwiftUI
import SwiftData

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
    
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showingProfileSheet = false
    
    private var currentUser: UserProfile {
        if let profile = profiles.first {
            return profile
        } else {
            return UserProfile() // Fallback
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .kerning(1)
                        
                        Text(currentUser.firstName.isEmpty ? "Daily Practice" : "Hi, \(currentUser.firstName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    // Avatar Button
                    Button(action: { showingProfileSheet = true }) {
                        ZStack {
                            Circle()
                                .fill(currentUser.color)
                                .frame(width: 48, height: 48)
                                .shadow(color: currentUser.color.opacity(0.5), radius: 8, x: 0, y: 4)
                            
                            Text(currentUser.initials)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
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
        .onAppear {
            if profiles.isEmpty {
                let newProfile = UserProfile(avatarColorHex: randomColorHex())
                modelContext.insert(newProfile)
            }
        }
        .sheet(isPresented: $showingProfileSheet) {
            ProfileEditView(profile: currentUser)
        }
    }
    
    private func randomColorHex() -> String {
        let colors = [
            "#FF5733", "#33FF57", "#3357FF", "#FF33F6", 
            "#33FFF6", "#F6FF33", "#FF8C00", "#9932CC"
        ]
        return colors.randomElement() ?? "#CCCCCC"
    }
}

struct ProfileEditView: View {
    @Bindable var profile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("First Name", text: $profile.firstName)
                    TextField("Last Name", text: $profile.lastName)
                }
                
                Section(header: Text("Avatar Color")) {
                    HStack {
                        Circle()
                            .fill(profile.color)
                            .frame(width: 40, height: 40)
                        
                        Spacer()
                        
                        Button("Randomize Color") {
                            profile.avatarColorHex = randomColorHex()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func randomColorHex() -> String {
        let colors = [
            "#FF5733", "#33FF57", "#3357FF", "#FF33F6", 
            "#33FFF6", "#F6FF33", "#FF8C00", "#9932CC",
            "#00FA9A", "#DC143C", "#1E90FF", "#FF1493"
        ]
        return colors.randomElement() ?? "#CCCCCC"
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
