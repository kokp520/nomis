//
//  nomisApp.swift
//  nomis
//
//  Created by adi on 2025/2/6.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if let config = DatabaseConfig.shared.loadGoogleServiceInfo() {
            let options = FirebaseOptions(
                googleAppID: config["appId"] as! String,
                gcmSenderID: config["messagingSenderId"] as! String
            )
            options.apiKey = config["apiKey"] as? String
            options.projectID = (config["projectId"] as! String)
            FirebaseApp.configure(options: options)
            print("info, appdelegate successfully.")
        } else {
            print("警告：無法初始化 Firebase，請確認 GoogleService-Info.plist 是否正確配置")
        }
        return true
    }
}

@main
struct nomisApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    print("MainTabView is on appearing...")
                }
        }
    }
}
