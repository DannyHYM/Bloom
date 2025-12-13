import Foundation
import CoreGraphics

enum GesturePattern: Equatable {
    case singleTouch(radius: CGFloat, angle: CGFloat)
    case dualTouch(span: CGFloat, angle: CGFloat)
    case triTouch(radius: CGFloat, angle: CGFloat)
    case quadTouch(radius: CGFloat, angle: CGFloat)
    
    // Helper to get target points relative to center (0,0)
    func getTargets() -> [CGPoint] {
        switch self {
        case .singleTouch(let radius, let angle):
            return [
                CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            ]
            
        case .dualTouch(let span, let angle):
            let halfSpan = span / 2
            return [
                CGPoint(x: -halfSpan * cos(angle), y: -halfSpan * sin(angle)),
                CGPoint(x: halfSpan * cos(angle), y: halfSpan * sin(angle))
            ]
            
        case .triTouch(let radius, let angle):
            return (0..<3).map { i in
                let theta = angle + (CGFloat(i) * (2 * .pi / 3))
                return CGPoint(x: radius * cos(theta), y: radius * sin(theta))
            }
            
        case .quadTouch(let radius, let angle):
            return (0..<4).map { i in
                let theta = angle + (CGFloat(i) * (2 * .pi / 4))
                return CGPoint(x: radius * cos(theta), y: radius * sin(theta))
            }
        }
    }
    
    var name: String {
        switch self {
        case .singleTouch: return "Focus Point"
        case .dualTouch: return "Span"
        case .triTouch: return "Triangle"
        case .quadTouch: return "Square"
        }
    }
}

struct CourseStep: Identifiable, Equatable {
    let id = UUID()
    let pattern: GesturePattern
    let holdDuration: TimeInterval = 1.0
}
