import SwiftUI
import Combine

class CalibrationViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case detecting
        case calibrated(span: CGFloat)
    }
    
    @Published var state: State = .idle
    @Published var activeTouches: [TouchPoint] = []
    @Published var calibrationProgress: Double = 0.0
    
    private let minSpanThreshold: CGFloat = 50.0
    private var calibrationTimer: Timer?
    private let requiredHoldTime: TimeInterval = 1.5
    
    func updateTouches(_ touches: [TouchPoint]) {
        self.activeTouches = touches
        
        switch state {
        case .idle, .detecting:
            if touches.count == 2 {
                // Potential calibration pose
                let p1 = touches[0].location
                let p2 = touches[1].location
                let distance = hypot(p2.x - p1.x, p2.y - p1.y)
                
                if distance > minSpanThreshold {
                    startCalibration(span: distance)
                } else {
                    resetCalibration()
                }
            } else {
                resetCalibration()
            }
            
        case .calibrated:
            if touches.isEmpty {
                // Optional: Reset if they lift hands completely? 
                // For now, let's keep it simpler.
            }
        }
    }
    
    private func startCalibration(span: CGFloat) {
        guard calibrationTimer == nil else { return } // Timer already running
        
        state = .detecting
        var elapsedTime: TimeInterval = 0
        
        calibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            elapsedTime += 0.1
            self.calibrationProgress = elapsedTime / self.requiredHoldTime
            
            if elapsedTime >= self.requiredHoldTime {
                self.completeCalibration(span: span)
            }
        }
    }
    
    private func resetCalibration() {
        calibrationTimer?.invalidate()
        calibrationTimer = nil
        calibrationProgress = 0.0
        if case .detecting = state {
            state = .idle
        }
    }
    
    private func completeCalibration(span: CGFloat) {
        calibrationTimer?.invalidate()
        calibrationTimer = nil
        state = .calibrated(span: span)
        // Here we would typically transition to the main game loop
    }
}
