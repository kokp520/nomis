import SwiftUI

struct BinMainView: View {
    @StateObject private var authService = BinAuthService()
    
    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                // 登入後的主畫面
                NavigationView {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let user = authService.user {
                                // 用戶資訊區
                                GroupBox("用戶資訊") {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("歡迎回來，\(user.name)！")
                                            .font(.title2)
                                        
                                        Text("電子郵件：\(user.email)")
                                            .font(.subheadline)
                                        
                                        if let createdAt = user.createdAt {
                                            Text("加入時間：\(createdAt.formatted())")
                                                .font(.subheadline)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                }
                                
                                // Firebase 測試區域
                                GroupBox("Firebase 測試") {
                                    VStack(spacing: 15) {
                                        // 環境切換
                                        GroupBox("環境設定") {
                                            VStack(spacing: 10) {
                                                HStack {
                                                    Image(systemName: authService.isUsingEmulator ? "laptopcomputer" : "globe")
                                                        .foregroundColor(authService.isUsingEmulator ? .orange : .blue)
                                                    Text(authService.isUsingEmulator ? "模擬器環境" : "線上環境")
                                                        .foregroundColor(authService.isUsingEmulator ? .orange : .blue)
                                                }
                                                
                                                Button(action: {
                                                    authService.toggleEnvironment()
                                                }) {
                                                    Text("切換到" + (authService.isUsingEmulator ? "線上環境" : "模擬器環境"))
                                                        .frame(maxWidth: .infinity)
                                                }
                                                .buttonStyle(.bordered)
                                                .tint(authService.isUsingEmulator ? .blue : .orange)
                                            }
                                        }
                                        
                                        // 連接測試
                                        GroupBox("連接測試") {
                                            Button("測試 Firebase 連接") {
                                                authService.testFirebaseConnection()
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                        
                                        // 認證測試
                                        GroupBox("認證測試") {
                                            VStack(spacing: 10) {
                                                Button("查看認證狀態") {
                                                    authService.printAuthState()
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                Button("重新載入用戶資料") {
                                                    Task {
                                                        try? await authService.reloadUser()
                                                    }
                                                }
                                                .buttonStyle(.bordered)
                                            }
                                        }
                                        
                                        // 資料監聽測試
                                        GroupBox("資料監聽") {
                                            VStack(spacing: 10) {
                                                Button("監聽用戶資料變化") {
                                                    authService.listenToUserChanges(userId: user.id)
                                                }
                                                .buttonStyle(.bordered)
                                                
                                                Button("查看用戶資料") {
                                                    Task {
                                                        await authService.printUserData(userId: user.id)
                                                    }
                                                }
                                                .buttonStyle(.bordered)
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                            
                            // 登出按鈕
                            Button(action: {
                                try? authService.signOut()
                            }) {
                                Text("登出")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                    .navigationTitle("Firebase 模擬器測試")
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                // 登入頁面
                BinAuthView()
            }
        }
    }
}

#Preview {
    BinMainView()
} 