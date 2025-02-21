//
//  HomeView.swift
//  nomis
//
//  Created by adi on 2025/2/21.
//
/*

import SwiftUI

// 交易模型
struct Transaction: Identifiable {
    let id = UUID()
    let amount: Double
    let type: TransactionType
    let date: Date
    let category: String
    let note: String?
}

enum TransactionType {
    case income
    case expense
}

// 貓咪模型
struct Cat: Identifiable {
    let id = UUID()
    var position: CGPoint
    var direction: CGFloat
    var mood: String {
        switch Int.random(in: 0...2) {
            case 0: return "喵！存錢！"
            case 1: return "記帳記帳！"
            default: return "好棒棒！"
        }
    }
}

struct CoinView: View {
    let coins: Int
    let level: Int
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                Text("\(coins)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            Text("Level \(level)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(20)
    }
}

struct TransactionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.title)
                    .foregroundColor(.white)
                Text(title)
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding()
            .background(Color.blue.opacity(0.8))
            .cornerRadius(15)
        }
    }
}

struct HomeView: View {
    @State private var coins = 1000
    @State private var level = 1
    @State private var experience = 0.0
    @State private var cat = Cat(position: CGPoint(x: 200, y: 200), direction: 0)
    @State private var timer: Timer?
    @State private var showingTransactionSheet = false
    @State private var transactions: [Transaction] = []
    @State private var selectedTransactionType: TransactionType = .income
    
    let screenSize = UIScreen.main.bounds.size
    
    var body: some View {
        ZStack {
            // 背景
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 上方狀態欄
                HStack {
                    Spacer()
                    CoinView(coins: coins, level: level)
                }
                .padding()
                
                // 房屋和貓咪區域
                ZStack {
                    // 房屋
                    VStack {
                        Image(systemName: "house.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .foregroundColor(.brown)
                        
                        Rectangle()
                            .fill(Color.green.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                    }
                    
                    // 貓咪
                    VStack {
                        // 對話泡泡
                        Text(cat.mood)
                            .font(.caption)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(10)
                            .offset(y: -40)
                        
                        // 貓咪本體
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 30, height: 30)
                    }
                    .position(cat.position)
                }
                
                // 記帳按鈕
                HStack(spacing: 20) {
                    TransactionButton(title: "收入", systemImage: "plus.circle.fill") {
                        selectedTransactionType = .income
                        showingTransactionSheet = true
                    }
                    
                    TransactionButton(title: "支出", systemImage: "minus.circle.fill") {
                        selectedTransactionType = .expense
                        showingTransactionSheet = true
                    }
                }
                .padding()
                
                // 最近交易記錄
                VStack(alignment: .leading) {
                    Text("最近記錄")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack {
                            ForEach(transactions.prefix(5)) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                    .frame(height: 200)
                }
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .padding()
            }
        }
        .onAppear {
            startCatMovement()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showingTransactionSheet) {
            TransactionSheet(
                isPresented: $showingTransactionSheet,
                type: selectedTransactionType,
                onSave: { amount, category, note in
                    addTransaction(amount: amount, type: selectedTransactionType, category: category, note: note)
                }
            )
        }
    }
    
    private func startCatMovement() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if Double.random(in: 0...1) < 0.02 {
                cat.direction = .random(in: 0...(2 * .pi))
            }
            
            let speed: CGFloat = 2.0
            let newX = cat.position.x + cos(cat.direction) * speed
            let newY = cat.position.y + sin(cat.direction) * speed
            
            let padding: CGFloat = 50
            if newX > padding && newX < screenSize.width - padding &&
               newY > padding && newY < screenSize.height - padding {
                cat.position = CGPoint(x: newX, y: newY)
            } else {
                cat.direction += .pi
            }
        }
    }
    
    private func addTransaction(amount: Double, type: TransactionType, category: String, note: String?) {
        let transaction = Transaction(amount: amount, type: type, date: Date(), category: category, note: note)
        transactions.insert(transaction, at: 0)
        
        // 更新金幣和經驗值
        switch type {
        case .income:
            coins += Int(amount)
            experience += amount * 0.1
        case .expense:
            coins -= Int(amount)
            experience += amount * 0.05
        }
        
        // 檢查升級
        checkLevelUp()
    }
    
    private func checkLevelUp() {
        let experienceNeeded = Double(level * 1000)
        if experience >= experienceNeeded {
            level += 1
            experience -= experienceNeeded
        }
    }
}

struct TransactionSheet: View {
    @Binding var isPresented: Bool
    let type: TransactionType
    let onSave: (Double, String, String?) -> Void
    
    @State private var amount = ""
    @State private var category = ""
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("金額")) {
                    TextField("輸入金額", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("分類")) {
                    TextField("輸入分類", text: $category)
                }
                
                Section(header: Text("備註")) {
                    TextField("輸入備註（選填）", text: $note)
                }
            }
            .navigationTitle(type == .income ? "新增收入" : "新增支出")
            .navigationBarItems(
                leading: Button("取消") { isPresented = false },
                trailing: Button("確定") {
                    if let amountDouble = Double(amount), !category.isEmpty {
                        onSave(amountDouble, category, note.isEmpty ? nil : note)
                        isPresented = false
                    }
                }
            )
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .income ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.type == .income ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(transaction.category)
                    .font(.headline)
                if let note = transaction.note {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(transaction.type == .income ? "+\(Int(transaction.amount))" : "-\(Int(transaction.amount))")
                .foregroundColor(transaction.type == .income ? .green : .red)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    HomeView()
}
*/
