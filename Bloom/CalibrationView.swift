import SwiftUI

struct CalibrationView: View {
    @StateObject private var viewModel = CalibrationViewModel()
    @State private var animateInstruction = false
    @State private var showResult = false
    var onCalibrated: (CGFloat) -> Void
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color.black.ignoresSafeArea()
            BloomParticles()
                .opacity(0.5) // Subtle particles
            
            // Faded Flower in background
            FlowerView(isBlooming: true)
                .scaleEffect(0.8)
                .opacity(0.3)
                .blur(radius: 10)
                .allowsHitTesting(false)
            
            // MARK: - Input Layer
            TouchInputView { touches in
                viewModel.updateTouches(touches)
            }
            
            // MARK: - Visual Feedback
            ZStack {
                // Instructions
                if !showResult {
                    VStack {
                        Text(instructionText)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .opacity(0.8)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280) // Shrink width for better readability
                            .padding(40)
                            .background {
                                ZStack {
                                    // Cloud of blurred gradient
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.3))
                                        .frame(width: 180, height: 180)
                                        .offset(x: -30, y: -20)
                                        .blur(radius: 50)
                                    
                                    Circle()
                                        .fill(Color.purple.opacity(0.3))
                                        .frame(width: 180, height: 180)
                                        .offset(x: 30, y: 20)
                                        .blur(radius: 50)
                                }
                                // Subtle breathing animation
                                .scaleEffect(animateInstruction ? 1.1 : 0.9)
                                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateInstruction)
                            }
                            .padding(.top, 40)
                            .onAppear {
                                animateInstruction = true
                            }
                        Spacer()
                    }
                    .transition(.opacity)
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
                
                // Result Overlay
                if showResult, case .calibrated(let span) = viewModel.state {
                    CalibrationResultView(span: span)
                        .zIndex(10)
                }
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .calibrated(let span) = newState {
                withAnimation {
                    showResult = true
                }
                // Delay slightly to show "Calibrated!" text before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
        case .calibrated:
            return "" // Text hidden when showing full screen result
        }
    }
}

// MARK: - Result View
struct CalibrationResultView: View {
    let span: CGFloat
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icon / Graphic
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                    
                    Image(systemName: "hand.raised.fingers.spread")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, value: span)
                }
                
                VStack(spacing: 8) {
                    Text("Reach Calibrated")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("\(Int(span)) points")
                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.accentColor)
                    
                    Text("Perfect fit for your hands")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

#Preview {
    CalibrationView(onCalibrated: { _ in })
        .preferredColorScheme(.dark)
}
