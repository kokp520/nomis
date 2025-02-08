import SwiftUI

struct BudgetView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("本月支出")) {
                    ForEach(Category.allCases, id: \.self) { category in
                        CategoryBudgetRow(
                            category: category,
                            amount: categoryExpenses(for: category)
                        )
                    }
                }
            }
            .navigationTitle("預算")
        }
    }
    
    private func categoryExpenses(for category: Category) -> Double {
        viewModel.filterTransactions(for: .month)
            .filter { $0.type == .expense && $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
}

struct CategoryBudgetRow: View {
    let category: Category
    let amount: Double
    
    var body: some View {
        HStack {
            Label(category.rawValue, systemImage: category.icon)
            Spacer()
            Text(String(format: "%.2f", amount))
                .foregroundColor(.red)
        }
    }
} 