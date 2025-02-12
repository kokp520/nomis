import SwiftUI
import FirebaseAuth
import AuthenticationServices

@MainActor
class AuthViewModel: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    private let firebaseService: FirebaseService
    private var stateListener: AuthStateDidChangeListenerHandle?
    
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
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                let userData = User(id: result.user.uid, name: name, email: email)
                try await firebaseService.createUser(user: userData)
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
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
    
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self
        authController.performRequests()
    }
    
    deinit {
        if let listener = stateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

extension AuthViewModel: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
           let appleIDToken = appleIDCredential.identityToken,
           let idTokenString = String(data: appleIDToken, encoding: .utf8) {
            
            Task {
                do {
                    let credential = OAuthProvider.credential(
                        withProviderID: "apple.com",
                        idToken: idTokenString,
                        rawNonce: ""
                    )
                    
                    let result = try await Auth.auth().signIn(with: credential)
                    let userData = User(
                        id: result.user.uid,
                        name: appleIDCredential.fullName?.givenName ?? "User",
                        email: appleIDCredential.email ?? ""
                    )
                    try await firebaseService.createUser(user: userData)
                } catch {
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
    }
} 