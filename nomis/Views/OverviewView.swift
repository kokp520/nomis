

// 已經經換成home view了 先註解
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

struct OverviewView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var sidebarViewModel: SidebarViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var newGroupName = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                NavigationView {
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
                                sidebarViewModel.showingSidebar.toggle()
                            } label: {
                                Image(systemName: "line.3.horizontal")
                            }
                        }
                    }
                    .onAppear {
                        viewModel.updateCategoryExpenses()
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
