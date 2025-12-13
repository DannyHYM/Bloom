//
//  ContentView.swift
//  Bloom
//
//  Created by Yuhao Chen on 12/4/25.
//

import SwiftUI

enum AppState {
    case home
    case calibration
    case gardening(Course?) // Pass selected course (optional for now)
}

struct ContentView: View {
    @State private var appState: AppState = .home
    @State private var handSpan: CGFloat = 200.0 // Default/Fallback
    
    var body: some View {
        ZStack {
            // Background stays consistent
            Color.black.ignoresSafeArea()
            
            switch appState {
            case .home:
                HomeView(
                    onSelectCourse: { course in
                        withAnimation {
                            self.appState = .gardening(course)
                        }
                    },
                    onCalibrate: {
                        withAnimation {
                            self.appState = .calibration
                        }
                    }
                )
                .transition(AnyTransition.move(edge: .leading))
                
            case .calibration:
                CalibrationView(onCalibrated: { span in
                    self.handSpan = span
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.appState = .home // Return home after calibration
                    }
                })
                .transition(AnyTransition.opacity)
                
            case .gardening(let course):
                BloomView(
                    targetSpan: handSpan,
                    theme: course?.theme,
                    onRecalibrate: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.appState = .home // Go back home instead of recalibrate directly
                        }
                    }
                )
                // We could pass 'course' to BloomView to change theme/difficulty
                .transition(AnyTransition.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
