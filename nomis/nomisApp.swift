//
//  nomisApp.swift
//  nomis
//
//  Created by adi on 2025/2/6.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@main
struct nomisApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()

        // cannel jump up login view, if user is already logged in
//         authViewModel.checkAuthenticationStatus()
//        authViewModel.setupAuthStateListener()
        
        // 暫時註解掉模擬器設定，先使用實際的 Firebase
        /*
        #if DEBUG && USE_FIREBASE_EMULATOR
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
        */
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
