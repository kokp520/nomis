import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct BinTestAppView: App {
    // 註冊 app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            BinMainView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        #if DEBUG
        // 設定模擬器
        let settings = Firestore.firestore().settings
        settings.host = "127.0.0.1:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        // 設定 Auth 模擬器
        Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
        
        // 設定 Storage 模擬器
        Storage.storage().useEmulator(withHost: "127.0.0.1", port: 9199)
        #endif
        
        FirebaseApp.configure()
        return true
    }
} 
