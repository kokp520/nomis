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
import CoreData

@main
struct nomisApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @Environment(\.scenePhase) private var scenePhase
    let coreDataManager: CoreDataManager
    
    init() {
        self.coreDataManager = CoreDataManager.shared
        
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environment(\.managedObjectContext, coreDataManager.mainContext)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .environment(\.managedObjectContext, coreDataManager.mainContext)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive {
                coreDataManager.saveContext()
            }
        }
    }
}
