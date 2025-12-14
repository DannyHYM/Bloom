import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
                        lockOrientation(allowAll: true)
                        withAnimation {
                            self.appState = .gardening(course)
                        }
                    },
                    onCalibrate: {
                        lockOrientation(allowAll: false)
                        withAnimation {
                            self.appState = .calibration
                        }
                    }
                )
                .transition(AnyTransition.move(edge: .leading))
                .onAppear { lockOrientation(allowAll: false) }
                
            case .calibration:
                CalibrationView(onCalibrated: { span in
                    self.handSpan = span
                    lockOrientation(allowAll: false)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.appState = .home // Return home after calibration
                    }
                })
                .transition(AnyTransition.opacity)
                .onAppear { lockOrientation(allowAll: false) }
                
            case .gardening:
                // This state is just a placeholder to trigger fullScreenCover now
                Color.black.ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item:Binding<Course?>(
            get: {
                if case .gardening(let course) = appState {
                    return course
                }
                return nil
            },
            set: { (newValue: Course?) in
                if newValue == nil {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.appState = .home
                    }
                }
            }
        )) { (course: Course) in
            BloomView(
                targetSpan: handSpan,
                course: course,
                onRecalibrate: {
                    lockOrientation(allowAll: false)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.appState = .home
                    }
                }
            )
            .background(Color.black.ignoresSafeArea()) // Ensure solid background behind the glass
            .onAppear { lockOrientation(allowAll: true) }
            .onDisappear { lockOrientation(allowAll: false) }
        }
    }
    
    func lockOrientation(allowAll: Bool) {
        #if canImport(UIKit)
        let orientation: UIInterfaceOrientationMask = allowAll ? .all : .portrait
        AppDelegate.orientationLock = orientation
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            
            if !allowAll {
                // Force portrait
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
        #endif
    }
}

#Preview {
    ContentView()
}
