import Foundation
import CoreGraphics

enum GesturePattern: Equatable {
    case dualTouch(span: CGFloat, angle: CGFloat) // Added angle parameter (in radians)
    
    // Helper to get target points relative to center (0,0)
    func getTargets() -> [CGPoint] {
        switch self {
        case .dualTouch(let span, let angle):
            // Calculate rotated points
            // Start with horizontal points: (-span/2, 0) and (span/2, 0)
            // Rotate them by 'angle'
            let halfSpan = span / 2
            
            // Point 1: Left (rotated)
            let p1 = CGPoint(
                x: -halfSpan * cos(angle),
                y: -halfSpan * sin(angle)
            )
            
            // Point 2: Right (rotated)
            let p2 = CGPoint(
                x: halfSpan * cos(angle),
                y: halfSpan * sin(angle)
            )
            
            return [p1, p2]
        }
    }
    
    var name: String {
        switch self {
        case .dualTouch(_, let angle):
            // Convert radians to degrees for display if needed
            let degrees = Int(abs(angle * 180 / .pi))
            if degrees == 0 { return "Dual Span" }
            return "Dual Span (\(degrees)°)"
        }
    }
}

struct CourseStep: Identifiable, Equatable {
    let id = UUID()
    let pattern: GesturePattern
    let holdDuration: TimeInterval = 1.0
}
