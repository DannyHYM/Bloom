import SwiftUI

struct TherapistView: View {
    @Environment(RemoteManager.self) private var remoteManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var inputCode: String = ""
    @State private var selectedCourse: Course?
    @State private var selectedSets: Double = 10
    
    var body: some View {
        NavigationStack {
            Form {
                if !remoteManager.isConnected || remoteManager.role != .therapist {
                    Section(header: Text("Connection")) {
                        TextField("Enter Patient Code", text: $inputCode)
                            .textInputAutocapitalization(.characters)
                            .font(.system(.body, design: .monospaced))
                        
                        Button("Connect") {
                            remoteManager.connect(as: .therapist, code: inputCode)
                        }
                        .disabled(inputCode.count < 6)
                    }
                } else {
                    Section(header: Text("Patient Status")) {
                        LabeledContent("Status", value: "Connected")
                            .foregroundStyle(.green)
                        
                        if let state = remoteManager.patientState {
                            LabeledContent("Total Practice", value: "\(state.totalPracticeCount)")
                            LabeledContent("Last Course", value: state.recentCourse)
                            if let date = state.lastPracticeDate {
                                LabeledContent("Last Active", value: date.formatted(date: .abbreviated, time: .shortened))
                            }
                        } else {
                            Text("Waiting for patient data...")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section(header: Text("Recommendation")) {
                        Picker("Select Course", selection: $selectedCourse) {
                            Text("Select a course...").tag(nil as Course?)
                            ForEach(Course.allCourses) { course in
                                Text(course.title).tag(course as Course?)
                            }
                        }
                        
                        if selectedCourse != nil {
                            VStack(alignment: .leading) {
                                Text("Sets: \(Int(selectedSets))")
                                Slider(value: $selectedSets, in: 5...30, step: 1)
                            }
                            
                            Button("Send Recommendation") {
                                if let course = selectedCourse {
                                    remoteManager.recommend(course: course.title, sets: Int(selectedSets))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Section {
                        Button("Disconnect", role: .destructive) {
                            remoteManager.disconnect()
                        }
                    }
                }
            }
            .navigationTitle("Therapist Mode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
