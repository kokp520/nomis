import SwiftUI
//import nomis.Models.Category
//import nomis.Models.TransactionType

// 導入必要的類型
//@_exported import struct nomis.Category
//@_exported import struct nomis.TransactionType

struct TransactionListView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @State private var searchText = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter
    }()
    
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

                    // group by year and month
                    let groupedTransactions = Dictionary(grouping: filteredTransactions) { transaction in
                        let components = Calendar.current.dateComponents([.year, .month], from: transaction.date)
                        return Calendar.current.date(from: components)!
                    }
                    ForEach(groupedTransactions.keys.sorted().reversed(), id: \.self){ date in 
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
