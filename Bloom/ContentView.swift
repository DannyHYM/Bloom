//
//  ContentView.swift
//  Bloom
//
//  Created by Yuhao Chen on 12/4/25.
//

import SwiftUI

enum AppState {
    case calibration
    case gardening // The main loop
}

struct ContentView: View {
    @State private var appState: AppState = .calibration
    @State private var handSpan: CGFloat = 200.0 // Default/Fallback
    
    var body: some View {
        ZStack {
            // Background stays consistent
            Color.black.ignoresSafeArea()
            
            switch appState {
            case .calibration:
                CalibrationView(onCalibrated: { _ in
                    // Demo Mode: Ignore actual calibration, use fixed value
                    self.handSpan = 200.0
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.appState = .gardening
                    }
                })
                .transition(.opacity)
                
            case .gardening:
                BloomView(targetSpan: handSpan, onRecalibrate: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.appState = .calibration
                    }
                })
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
