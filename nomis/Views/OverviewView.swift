import SwiftUI

struct OverviewView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    BalanceCard(
                        balance: viewModel.balance,
                        income: viewModel.totalIncome,
                        expenses: viewModel.totalExpenses
                    )
                    .padding(.horizontal)
                    
                    RecentTransactionsSection(
                        transactions: Array(viewModel.filterTransactions(for: .month).prefix(5))
                    )
                }
                .padding(.vertical)
            }
            .navigationTitle("總覽")
        }
    }
}

struct BalanceCard: View {
    let balance: Double
    let income: Double
    let expenses: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("目前餘額")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(String(format: "%.2f", balance))
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(balance >= 0 ? .green : .red)
            
            HStack(spacing: 40) {
                VStack {
                    Text("收入")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", income))
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                VStack {
                    Text("支出")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f", expenses))
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 5)
    }
}

struct RecentTransactionsSection: View {
    let transactions: [Transaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近交易")
                .font(.headline)
                .padding(.horizontal)
            
            if transactions.isEmpty {
                Text("尚無交易記錄")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                        .padding(.horizontal)
                }
            }
        }
    }
} 