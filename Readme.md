# Nomis - 記帳應用

一個簡單易用的記帳應用，使用 Firebase 和 CloudKit 作為後端服務。

## 功能特點

- 多群組支援
- 收入支出追蹤
- 分類統計
- 預算管理
- 跨裝置即時同步
- iCloud 同步支援

## 技術架構

- SwiftUI
- Firebase (Firestore + Auth)
- CloudKit
- MVVM 架構

## 安裝步驟

1. 克隆專案：
```bash
git clone https://github.com/yourusername/nomis.git
cd nomis
```

2. 安裝依賴：
   - 使用 CocoaPods 安裝依賴
   - 在專案根目錄執行：
```bash
pod install
```
   - 開啟 `.xcworkspace` 檔案（不是 `.xcodeproj`）

3. Firebase 設置：
   - 前往 [Firebase Console](https://console.firebase.google.com/)
   - 創建新專案
   - 添加 iOS 應用
   - 下載 `GoogleService-Info.plist`
   - 將設定值複製到 `DatabaseConfig.swift`

4. CloudKit 設置：
   - 在 Xcode 中啟用 iCloud 功能
   - 設定適當的 Container Identifier
   - 確保已配置正確的 Capabilities

5. 修改設定：
   - 打開 `DatabaseConfig.swift`
   - 填入您的 Firebase 設定值
   - 配置 CloudKit 相關設定

## 開發環境設置

1. 開發環境：
   - Xcode 15.0+
   - iOS 16.0+
   - Swift 5.9+

2. 後端服務設定：
   - Firebase：配置開發和生產環境
   - CloudKit：設定開發和生產容器

## 使用說明

1. 首次使用：
   - 應用會自動創建匿名帳戶
   - 可以創建新群組或加入現有群組
   - 可選擇使用 iCloud 帳號同步

2. 記帳功能：
   - 點擊 "+" 添加新交易
   - 選擇收入或支出
   - 填寫金額和分類
   - 自動同步到雲端

3. 群組管理：
   - 點擊左上角選單
   - 可以創建或切換群組
   - 群組內容即時同步

## 注意事項

- 請確保有穩定的網路連接
- 建議定期備份重要數據
- 注意 Firebase 免費額度的使用限制
- 確保 iCloud 帳號已正確設定

## Firebase 免費額度

- 同時連接數：100
- 存儲空間：1GB
- 每日下載量：10GB
- 文檔讀取：50,000/天
- 文檔寫入：20,000/天

## 貢獻指南

歡迎提交 Pull Request 或提出 Issue。

## 授權協議

MIT License