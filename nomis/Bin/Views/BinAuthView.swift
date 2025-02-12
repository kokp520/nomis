import SwiftUI
import AuthenticationServices

struct BinAuthView: View {
    @StateObject private var authService = BinAuthService()
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showResetPassword = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Logo
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top, 50)
                    
                    // 標題
                    Text(isSignUp ? "建立帳號" : "登入")
                        .font(.largeTitle)
                        .bold()
                    
                    // 輸入表單
                    VStack(spacing: 15) {
                        if isSignUp {
                            TextField("姓名", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .padding(.horizontal)
                        }
                        
                        TextField("電子郵件", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(.horizontal)
                        
                        SecureField("密碼", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding(.horizontal)
                    }
                    
                    // 錯誤訊息
                    if let error = authService.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // 主要按鈕
                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                if isSignUp {
                                    try await authService.signUp(email: email, password: password, name: name)
                                } else {
                                    try await authService.signIn(email: email, password: password)
                                }
                            } catch {
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                            isLoading = false
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSignUp ? "註冊" : "登入")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(isLoading)
                    
                    // 分隔線
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("或")
                            .foregroundColor(.gray)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .padding(.horizontal)
                    
                    // Apple 登入按鈕
                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                try await authService.signInWithApple()
                            } catch {
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                            isLoading = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("使用 Apple 登入")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(isLoading)
                    
                    // 切換註冊/登入
                    Button(action: {
                        isSignUp.toggle()
                        authService.errorMessage = nil
                    }) {
                        Text(isSignUp ? "已有帳號？登入" : "沒有帳號？註冊")
                            .foregroundColor(.blue)
                    }
                    
                    // 忘記密碼
                    if !isSignUp {
                        Button(action: {
                            showResetPassword = true
                        }) {
                            Text("忘記密碼？")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical)
            }
            .alert("錯誤", isPresented: $showAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .alert("重設密碼", isPresented: $showResetPassword) {
                TextField("電子郵件", text: $email)
                Button("取消", role: .cancel) {}
                Button("送出") {
                    Task {
                        do {
                            try await authService.resetPassword(email: email)
                            alertMessage = "重設密碼連結已發送到您的信箱"
                            showAlert = true
                        } catch {
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                }
            } message: {
                Text("請輸入您的電子郵件，我們將發送重設密碼的連結給您。")
            }
        }
    }
}

#Preview {
    BinAuthView()
} 
 
