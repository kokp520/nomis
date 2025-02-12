import SwiftUI
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
class AuthViewModel: NSObject, ObservableObject, ASAuthorizationControllerPresentationContextProviding {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    private let firebaseService: FirebaseService
    private var stateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    
    init(firebaseService: FirebaseService = FirebaseService.shared) {
        self.firebaseService = firebaseService
        super.init()
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                if let user = user {
                    try? await self?.loadUserData(userId: user.uid)
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        Task {
            do {
                let result = try await Auth.auth().signIn(withEmail: email, password: password)
                self.errorMessage = nil
                try await loadUserData(userId: result.user.uid)
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        Task {
            do {
                // 基本驗證
                guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.errorMessage = "請輸入電子郵件"
                    return
                }
                
                guard !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.errorMessage = "請輸入密碼"
                    return
                }
                
                guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.errorMessage = "請輸入名稱"
                    return
                }
                
                guard password.count >= 6 else {
                    self.errorMessage = "密碼長度至少需要6個字符"
                    return
                }
                
                // 更嚴格的電子郵件驗證
                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
                let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
                guard emailPredicate.evaluate(with: email) else {
                    self.errorMessage = "請輸入有效的電子郵件地址"
                    return
                }
                
                // 密碼複雜度驗證
                let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{6,}$"
                let passwordPredicate = NSPredicate(format:"SELF MATCHES %@", passwordRegex)
                guard passwordPredicate.evaluate(with: password) else {
                    self.errorMessage = "密碼必須包含至少一個字母和一個數字"
                    return
                }
                
                print("開始註冊：\(email)")
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                print("用戶創建成功，UID: \(result.user.uid)")
                
                let userData = User(id: result.user.uid, name: name, email: email)
                try await firebaseService.createUser(user: userData)
                print("用戶資料保存成功")
                
                self.errorMessage = nil
                self.user = userData
                self.isAuthenticated = true
            } catch let error as NSError {
                print("註冊錯誤：\(error)")
                let authError = AuthErrorCode(_bridgedNSError: error)
                switch authError {
                case .emailAlreadyInUse:
                    self.errorMessage = "此電子郵件已被使用"
                case .invalidEmail:
                    self.errorMessage = "無效的電子郵件格式"
                case .weakPassword:
                    self.errorMessage = "密碼強度不足"
                default:
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserData(userId: String) async throws {
        self.user = try await firebaseService.getUser(userId: userId)
    }
    
    // MARK: - Apple Sign In
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
    
    func handleSignInWithAppleResult(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])
                }
                
                let credential = OAuthProvider.credential(
                    withProviderID: "apple.com",
                    idToken: idTokenString,
                    rawNonce: nonce
                )
                
                let result = try await Auth.auth().signIn(with: credential)
                let firebaseUser = result.user
                
                // 如果是新用戶，保存用戶資料
                if appleIDCredential.fullName?.givenName != nil {
                    let userData = User(
                        id: firebaseUser.uid,
                        name: [
                            appleIDCredential.fullName?.givenName,
                            appleIDCredential.fullName?.familyName
                        ].compactMap { $0 }.joined(separator: " "),
                        email: appleIDCredential.email ?? ""
                    )
                    try await firebaseService.createUser(user: userData)
                }
                
                try await loadUserData(userId: firebaseUser.uid)
            }
        case .failure(let error):
            throw error
        }
    }
    
    func prepareSignInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    deinit {
        if let listener = stateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                try await handleSignInWithAppleResult(.success(authorization))
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let errorMessage: String
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                errorMessage = "使用者取消了登入"
            case .invalidResponse:
                errorMessage = "伺服器回應無效"
            case .notHandled:
                errorMessage = "無法處理此請求"
            case .failed:
                errorMessage = "認證失敗"
            case .notInteractive:
                errorMessage = "認證過程無法互動"
            case .unknown:
                errorMessage = "發生未知錯誤"
            @unknown default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        self.errorMessage = errorMessage
    }
} 
