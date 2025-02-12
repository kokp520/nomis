import SwiftUI
import Charts
//import nomis.Models.Category
//import nomis.Models.TransactionType

// 導入必要的類型
//@_exported import struct nomis.Category
//@_exported import struct nomis.TransactionType

struct BudgetView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingAddBudget = false
    @State private var selectedCategory: Category = .food
    @State private var budgetAmount = ""
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                NavigationView {
                    List {
                        Section {
                            HStack {
                                Text("本月總支出")
                                Spacer()
                                Text("$\(String(format: "%.2f", viewModel.totalExpenses))")
                                    .foregroundColor(.red)
                            }
                            
                            if #available(iOS 16.0, *) {
                                Chart(viewModel.categoryExpenses, id: \.category) { item in
                                    BarMark(
                                        x: .value("Category", item.category.rawValue),
                                        y: .value("Amount", item.amount)
                                    )
                                    .foregroundStyle(by: .value("Category", item.category.rawValue))
                                }
                                .frame(height: 200)
                                .padding(.vertical)
                            }
                        }
                        
                        Section("分類預算") {
                            ForEach(Category.allCases.filter { $0 != .salary && $0 != .investment }, id: \.self) { category in
                                HStack {
                                    Text(category.icon)
                                    Text(category.rawValue)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("$\(String(format: "%.2f", viewModel.expenses(for: category)))")
                                            .foregroundColor(.red)
                                        if let budget = viewModel.budget(for: category) {
                                            Text("預算: $\(String(format: "%.2f", budget))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCategory = category
                                    if let budget = viewModel.budget(for: category) {
                                        budgetAmount = String(format: "%.2f", budget)
                                    } else {
                                        budgetAmount = ""
                                    }
                                    showingAddBudget = true
                                }
                            }
                        }
                    }
                    .navigationTitle("預算")
                    .sheet(isPresented: $showingAddBudget) {
                        NavigationView {
                            Form {
                                Section {
                                    HStack {
                                        Text(selectedCategory.icon)
                                        Text(selectedCategory.rawValue)
                                    }
                                    
                                    HStack {
                                        Text("$")
                                        TextField("預算金額", text: $budgetAmount)
                                            .keyboardType(.decimalPad)
                                    }
                                }
                            }
                            .navigationTitle("設定預算")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("取消") {
                                        showingAddBudget = false
                                    }
                                }
                                
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("儲存") {
                                        if let amount = Double(budgetAmount) {
                                            viewModel.setBudget(amount, for: selectedCategory)
                                        }
                                        showingAddBudget = false
                                    }
                                }
                            }
                        }
                        .presentationDetents([.height(250)])
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
}

#Preview("無資料") {
    BudgetView()
        .environmentObject(TransactionViewModel())
        .environmentObject(AuthViewModel())
} 
