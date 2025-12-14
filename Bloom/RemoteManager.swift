import SwiftUI
import SwiftData

@Observable
class RemoteManager {
    var isConnected = false
    var roomCode = ""
    var role: UserRole = .patient
    
    // Therapist Data
    var patientState: PatientStatePayload?
    
    // Client
    private var client: BloomClient?
    private let userId = UUID()
    
    // Alert triggers
    var pendingRecommendation: RecommendCoursePayload?
    var showRecommendationAlert = false
    
    func generateCode() {
        let characters = "0123456789"
        self.roomCode = String((0..<6).map { _ in characters.randomElement()! })
    }
    
    func connect(as role: UserRole, code: String? = nil) {
        self.role = role
        if let code = code {
            self.roomCode = code
        } else if roomCode.isEmpty {
            generateCode()
        }
        
        client = BloomClient(userId: userId, roomCode: roomCode)
        
        client?.onConnectionStateChange = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .connected:
                self.isConnected = true
                self.sendHandshake()
            default:
                self.isConnected = false
            }
        }
        
        client?.onMessage = { [weak self] message in
            guard let self = self else { return }
            self.handleMessage(message)
        }
        
        client?.connect()
    }
    
    func disconnect() {
        client?.disconnect()
        isConnected = false
        patientState = nil
    }
    
    private func sendHandshake() {
        let payload = HandshakePayload(role: role, roomCode: roomCode)
        sendMessage(type: .handshake, payload: payload)
        
        if role == .patient {
             // Send initial empty state or current state if available
             // Real state update happens when triggered by View
        }
    }
    
    func sendStateUpdate(totalPractice: Int, recentCourse: String) {
        guard role == .patient else { return }
        let payload = PatientStatePayload(
            totalPracticeCount: totalPractice,
            recentCourse: recentCourse,
            lastPracticeDate: Date()
        )
        sendMessage(type: .stateUpdate, payload: payload)
    }
    
    func recommend(course: String, sets: Int) {
        guard role == .therapist else { return }
        let payload = RecommendCoursePayload(courseTitle: course, setDuration: sets)
        sendMessage(type: .recommendCourse, payload: payload)
    }
    
    private func sendMessage<T: Codable>(type: BloomMessage.MessageType, payload: T) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        let message = BloomMessage(type: type, data: data)
        
        Task {
            try? await client?.send(message)
        }
    }
    
    private func handleMessage(_ message: BloomMessage) {
        switch message.type {
        case .stateUpdate:
            if role == .therapist {
                if let payload = try? JSONDecoder().decode(PatientStatePayload.self, from: message.data) {
                    self.patientState = payload
                }
            }
        case .recommendCourse:
            if role == .patient {
                if let payload = try? JSONDecoder().decode(RecommendCoursePayload.self, from: message.data) {
                    self.pendingRecommendation = payload
                    self.showRecommendationAlert = true
                }
            }
        default:
            break
        }
    }
}
