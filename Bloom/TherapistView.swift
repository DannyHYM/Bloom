import SwiftUI

struct TherapistView: View {
    @Environment(RemoteManager.self) private var remoteManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputCode: String = ""
    @State private var selectedCourse: Course?
    @State private var selectedSets: Double = 10
    
    @AppStorage("serverURL") private var serverURL: String = "wss://opbloom.fly.dev"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if !remoteManager.isConnected || remoteManager.role != .therapist {
                        connectionView
                    } else {
                        dashboardView
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Therapist Mode")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    var connectionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 40)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Connect to Patient")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text("Enter the 6-digit session code found on the patient's profile.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                TextField("Server URL", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    .foregroundStyle(.white)
                
                TextField("000000", text: $inputCode)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(white: 0.1))
                    .cornerRadius(12)
                    .foregroundStyle(.white)
                    .onChange(of: inputCode) { _, newValue in
                        if newValue.count > 6 {
                            inputCode = String(newValue.prefix(6))
                        }
                    }
                
                Button(action: {
                    remoteManager.connect(as: .therapist, code: inputCode)
                }) {
                    Text(remoteManager.isConnected ? "Connecting..." : "Connect")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputCode.count == 6 ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .disabled(inputCode.count < 6)
            }
            
            Spacer()
        }
    }
    
    var dashboardView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Card
                VStack(spacing: 12) {
                    HStack {
                        Label("Status", systemImage: "network")
                            .font(.caption)
                            .foregroundStyle(.gray)
                        Spacer()
                        Text("Connected")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    if let state = remoteManager.patientState {
                        HStack(spacing: 0) {
                            statItem(value: "\(state.totalPracticeCount)", label: "Sessions")
                            Divider().background(Color.white.opacity(0.1))
                            statItem(value: state.recentCourse, label: "Last Course")
                        }
                        .padding(.top, 8)
                    } else {
                        Text("Waiting for patient data...")
                            .foregroundStyle(.gray)
                            .padding()
                    }
                }
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(16)
                
                // Recommendation Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommend Exercise")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Course.allCourses) { course in
                                Button(action: { selectedCourse = course }) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        // Top section with title
                                        ZStack(alignment: .topLeading) {
                                            course.theme.baseColor.opacity(0.6)
                                            
                                            Text(course.title)
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundStyle(.white)
                                                .padding(12)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(height: 80)
                                        
                                        // Bottom section with pattern
                                        GenerativePatternView(theme: course.theme)
                                            .frame(height: 60)
                                            .overlay(
                                                LinearGradient(
                                                    colors: [.black.opacity(0.2), .clear],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedCourse?.id == course.id ? Color.blue : Color.white.opacity(0.1), lineWidth: 3)
                                    )
                                    .frame(width: 140, height: 140)
                                    .overlay(alignment: .topTrailing) {
                                        if selectedCourse?.id == course.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.white)
                                                .background(Circle().fill(.blue))
                                                .offset(x: 8, y: -8)
                                        }
                                    }
                                    .padding(.top, 10) // Make room for the checkmark popout
                                }
                            }
                        }
                    }
                    
                    if let _ = selectedCourse {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .foregroundStyle(.gray)
                                Spacer()
                                Text("\(Int(selectedSets)) Sets")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            
                            Slider(value: $selectedSets, in: 5...30, step: 1)
                                .tint(.blue)
                        }
                        .padding()
                        .background(Color(white: 0.1))
                        .cornerRadius(12)
                        
                        Button(action: {
                            if let course = selectedCourse {
                                remoteManager.recommend(course: course.title, sets: Int(selectedSets))
                            }
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Recommendation")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
                
                Button(role: .destructive, action: {
                    remoteManager.disconnect()
                }) {
                    Text("End Session")
                        .foregroundStyle(.red)
                }
                .padding(.top, 20)
            }
        }
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    TherapistView()
        .environment(RemoteManager())
        .preferredColorScheme(.dark)
}
