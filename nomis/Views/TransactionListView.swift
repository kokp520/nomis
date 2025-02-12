import SwiftUI
//import nomis.Models.Category
//import nomis.Models.TransactionType

// 導入必要的類型
//@_exported import struct nomis.Category
//@_exported import struct nomis.TransactionType

struct TransactionListView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    
    private var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return viewModel.transactions
        } else {
            return viewModel.transactions.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var groupedTransactions: [Date: [Transaction]] {
        Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                NavigationView {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupedTransactions.keys.sorted().reversed(), id: \.self) { date in
                                Text(dateFormatter.string(from: date))
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal)
                                
                                ForEach(groupedTransactions[date] ?? []) { transaction in
                                    TransactionRowView(transaction: transaction)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                viewModel.deleteTransaction(transaction)
                                            } label: {
                                                Label("刪除", systemImage: "trash")
                                            }
                                        }
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "搜尋交易...")
                    .navigationTitle("交易記錄")
                    .background(Color(.systemGroupedBackground))
                }
            } else {
                LoginView()
            }
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
        .environmentObject(AuthViewModel())
} 
