import SwiftUI

struct SettingsView: View {
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("currency") private var currency: String = "TWD"
    @AppStorage("darkMode") private var isDarkMode: Bool = false
    
    let currencies = ["TWD", "USD", "EUR", "JPY", "CNY"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("個人資料")) {
                    TextField("使用者名稱", text: $userName)
                }
                
                Section(header: Text("顯示設定")) {
                    Picker("貨幣", selection: $currency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    
                    Toggle("深色模式", isOn: $isDarkMode)
                }
                
                Section(header: Text("關於")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
} 