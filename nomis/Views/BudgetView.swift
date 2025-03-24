import Charts
import SwiftUI

// TODO: 預算頁面
struct BudgetView: View {
    var body: some View {
        Text("預算頁面").font(.title)
    }
}

//
//// 預算圖表視圖
// struct BudgetChartView: View {
//    let categoryExpenses: [CategoryExpense]
//
//    var body: some View {
//        Chart {
//            ForEach(categoryExpenses) { item in
//                BarMark(
//                    x: .value("Category", item.category.name),
//                    y: .value("Amount", item.amount)
//                )
//                .foregroundStyle(item.category.color)
//            }
//        }
//        .frame(height: 200)
//        .padding()
//        .background(Color(UIColor.systemBackground))
//        .cornerRadius(12)
//    }
// }
//
//// 預算項目視圖
// struct BudgetItemView: View {
//    let category: Category
//    let expense: Double
//
//    var body: some View {
//        HStack {
//            ZStack {
//                Circle()
//                    .fill(category.color.opacity(0.1))
//                    .frame(width: 40, height: 40)
//
//                Text(category.icon)
//                    .font(.title3)
//            }
//
//            VStack(alignment: .leading, spacing: 6) {
//                Text(category.name)
//                    .font(.subheadline)
//                    .foregroundColor(.primary)
//
//                Text("$\(String(format: "%.2f", expense))")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//            }
//
//            Spacer()
//        }
//        .padding()
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(12)
//    }
// }
//
//// 主視圖
// struct BudgetView: View {
//    @EnvironmentObject var viewModel: TransactionViewModel
//    @EnvironmentObject var authViewModel: AuthViewModel
//    @EnvironmentObject var sidebarViewModel: SidebarViewModel
//    @ObservedObject private var firebaseService = FirebaseService.shared
//    @State private var showingAddBudget = false
//    @State private var selectedCategory: Category = .food
//    @State private var budgetAmount = ""
//    @State private var categoryExpenses: [CategoryExpense] = []
//
//    var body: some View {
//        SwiftUI.Group {
//            if authViewModel.isAuthenticated {
//                NavigationView {
//                    ScrollView {
//                        VStack(spacing: 20) {
//                            // 預算圖表
//                            BudgetChartView(categoryExpenses: categoryExpenses)
//
//                            // 預算列表
//                            ForEach(Category.defaultCategories) { category in
//                                BudgetItemView(
//                                    category: category,
//                                    expense: viewModel.categoryExpenses.first(where: { $0.category == category })?.amount ?? 0
//                                )
//                            }
//                        }
//                        .padding()
//                    }
//                    .navigationTitle("預算")
//                    .background(Color(.systemGroupedBackground))
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarLeading) {
//                            Button {
//                                sidebarViewModel.showingSidebar.toggle()
//                            } label: {
//                                Image(systemName: "line.3.horizontal")
//                            }
//                        }
//                    }
//                }
//                .sheet(isPresented: $showingAddBudget) {
//                    NavigationView {
//                        Form {
//                            Section {
//                                TextField("預算金額", text: $budgetAmount)
//                                    .keyboardType(.decimalPad)
//                            }
//                        }
//                        .navigationTitle("設定預算")
//                        .navigationBarItems(
//                            leading: Button("取消") {
//                                showingAddBudget = false
//                            },
//                            trailing: Button("儲存") {
//                                if let amount = Double(budgetAmount) {
//                                    // TODO: 儲存預算
//                                    print("設定 \(selectedCategory.name) 預算為 \(amount)")
//                                }
//                                showingAddBudget = false
//                            }
//                            .disabled(budgetAmount.isEmpty)
//                        )
//                    }
//                }
//            } else {
//                LoginView()
//            }
//        }
//        .onAppear {
//            loadCategoryExpenses()
//        }
//    }
//
//    private func loadCategoryExpenses() {
//        // 創建測試數據，實際應用中應從交易中計算
//        let foodCategory = Category(name: "餐飲", icon: "🍔", color: .blue)
//        let transportCategory = Category(name: "交通", icon: "🚗", color: .green)
//        let entertainmentCategory = Category(name: "娛樂", icon: "🎬", color: .purple)
//        let housingCategory = Category(name: "住房", icon: "🏠", color: .orange)
//
//        categoryExpenses = [
//            CategoryExpense(category: foodCategory, amount: 5000),
//            CategoryExpense(category: transportCategory, amount: 3000),
//            CategoryExpense(category: entertainmentCategory, amount: 2500),
//            CategoryExpense(category: housingCategory, amount: 8000)
//        ]
//    }
// }
//
// #Preview("有預算資料") {
//    let viewModel = TransactionViewModel()
//    viewModel.transactions = [
//        Transaction(title: "午餐", amount: 120, category: .food, type: .expense),
//        Transaction(title: "計程車", amount: 250, category: .transport, type: .expense),
//        Transaction(title: "電影票", amount: 300, category: .entertainment, type: .expense),
//        Transaction(title: "購物", amount: 1500, category: .shopping, type: .expense)
//    ]
//    // 設定一些預算
//    viewModel.setBudget(3000, for: .food)
//    viewModel.setBudget(2000, for: .transport)
//    viewModel.setBudget(1000, for: .entertainment)
//
//    return BudgetView()
//        .environmentObject(viewModel)
//        .environmentObject(AuthViewModel())
//        .environmentObject(SidebarViewModel.shared)
// }
//
// #Preview("無資料") {
//    BudgetView()
//        .environmentObject(TransactionViewModel())
//        .environmentObject(AuthViewModel())
//        .environmentObject(SidebarViewModel.shared)
// }
