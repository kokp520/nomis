import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation
import ObjectiveC
import SwiftUI
import UIKit

extension Notification.Name {
    static let groupDidChange = Notification.Name("groupDidChange")
}

@MainActor
public class FirebaseService: ObservableObject {
    public static let shared = FirebaseService()
    private let db: Firestore
    
    @Published public var groups: [Group] = []
    @Published public var selectedGroup: Group?
    @Published public var currentUser: User?
    @Published public var isAuthenticated = false
    private var currentNonce: String?
    
    private init() {
        // 檢查是否已經登入
        if let user = Auth.auth().currentUser {
            self.currentUser = User(id: user.uid, name: user.displayName ?? "", email: user.email ?? "")
            self.isAuthenticated = true
        }
        self.db = Firestore.firestore()
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - 認證相關

    public func signInWithApple() async throws {
        let nonce = randomNonceString()
        currentNonce = nonce
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AuthorizationControllerDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.presentationContextProvider = UIApplication.shared.windows.first?.rootViewController as? ASAuthorizationControllerPresentationContextProviding
            controller.performRequests()
            // 保持對 delegate 的強引用
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
        
        if let appleIDCredential = result as? ASAuthorizationAppleIDCredential {
            let idToken = String(data: appleIDCredential.identityToken!, encoding: .utf8)!
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idToken,
                rawNonce: currentNonce ?? "nil"
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            print("用戶登入成功：\(user.uid)")
            
            // 更新用戶資料
            currentUser = User(
                id: user.uid,
                name: user.displayName ?? "",
                email: user.email ?? ""
            )
            isAuthenticated = true
            
            print("當前用戶設置完成：\(currentUser?.id ?? "nil")")
            
            // 儲存用戶資料到 Firestore
            try await saveUserToFirestore(user: currentUser!)
            
            // 立即獲取群組
            try await fetchGroups()
            print("獲取到的群組數量：\(groups.count)")
            groups.forEach { group in
                print("群組：\(group.name), 成員：\(group.members)")
            }
        }
    }
    
    private func saveUserToFirestore(user: User) async throws {
        try await db.collection("users").document(user.id).setData([
            "name": user.name,
            "email": user.email,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - 群組相關

    public func createGroup(name: String) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "用戶未登入"])
        }
        
        let groupRef = db.collection("groups").document()
        let newGroup = Group(id: groupRef.documentID, name: name, owner: user.id, members: [user.id])
        
        try await groupRef.setData([
            "name": name,
            "owner": user.id,
            "members": [user.id],
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        groups.append(newGroup)
        selectedGroup = newGroup
    }
    
    public func fetchGroups() async throws {
        guard let user = currentUser else {
            print("fetchGroups: 當前用戶為空")
            return
        }
        
        print("開始獲取群組，用戶ID：\(user.id)")
        
        let snapshot = try await db.collection("groups")
            .whereField("members", arrayContains: user.id)
            .getDocuments()
        
        print("查詢到 \(snapshot.documents.count) 個群組文檔")
        
        groups = snapshot.documents.compactMap { doc -> Group? in
            let data = doc.data()
            print("群組文檔數據：\(data)")
            
            guard let name = data["name"] as? String,
                  let owner = data["owner"] as? String,
                  let members = data["members"] as? [String]
            else {
                print("群組數據格式不正確：\(doc.documentID)")
                return nil
            }
            return Group(id: doc.documentID, name: name, owner: owner, members: members)
        }
        
        print("處理後的群組數量：\(groups.count)")
    }
    
    public func addMemberToGroup(_ email: String) async throws {
        guard let group = selectedGroup else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "沒有選擇群組"])
        }
        
        // 查找用戶
        let userSnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()
        
