import SwiftUI

// MARK: - Extensions

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

// MARK: - Shared Models

struct Course: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let theme: CourseTheme
    let strategy: CourseStrategy
    let defaultSets: Int
}

enum CourseStrategy {
    case gentle   // Morning Awakening: Small angles, consistent span
    case rhythmic // Deep Focus: Repeating patterns
    case stretch  // Hand Yoga: Wide variations, diagonal angles
    case chaotic  // Cosmic Flow: Full random
}

enum CourseTheme {
    case sunrise
    case deepOcean
    case forest
    case nebula
}

extension Course {
    static let allCourses = [
        Course(title: "Morning Awakening", subtitle: "Gentle stretches to start your day", theme: .sunrise, strategy: .gentle, defaultSets: 8),
        Course(title: "Deep Focus", subtitle: "Rhythmic patterns for concentration", theme: .deepOcean, strategy: .rhythmic, defaultSets: 12),
        Course(title: "Hand Yoga", subtitle: "Flexibility and dexterity training", theme: .forest, strategy: .stretch, defaultSets: 10),
        Course(title: "Cosmic Flow", subtitle: "Explore complex generative patterns", theme: .nebula, strategy: .chaotic, defaultSets: 15)
    ]
}

extension CourseTheme {
    var baseColor: Color {
        switch self {
        case .sunrise: return Color(hex: 0xFF8C00, alpha: 0.3)
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
