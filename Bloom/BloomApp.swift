import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

@main
struct BloomApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @State private var remoteManager = RemoteManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(remoteManager)
        }
        .modelContainer(for: [UserProfile.self, PracticeLog.self])
    }
}

#if canImport(UIKit)
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
#endif
