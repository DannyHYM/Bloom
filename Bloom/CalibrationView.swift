import SwiftUI

struct CalibrationView: View {
    @StateObject private var viewModel = CalibrationViewModel()
    var onCalibrated: (CGFloat) -> Void
    
    var body: some View {
        ZStack {
            // MARK: - Input Layer
            TouchInputView { touches in
                viewModel.updateTouches(touches)
            }
            
            // MARK: - Visual Feedback
            ZStack {
                // Instructions
                VStack {
                    Text(instructionText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.top, 60)
                    Spacer()
                }
                
                // Touch Indicators
                ForEach(viewModel.activeTouches) { touch in
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .background(Circle().fill(Color.accentColor.opacity(0.3)))
                        .frame(width: 60, height: 60)
                        .position(touch.location)
                        .animation(.interactiveSpring, value: touch.location)
                }
                
                // Connection Line (Visualizing span)
                if viewModel.activeTouches.count == 2 {
                    Path { path in
                        let p1 = viewModel.activeTouches[0].location
                        let p2 = viewModel.activeTouches[1].location
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                }
                
                // Progress Ring (if detecting)
                if viewModel.calibrationProgress > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: viewModel.calibrationProgress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 100, height: 100)
                }
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .calibrated(let span) = newState {
                // Delay slightly to show "Calibrated!" text before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onCalibrated(span)
                }
            }
        }
    }
    
    var instructionText: String {
        switch viewModel.state {
        case .idle:
            return "Place Thumb & Pinky on the screen\nto calibrate your reach."
        case .detecting:
            return "Hold steady..."
        case .calibrated(let span):
            return "Calibrated! Span: \(Int(span)) points"
        }
    }
}

#Preview {
    CalibrationView(onCalibrated: { _ in })
        .preferredColorScheme(.dark)
}
