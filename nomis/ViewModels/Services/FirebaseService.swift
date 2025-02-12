import Foundation
import FirebaseCore
import FirebaseFirestore

public class FirebaseService : ObservableObject {
    public static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {
        // 初始化 Firebase
        if FirebaseApp.app() == nil {
            if let config = DatabaseConfig.shared.loadGoogleServiceInfo() {
                let options = FirebaseOptions(
                    googleAppID: config["appId"] as! String,
                    gcmSenderID: config["messagingSenderId"] as! String
                )
                options.apiKey = config["apiKey"] as! String
                options.projectID = config["projectId"] as! String
                FirebaseApp.configure(options: options)
            }
        }
    }
    
    // 在這裡添加 Firebase 相關的方法
    @Published public var groups: [Group] = []
    @Published public var selectedGroup: Group?
    
    public func selectGroup(_ group: Group) {
        selectedGroup = group
        NotificationCenter.default.post(name: Notification.Name("SelectedGroupChanged"), object: nil)
    }
    
    public func signInAnonymously() async throws {
        // 實現匿名登入邏輯
    }
    
    public func fetchGroups() async {
        // 實現獲取群組邏輯
    }
    
    public func createGroup(name: String) async throws {
        // 實現創建群組邏輯
    }
} 