        guard let userDoc = userSnapshot.documents.first else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "找不到該用戶"])
        }
        
        // 更新群組成員
        try await db.collection("groups").document(group.id).updateData([
            "members": FieldValue.arrayUnion([userDoc.documentID])
        ])
        
        // 更新本地資料
        if var updatedGroup = groups.first(where: { $0.id == group.id }) {
            updatedGroup.members.append(userDoc.documentID)
            if let index = groups.firstIndex(where: { $0.id == group.id }) {
                groups[index] = updatedGroup
            }
            selectedGroup = updatedGroup
        }
    }
    
    // MARK: - 交易相關

    public func addTransaction(_ transaction: Transaction, groupID: String) async throws {
        let transactionRef = db.collection("groups").document(groupID).collection("transactions").document()
        
        let transactionData: [String: Any] = [
            "id": transactionRef.documentID,
            "title": transaction.title,
            "amount": transaction.amount,
            "date": transaction.date,
            "categoryId": transaction.category.id,
            "categoryName": transaction.category.name,
            "categoryIcon": transaction.category.icon,
            "categoryColorHex": transaction.category.color.toHex() ?? "#808080",
            "type": transaction.type.rawValue,
            "note": transaction.note ?? "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await transactionRef.setData(transactionData)
    }
    
    public func fetchTransactions(groupID: String) async throws -> [Transaction] {
        // 檢查用戶是否為群組成員
        guard let user = currentUser else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "用戶未登入"])
        }
        
        // 獲取群組資訊並檢查權限
        let groupDoc = try await db.collection("groups").document(groupID).getDocument()
        guard let groupData = groupDoc.data(),
              let members = groupData["members"] as? [String],
              members.contains(user.id) else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "沒有權限訪問該群組"])
        }
        
        let snapshot = try await db.collection("groups")
            .document(groupID)
            .collection("transactions")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            let data = document.data()
            guard let title = data["title"] as? String,
                  let amount = data["amount"] as? Double,
                  let date = (data["date"] as? Timestamp)?.dateValue(),
                  let typeString = data["type"] as? String,
                  let type = TransactionType(rawValue: typeString)
            else {
                return nil
            }
            
            // 根據舊格式或新格式處理分類
            let category: Category
            if let categoryId = data["categoryId"] as? String,
               let categoryName = data["categoryName"] as? String,
               let categoryIcon = data["categoryIcon"] as? String,
               let categoryColorHex = data["categoryColorHex"] as? String {
                // 使用新格式的分類
                let color = Color(hex: categoryColorHex) ?? .gray
                category = Category(id: categoryId, name: categoryName, icon: categoryIcon, color: color)
            } else if let categoryString = data["category"] as? String,
                      // 嘗試查找預設分類
                      let defaultCategory = Category.defaultCategories.first(where: { $0.name == categoryString }) {
                // 相容舊格式的資料
                category = defaultCategory
            } else {
                // 如果都無法處理，使用「其他」分類
                category = Category.other
            }
            
            return Transaction(
                id: document.documentID,
                title: title,
                amount: amount,
                date: date,
                category: category,
                type: type,
                note: data["note"] as? String
            )
        }
    }
    
    public func deleteTransaction(_ transaction: Transaction) async throws {
        guard let group = selectedGroup else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "沒有選擇群組"])
        }
        
        try await db.collection("groups").document(group.id)
            .collection("transactions")
            .document(transaction.id)
            .delete()
    }
    
    public func selectGroup(_ group: Group) {
        selectedGroup = group
        // 發送群組變更通知
        NotificationCenter.default.post(name: .groupDidChange, object: nil)
    }
    
    public func deleteGroup(_ group: Group) async throws {
        // 檢查是否為群組擁有者
        guard let user = currentUser, group.owner == user.id else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "只有群組擁有者可以刪除群組"])
        }
        
        // 刪除群組中的所有交易記錄
        let transactionsSnapshot = try await db.collection("groups")
            .document(group.id)
            .collection("transactions")
            .getDocuments()
        
        for doc in transactionsSnapshot.documents {
            try await doc.reference.delete()
        }
        
        // 刪除群組本身
        try await db.collection("groups").document(group.id).delete()
        
        // 更新本地資料
        groups.removeAll { $0.id == group.id }
        if selectedGroup?.id == group.id {
            selectedGroup = nil
        }
        
        // 發送群組變更通知
        NotificationCenter.default.post(name: .groupDidChange, object: nil)
    }
    
    public func updateTransaction(_ transaction: Transaction) async throws {
        guard let group = selectedGroup else {
            throw NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "沒有選擇群組"])
        }
        
        let transactionData: [String: Any] = [
            "id": transaction.id,
            "title": transaction.title,
            "amount": transaction.amount,
            "date": transaction.date,
            "categoryId": transaction.category.id,
            "categoryName": transaction.category.name,
            "categoryIcon": transaction.category.icon,
            "categoryColorHex": transaction.category.color.toHex() ?? "#808080",
            "type": transaction.type.rawValue,
            "note": transaction.note ?? "",
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("groups").document(group.id)
            .collection("transactions")
            .document(transaction.id)
            .setData(transactionData, merge: true)
    }
    
    public func signInAnonymously() async throws {
        // 實現匿名登入邏輯
    }
    
    func createUser(user: User) async throws {
        try await db.collection("users").document(user.id).setData([
            "name": user.name,
            "email": user.email,
            "id": user.id
        ])
    }
    
    func getUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data(),
              let name = data["name"] as? String,
              let email = data["email"] as? String,
              let id = data["id"] as? String
        else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        return User(id: id, name: name, email: email)
    }
    
    // MARK: - 分類相關方法
    
    // 獲取群組的自定義分類
    public func fetchCategories(groupID: String) async throws -> [Category] {
        let snapshot = try await db.collection("groups").document(groupID).collection("categories").getDocuments()
        
        var categories: [Category] = []
        for document in snapshot.documents {
            let data = document.data()
            
            let id = document.documentID
            guard let name = data["name"] as? String,
                  let icon = data["icon"] as? String,
                  let colorHex = data["colorHex"] as? String else {
                continue
            }
            
            let color = Color(hex: colorHex) ?? .gray
            let category = Category(id: id, name: name, icon: icon, color: color, groupId: groupID)
            categories.append(category)
        }
        
        return categories
    }
    
    // 添加自定義分類
    public func addCategory(_ category: Category, groupID: String) async throws {
        let categoryData: [String: Any] = [
            "name": category.name,
            "icon": category.icon,
            "colorHex": category.color.toHex() ?? "#808080",
            "createdAt": Timestamp(date: Date())
        ]
        
        if category.id.isEmpty {
            // 創建新文檔
            try await db.collection("groups").document(groupID).collection("categories").addDocument(data: categoryData)
        } else {
            // 使用預設 ID
            try await db.collection("groups").document(groupID).collection("categories").document(category.id).setData(categoryData)
        }
    }
    
    // 更新自定義分類
    public func updateCategory(_ category: Category, groupID: String) async throws {
        let categoryData: [String: Any] = [
            "name": category.name,
            "icon": category.icon,
            "colorHex": category.color.toHex() ?? "#808080",
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection("groups").document(groupID).collection("categories").document(category.id).updateData(categoryData)
    }
    
    // 刪除自定義分類
    public func deleteCategory(_ categoryID: String, groupID: String) async throws {
        try await db.collection("groups").document(groupID).collection("categories").document(categoryID).delete()
    }
}

#if DEBUG
public extension FirebaseService {
    static var preview: FirebaseService {
        let service = FirebaseService()
        service.selectedGroup = Group(id: "preview", name: "預覽群組", owner: "preview", members: ["preview"])
        return service
    }
}
#endif

// 添加 AuthorizationControllerDelegate 類
private class AuthorizationControllerDelegate: NSObject, ASAuthorizationControllerDelegate {
    let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}
