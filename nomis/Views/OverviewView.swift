import Charts
import FirebaseCore
import SwiftUI
//import nomis.Models.Category
//import nomis.Models.TransactionType

// 導入必要的類型
//@_exported import struct nomis.Category
//@_exported import struct nomis.TransactionType

struct OverviewView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var showingSidebar = false
    @State private var showingCreateGroup = false
    @State private var newGroupName = ""
    @State private var showingICloudAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 主要內容
                ScrollView {
                    VStack(spacing: 20) {
                        // 餘額卡片
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("總餘額")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("$\(String(format: "%.2f", viewModel.balance))")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(viewModel.balance >= 0 ? .green : .red)
                            }
                        }
                        
                        // 收入支出摘要
                        HStack(spacing: 15) {
                            // 收入卡片
                            CardView {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(.green)
                                        Text("收入")
                                            .font(.subheadline)
                                    }
                                    Text("$\(String(format: "%.2f", viewModel.totalIncome))")
                                        .font(.headline)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            // 支出卡片
                            CardView {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(systemName: "arrow.down")
                                            .foregroundColor(.red)
                                        Text("支出")
                                            .font(.subheadline)
                                    }
                                    Text("$\(String(format: "%.2f", viewModel.totalExpenses))")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // 圖表
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("支出分類")
                                    .font(.headline)
                                
                                if #available(iOS 16.0, *) {
                                    Chart {
                                        ForEach(viewModel.categoryExpenses) { item in
                                            SectorMark(
                                                angle: .value("Amount", item.amount),
                                                innerRadius: .ratio(0.618),
                                                angularInset: 1.5
                                            )
                                            .foregroundStyle(by: .value("Category", item.category.rawValue))
                                        }
                                    }
                                    .frame(height: 200)
                                }
                            }
                        }
                        
                        // 最近交易
                        CardView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("最近交易")
                                    .font(.headline)
                                
                                ForEach(Array(viewModel.recentTransactions.prefix(5))) { transaction in
                                    TransactionRowView(transaction: transaction)
                                        .padding(.vertical, 4)
                                    
                                    if transaction.id != viewModel.recentTransactions.prefix(5).last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("總覽")
                .background(Color(.systemGroupedBackground))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingSidebar.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
                
                // 側邊欄
                if showingSidebar {
                    GeometryReader { geometry in
                        HStack {
                            VStack {
                                // 群組列表
                                List {
                                    Section(header: Text("群組")) {
                                        ForEach(firebaseService.groups) { (group: Group) in
                                            Button(action: {
                                                firebaseService.selectGroup(group)
                                                showingSidebar = false
                                            }) {
                                                HStack {
                                                    Text(group.name)
                                                    Spacer()
                                                    if firebaseService.selectedGroup?.id == group.id {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.accentColor)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // 建立群組按鈕
                                Button(action: {
                                    showingCreateGroup = true
                                }) {
                                    Label("建立新群組", systemImage: "plus.circle.fill")
                                }
                                .padding()
                            }
                            .frame(width: min(geometry.size.width * 0.75, 300))
                            .background(Color(.systemBackground))
                            
                            Spacer()
                        }
                        .transition(.move(edge: .leading))
                    }
                    .background(Color.black.opacity(0.3)
                        .onTapGesture {
                            showingSidebar = false
                        }
                    )
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                NavigationView {
                    Form {
                        TextField("群組名稱", text: $newGroupName)
                    }
                    .navigationTitle("建立新群組")
                    .navigationBarItems(
                        leading: Button("取消") {
                            showingCreateGroup = false
                        },
                        trailing: Button("建立") {
                            Task {
                                do {
                                    try await firebaseService.createGroup(name: newGroupName)
                                    showingCreateGroup = false
                                    newGroupName = ""
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                        }
                        .disabled(newGroupName.isEmpty)
                    )
                }
            }
        }
        .task {
            do {
                try await firebaseService.signInAnonymously()
                try await firebaseService.fetchGroups()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        .alert("錯誤", isPresented: $showingError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview("有資料") {
    let viewModel = TransactionViewModel()
    viewModel.transactions = [
        Transaction(title: "午餐", amount: 120, category: .food, type: .expense),
        Transaction(title: "計程車", amount: 250, category: .transport, type: .expense),
        Transaction(title: "薪水", amount: 50000, category: .salary, type: .income),
        Transaction(title: "電影票", amount: 300, category: .entertainment, type: .expense),
        Transaction(title: "投資", amount: 10000, category: .investment, type: .expense)
    ]
    return OverviewView()
        .environmentObject(viewModel)
}

#Preview("無資料") {
    OverviewView()
        .environmentObject(TransactionViewModel())
}
