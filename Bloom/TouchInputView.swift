import SwiftUI
import UIKit

struct TouchPoint: Identifiable, Equatable {
    let id: Int // We'll use hash of the UITouch object as stable ID
    let location: CGPoint
}

struct TouchInputView: UIViewRepresentable {
    var onUpdate: ([TouchPoint]) -> Void
    
    func makeUIView(context: Context) -> MultiTouchView {
        let view = MultiTouchView()
        view.onUpdate = onUpdate
        return view
    }
    
    func updateUIView(_ uiView: MultiTouchView, context: Context) {
        uiView.onUpdate = onUpdate
    }
    
    class MultiTouchView: UIView {
        var onUpdate: (([TouchPoint]) -> Void)?
        
        private var activeTouches = [UITouch]()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            isMultipleTouchEnabled = true
            backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            updateTouches(with: event)
        }
        
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            updateTouches(with: event)
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            updateTouches(with: event)
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            updateTouches(with: event)
        }
        
        private func updateTouches(with event: UIEvent?) {
            guard let event = event else { return }
            
            
            let touches = event.allTouches?.compactMap { touch -> TouchPoint? in
                guard touch.phase != .ended && touch.phase != .cancelled else { return nil }
                let location = touch.location(in: self)
                return TouchPoint(id: touch.hash, location: location)
            } ?? []
            
            onUpdate?(touches)
        }
    }
}
