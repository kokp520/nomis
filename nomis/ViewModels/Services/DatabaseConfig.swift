/*
import Foundation

enum AppEnvironment {
    case development
    case production
}

class DatabaseConfig {
    static let shared = DatabaseConfig()
    
    var currentEnvironment: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    func loadGoogleServiceInfo() -> [String: Any]? {
        guard let plistPath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plistData = FileManager.default.contents(atPath: plistPath),
              let plistDict = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            print("錯誤：無法讀取 GoogleService-Info.plist")
            return nil
        }
        
        return [
            "apiKey": plistDict["API_KEY"] as? String ?? "",
            "authDomain": plistDict["AUTH_DOMAIN"] as? String ?? "",
            "projectId": plistDict["PROJECT_ID"] as? String ?? "",
            "storageBucket": plistDict["STORAGE_BUCKET"] as? String ?? "",
            "messagingSenderId": plistDict["MESSAGING_SENDER_ID"] as? String ?? "",
            "appId": plistDict["BUNDLE_ID"] as? String ?? "",
            "clientId": plistDict["CLIENT_ID"] as? String ?? ""
        ]
    }
    
    private init() {}
} 
*/
