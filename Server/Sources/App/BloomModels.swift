import Foundation

struct BloomMessage: Codable {
    enum MessageType: String, Codable {
        case handshake // Client -> Server: Join room
        case stateUpdate // Patient -> Server -> Therapist: Sync data
        case recommendCourse // Therapist -> Server -> Patient: Send command
    }

    let id: UUID
    let type: MessageType
    let data: Data
    
    init(type: MessageType, data: Data, id: UUID = UUID()) {
        self.id = id
        self.type = type
        self.data = data
    }
}

enum UserRole: String, Codable {
    case patient
    case therapist
}

struct HandshakePayload: Codable {
    let role: UserRole
    let roomCode: String
}

struct PatientStatePayload: Codable {
    // Basic stats for the therapist to see
    let totalPracticeCount: Int
    let recentCourse: String
    let lastPracticeDate: Date?
    // Could add heat map data here if needed, but keeping it simple for now
}

struct RecommendCoursePayload: Codable {
    let courseTitle: String
    let setDuration: Int
}
