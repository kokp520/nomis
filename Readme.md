# Nomis - 優雅的記帳應用 💰

<div align="center">
  <img src="assets/logo.png" alt="Nomis Logo" width="200"/>
  <br>
  <p>
    <strong>簡單、直覺、優雅的個人記帳體驗</strong>
  </p>
</div>

## 🌟 功能特點

- 📱 多群組支援與跨裝置同步
- 💸 收入支出智能追蹤
- 📊 視覺化分析與統計
- 💰 客製化預算管理
- ⚡️ 即時資料同步
- 🔐 安全的 iCloud 整合
- 分類功能新增以及加入（記在group內）

## 🎨 設計理念

### 視覺設計
- 採用現代簡約風格
- 遵循 iOS Human Interface Guidelines
- 支援淺色/深色模式
- 使用自適應佈局

### 色彩系統
```swift
// 主要色彩
static let primary = Color(hex: "#007AFF")
static let secondary = Color(hex: "#5856D6")

// 輔助色彩
static let success = Color(hex: "#34C759")
static let warning = Color(hex: "#FF9500")
static let error = Color(hex: "#FF3B30")
```

### 字體系統
```swift
// 標題字體
static let titleFont = Font.system(size: 28, weight: .bold)
// 副標題字體
static let subtitleFont = Font.system(size: 17, weight: .semibold)
// 內文字體
static let bodyFont = Font.system(size: 15, weight: .regular)
```

## 🛠 技術架構

### 前端技術
- SwiftUI
- 自定義動畫效果
- 響應式設計
- 無障礙支援

### 後端服務
- Firebase (Firestore + Auth)
- CloudKit
- MVVM 架構

## 📱 UI 組件

### 自定義組件
- 圓形進度條
- 自適應卡片視圖
- 動態圖表
- 客製化輸入框

```swift
// 範例：自定義按鈕樣式
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.primary)
                .cornerRadius(12)
        }
    }
}
```

## 🚀 安裝步驟

1. 克隆專案：
```bash
git clone https://github.com/yourusername/nomis.git
cd nomis
```

2. 安裝依賴：
```bash
pod install
```

3. Firebase 設置：
   - 前往 [Firebase Console](https://console.firebase.google.com/)
   - 創建新專案並下載 `GoogleService-Info.plist`
   - 配置 `DatabaseConfig.swift`

4. CloudKit 設置：
   - 在 Xcode 中啟用 iCloud
   - 配置 Container Identifier

## 💻 開發環境

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+
- CocoaPods

## 📖 使用說明

### 首次使用
1. 自動創建匿名帳戶
2. 創建群組或加入現有群組
3. 選擇同步方式

### 記帳功能
1. 點擊 "+" 新增交易
2. 選擇交易類型
3. 填寫詳細資訊
4. 自動同步

## ⚠️ 注意事項

- 需要穩定網路連接
- 建議定期備份
- 注意 Firebase 用量限制
- 確認 iCloud 設定

## 📊 Firebase 限制

| 服務項目 | 免費額度 |
|---------|---------|
| 同時連接 | 100     |
| 存儲空間 | 1GB     |
| 每日下載 | 10GB    |
| 讀取次數 | 50,000/天|
| 寫入次數 | 20,000/天|

## 🤝 貢獻指南

歡迎提交 Pull Request 或建立 Issue。

## 📄 授權協議

MIT License

<div align="center">
  <p>Made with ❤️ by Nomis Team</p>
</div>