import SwiftUI
import SwiftData

@Observable
class RemoteManager {
    var isConnected = false
    var roomCode = "" // User's own "Patient" code
    private var activeRoomCode = "" // The room code we are currently connected to
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
        
        // Determine the room code for the connection
        if let code = code {
            self.activeRoomCode = code
        } else {
            if roomCode.isEmpty {
                generateCode()
            }
            self.activeRoomCode = roomCode
        }
        
        let savedURL = UserDefaults.standard.string(forKey: "serverURL") ?? "wss://opbloom.fly.dev"
        let url = URL(string: savedURL) ?? URL(string: "wss://opbloom.fly.dev")!
        
        client = BloomClient(hostname: url, userId: userId, roomCode: activeRoomCode)
        
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
        let payload = HandshakePayload(role: role, roomCode: activeRoomCode)
        sendMessage(type: .handshake, payload: payload)
        
        if role == .therapist {
            // Request state from patient immediately upon joining
            sendMessage(type: .requestState, payload: "request")
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
        case .requestState:
            if role == .patient {
                // Trigger view layer to send state? Or rely on RemoteManager if it had access to models.
                // Since RemoteManager doesn't hold the models, we need a callback or notification.
                // For now, we'll emit a notification that HomeView can listen to.
                NotificationCenter.default.post(name: .bloomRequestState, object: nil)
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
