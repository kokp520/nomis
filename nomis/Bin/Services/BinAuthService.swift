import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import SwiftUI

@MainActor
class BinAuthService: NSObject, ObservableObject {
    @Published var user: BinUser?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isUsingEmulator = true
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var currentNonce: String?
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        setupAuthStateListener()
        
        #if DEBUG
        // 預設使用模擬器
        setupEmulator()
        #endif
    }
    
    // MARK: - 環境設定
    func toggleEnvironment() {
        isUsingEmulator.toggle()
        
        // 移除現有的監聽器
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
        
        // 登出當前用戶
        try? signOut()
        
        // 重新配置 Firebase
        if isUsingEmulator {
            setupEmulator()
        } else {
            setupProduction()
        }
        
        // 重新設定監聽器
        setupAuthStateListener()
    }
    
    private func setupEmulator() {
        let settings = Firestore.firestore().settings
        settings.host = "127.0.0.1:8080"
        settings.isPersistenceEnabled = false
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
        Storage.storage().useEmulator(withHost: "127.0.0.1", port: 9199)
        
        print("🔧 已切換到模擬器環境")
    }
    
    private func setupProduction() {
        let settings = Firestore.firestore().settings
        settings.host = Firestore.firestore().app.options.projectID + ".firebaseio.com"
        settings.isPersistenceEnabled = true
        settings.isSSLEnabled = true
        Firestore.firestore().settings = settings
        
        print("🌐 已切換到線上環境")
    }
    
    private func setupAuthStateListener() {
        stateListener = auth.addStateDidChangeListener { [weak self] (_, user) in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                if let user = user {
                    try? await self?.fetchUserData(userId: user.uid)
                }
            }
        }
    }
    
    deinit {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Email 註冊/登入
    func signUp(email: String, password: String, name: String) async throws {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let newUser = BinUser(id: result.user.uid, name: name, email: email)
            try await saveUserToFirestore(user: newUser)
            self.user = newUser
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            try await fetchUserData(userId: result.user.uid)
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Apple 登入
    func signInWithApple() async throws {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let result = try await performAppleSignIn(request: request)
        
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
           let appleIDToken = appleIDCredential.identityToken,
           let idTokenString = String(data: appleIDToken, encoding: .utf8) {
            
            guard let nonce = currentNonce else {
                throw NSError(domain: "BinAuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid nonce"])
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            let authResult = try await auth.signIn(with: credential)
            
            // 如果是新用戶，保存用戶資料
            let newUser = BinUser(
                id: authResult.user.uid,
                name: appleIDCredential.fullName?.givenName ?? "User",
                email: appleIDCredential.email ?? authResult.user.email ?? ""
            )
            
            try await saveUserToFirestore(user: newUser)
            self.user = newUser
        }
    }
    
    private func performAppleSignIn(request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AuthorizationDelegate(continuation: continuation)
            controller.delegate = delegate
            controller.performRequests()
            
            // 保持對 delegate 的強引用
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    // MARK: - 其他功能
    func signOut() throws {
        do {
            try auth.signOut()
            self.user = nil
            self.isAuthenticated = false
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - 輔助方法
    private func saveUserToFirestore(user: BinUser) async throws {
        try await db.collection("users").document(user.id).setData([
            "name": user.name,
            "email": user.email,
            "id": user.id,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
    
    private func fetchUserData(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let data = document.data(),
              let name = data["name"] as? String,
              let email = data["email"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            throw NSError(domain: "BinAuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        self.user = BinUser(id: userId, name: name, email: email, createdAt: createdAt.dateValue())
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
    
    // MARK: - Firebase 測試方法
    func testFirebaseConnection() {
        // 測試 Firestore 連接
        db.collection("test").document("connection")
            .setData(["timestamp": FieldValue.serverTimestamp(),
                     "status": "connected",
                     "device": UIDevice.current.name,
                     "system": UIDevice.current.systemVersion])
            { error in
                if let error = error {
                    print("❌ Firebase 連接失敗: \(error.localizedDescription)")
                } else {
                    print("✅ Firebase 連接成功！")
                }
            }
    }
    
    // 重新載入用戶資料
    func reloadUser() async throws {
        guard let currentUser = Auth.auth().currentUser else { return }
        try await currentUser.reload()
        if let userId = currentUser.uid {
            try await fetchUserData(userId: userId)
        }
        print("✅ 用戶資料已重新載入")
    }
    
    // 監聽資料變化
    func listenToUserChanges(userId: String) {
        db.collection("users").document(userId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("❌ 監聽錯誤: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                print("📝 用戶資料更新: \(document.data() ?? [:])")
            }
    }
    
    // 查看目前的 Auth 狀態
    func printAuthState() {
        if let user = Auth.auth().currentUser {
            print("👤 目前登入用戶:")
            print("   - UID: \(user.uid)")
            print("   - Email: \(user.email ?? "無")")
            print("   - 名稱: \(user.displayName ?? "無")")
            print("   - 驗證狀態: \(user.isEmailVerified ? "已驗證" : "未驗證")")
        } else {
            print("❌ 目前沒有用戶登入")
        }
    }
    
    // 查看用戶資料
    func printUserData(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                print("📋 用戶資料:")
                print("   - 名稱: \(data["name"] ?? "無")")
                print("   - 信箱: \(data["email"] ?? "無")")
                print("   - ID: \(data["id"] ?? "無")")
                if let timestamp = data["createdAt"] as? Timestamp {
                    print("   - 建立時間: \(timestamp.dateValue().formatted())")
                }
            } else {
                print("❌ 找不到用戶資料")
            }
        } catch {
            print("❌ 讀取用戶資料失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: - Apple Sign In Delegate
private class AuthorizationDelegate: NSObject, ASAuthorizationControllerDelegate {
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

#if DEBUG
extension BinAuthService {
    @MainActor
    static var preview: BinAuthService {
        let service = BinAuthService()
        // 模擬用戶資料
        service.user = BinUser(
            id: "preview-user-id",
            name: "預覽使用者",
            email: "preview@example.com",
            createdAt: Date()
        )
        service.isAuthenticated = true
        return service
    }
}
#endif 