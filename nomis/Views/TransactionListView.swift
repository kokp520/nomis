import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filterTransactions(for: viewModel.selectedPeriod)) { transaction in
                    TransactionRow(transaction: transaction)
                }
                .onDelete(perform: deleteTransaction)
            }
            .navigationTitle("交易記錄")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("期間", selection: $viewModel.selectedPeriod) {
                        Text("週").tag(TransactionViewModel.DatePeriod.week)
                        Text("月").tag(TransactionViewModel.DatePeriod.month)
                        Text("年").tag(TransactionViewModel.DatePeriod.year)
                        Text("全部").tag(TransactionViewModel.DatePeriod.all)
                    }
                }
            }
        }
    }
    
    private func deleteTransaction(at offsets: IndexSet) {
        let transactions = viewModel.filterTransactions(for: viewModel.selectedPeriod)
        offsets.forEach { index in
            viewModel.deleteTransaction(transactions[index])
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(transaction.title)
                    .font(.headline)
                Text(transaction.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "%.2f", transaction.amount))
                    .font(.headline)
                    .foregroundColor(transaction.type == .income ? .green : .red)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
} 