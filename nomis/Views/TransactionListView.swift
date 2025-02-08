import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @State private var searchText = ""
    
    var filteredTransactions: [Transaction] {
        let periodFilteredTransactions = viewModel.filterTransactions(for: viewModel.selectedPeriod)
        if searchText.isEmpty {
            return periodFilteredTransactions
        }
        return periodFilteredTransactions.filter { transaction in
            transaction.title.localizedCaseInsensitiveContains(searchText) ||
            transaction.category.rawValue.localizedCaseInsensitiveContains(searchText) ||
            String(format: "%.2f", transaction.amount).contains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    Picker("期間", selection: $viewModel.selectedPeriod) {
                        Text("週").tag(TransactionViewModel.DatePeriod.week)
                        Text("月").tag(TransactionViewModel.DatePeriod.month)
                        Text("年").tag(TransactionViewModel.DatePeriod.year)
                        Text("全部").tag(TransactionViewModel.DatePeriod.all)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    ForEach(filteredTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTransaction(transaction)
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "搜尋交易...")
            .navigationTitle("交易記錄")
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    let viewModel = TransactionViewModel()
    viewModel.transactions = [
        Transaction(title: "午餐", amount: 120, category: .food, type: .expense),
        Transaction(title: "計程車", amount: 250, category: .transport, type: .expense),
        Transaction(title: "薪水", amount: 50000, category: .salary, type: .income),
        Transaction(title: "電影票", amount: 300, category: .entertainment, type: .expense)
    ]
    
    return TransactionListView()
        .environmentObject(viewModel)
} 