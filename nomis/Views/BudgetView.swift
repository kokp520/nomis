import SwiftUI
import Charts
//import nomis.Models.Category
//import nomis.Models.TransactionType

// 導入必要的類型
//@_exported import struct nomis.Category
//@_exported import struct nomis.TransactionType

// 預算圖表視圖
struct BudgetChartView: View {
    let categoryExpenses: [CategoryExpense]
    
    var body: some View {
        Chart {
            ForEach(categoryExpenses) { item in
                BarMark(
                    x: .value("Category", item.category.rawValue),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(item.category.color)
            }
        }
        .frame(height: 200)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// 預算項目視圖
struct BudgetItemView: View {
    let category: Category
    let expense: Double
    let onAddBudget: () -> Void
    
    var body: some View {
        HStack {
            Text(category.icon)
                .font(.title2)
                .padding(8)
                .background(category.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(category.rawValue)
                    .font(.headline)
                Text("已使用：\(expense, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onAddBudget) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// 主視圖
struct BudgetView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var sidebarViewModel: SidebarViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var showingAddBudget = false
    @State private var selectedCategory: Category = .food
    @State private var budgetAmount = ""
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                NavigationView {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 預算圖表
                            BudgetChartView(categoryExpenses: viewModel.categoryExpenses)
                            
                            // 預算列表
                            ForEach(Category.allCases, id: \.self) { category in
                                BudgetItemView(
                                    category: category,
                                    expense: viewModel.categoryExpenses.first(where: { $0.category == category })?.amount ?? 0,
                                    onAddBudget: {
                                        selectedCategory = category
                                        showingAddBudget = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("預算")
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
                }
                .sheet(isPresented: $showingAddBudget) {
                    NavigationView {
                        Form {
                            Section {
                                TextField("預算金額", text: $budgetAmount)
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .navigationTitle("設定預算")
                        .navigationBarItems(
                            leading: Button("取消") {
                                showingAddBudget = false
                            },
                            trailing: Button("儲存") {
                                if let amount = Double(budgetAmount) {
                                    // TODO: 儲存預算
                                    print("設定 \(selectedCategory.rawValue) 預算為 \(amount)")
                                }
                                showingAddBudget = false
                            }
                            .disabled(budgetAmount.isEmpty)
                        )
                    }
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview("有預算資料") {
    let viewModel = TransactionViewModel()
    viewModel.transactions = [
        Transaction(title: "午餐", amount: 120, category: .food, type: .expense),
        Transaction(title: "計程車", amount: 250, category: .transport, type: .expense),
        Transaction(title: "電影票", amount: 300, category: .entertainment, type: .expense),
        Transaction(title: "購物", amount: 1500, category: .shopping, type: .expense)
    ]
    // 設定一些預算
    viewModel.setBudget(3000, for: .food)
    viewModel.setBudget(2000, for: .transport)
    viewModel.setBudget(1000, for: .entertainment)
    
    return BudgetView()
        .environmentObject(viewModel)
        .environmentObject(AuthViewModel())
        .environmentObject(SidebarViewModel.shared)
}

#Preview("無資料") {
    BudgetView()
        .environmentObject(TransactionViewModel())
        .environmentObject(AuthViewModel())
        .environmentObject(SidebarViewModel.shared)
} 
