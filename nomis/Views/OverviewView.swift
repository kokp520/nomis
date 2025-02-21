import Charts
import FirebaseCore
import SwiftUI

typealias CategoryExpense = TransactionViewModel.CategoryExpense

struct BalanceView: View {
    let balance: Double

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("總餘額")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("$\(String(format: "%.2f", balance))")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(balance >= 0 ? .green : .red)
            }
        }
    }
}

struct IncomeExpenseSummaryView: View {
    let totalIncome: Double
    let totalExpenses: Double

    var body: some View {
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
                    Text("$\(String(format: "%.2f", totalIncome))")
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
                    Text("$\(String(format: "%.2f", totalExpenses))")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct CategoryExpenseView: View {
    let categoryExpenses: [CategoryExpense]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("支出分類")
                    .font(.headline)

                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(categoryExpenses, id: \.category) { item in
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
    }
}

struct RecentTransactionsView: View {
    let recentTransactions: [Transaction]

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("最近交易")
                    .font(.headline)

                ForEach(Array(recentTransactions.prefix(5))) { transaction in
                    TransactionRowView(transaction: transaction)
                        .padding(.vertical, 4)

                    if transaction.id != recentTransactions.prefix(5).last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

struct SidebarView: View {
    @ObservedObject var firebaseService: FirebaseService
    @Binding var showingSidebar: Bool
    @Binding var showingCreateGroup: Bool
    let geometry: GeometryProxy
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: Group?

    var body: some View {
        HStack {
            VStack {
                List {
                    Section(header: Text("群組")) {
                        ForEach(firebaseService.groups) { group in
                            HStack {
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
                                
                                if group.owner == firebaseService.currentUser?.id {
                                    Button(action: {
                                        groupToDelete = group
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }

                Button(action: {
                    showingCreateGroup = true
                }) {
                    Label("建立新群組", systemImage: "plus.circle.fill")
                }
                .padding()
            }
            .frame(width: min(geometry.size.width * 0.75, 300))
            .background(Color(.systemBackground))
            .alert("確定要刪除群組？", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("刪除", role: .destructive) {
                    if let group = groupToDelete {
                        Task {
                            do {
                                try await firebaseService.deleteGroup(group)
                            } catch {
                                print("刪除群組時發生錯誤：\(error)")
                            }
                        }
                    }
                }
            } message: {
                Text("此操作將會刪除群組中的所有交易記錄，且無法復原。")
            }

            Spacer()
        }
        .transition(.move(edge: .leading))
    }
}

struct OverviewView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var showingSidebar = false
    @State private var showingCreateGroup = false
    @State private var newGroupName = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                NavigationView {
                    ZStack {
                        // 主要內容
                        ScrollView {
                            VStack(spacing: 20) {
                                // 餘額卡片
                                BalanceView(balance: viewModel.balance)
                                IncomeExpenseSummaryView(totalIncome: viewModel.totalIncome, totalExpenses: viewModel.totalExpenses)

                                // 圖表
                                CategoryExpenseView(categoryExpenses: viewModel.categoryExpenses)

                                // 最近交易
                                RecentTransactionsView(recentTransactions: viewModel.recentTransactions)
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
                        .onAppear {
                            viewModel.updateCategoryExpenses()
                        }

                        // 側邊欄
                        if showingSidebar {
                            GeometryReader { geometry in
                                SidebarView(
                                    firebaseService: firebaseService,
                                    showingSidebar: $showingSidebar,
                                    showingCreateGroup: $showingCreateGroup,
                                    geometry: geometry
                                )
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
            } else {
                LoginView()
            }
        }
        .task {
            if authViewModel.isAuthenticated {
                do {
                    try await firebaseService.fetchGroups()
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
        .alert("錯誤", isPresented: $showingError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview("測試preview, 有資料") {
    let viewModel = TransactionViewModel()
    viewModel.transactions = [
        Transaction(title: "午餐", amount: 120, category: .food, type: .expense),
        Transaction(title: "計程車", amount: 250, category: .transport, type: .expense),
        Transaction(title: "薪水", amount: 50000, category: .salary, type: .income),
        Transaction(title: "電影票", amount: 300, category: .entertainment, type: .expense),
        Transaction(title: "投資", amount: 10000, category: .investment, type: .expense),
    ]
    return OverviewView()
        .environmentObject(viewModel)
        .environmentObject(AuthViewModel())
}
