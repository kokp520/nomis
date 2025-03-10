import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text(isSignUp ? "建立帳號" : "登入")
                    .font(.largeTitle)
                    .bold()
                
                if isSignUp {
                    TextField("姓名", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
                
                TextField("電子郵件", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("密碼", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    if isSignUp {
                        authViewModel.signUp(email: email, password: password, name: name)
                    } else {
                        authViewModel.signIn(email: email, password: password)
                    }
                }) {
                    Text(isSignUp ? "註冊" : "登入")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if !isSignUp {
                    Button(action: {
                        authViewModel.prepareSignInWithApple()
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .foregroundColor(.white)
                            Text("使用 Apple 登入")
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                    }
                }
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "已有帳號？登入" : "沒有帳號？註冊")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
        .preferredColorScheme(.light)
        .environmentObject(AuthViewModel())
}

#Preview("深色模式") {
    LoginView()
        .preferredColorScheme(.dark)
        .environmentObject(AuthViewModel())
}
