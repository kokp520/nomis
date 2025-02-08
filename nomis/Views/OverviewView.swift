import SwiftUI
import Charts

struct OverviewView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 餘額卡片
                    CardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("總餘額")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("$\(String(format: "%.2f", viewModel.balance))")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(viewModel.balance >= 0 ? .green : .red)
                        }
                    }
                    
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
                                Text("$\(String(format: "%.2f", viewModel.totalIncome))")
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
                                Text("$\(String(format: "%.2f", viewModel.totalExpenses))")
                                    .font(.headline)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // 圖表
                    CardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("支出分類")
                                .font(.headline)
                            
                            if #available(iOS 16.0, *) {
                                Chart {
                                    ForEach(viewModel.categoryExpenses) { item in
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
                    
                    // 最近交易
                    CardView {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("最近交易")
                                .font(.headline)
                            
                            ForEach(Array(viewModel.recentTransactions.prefix(5))) { transaction in
                                TransactionRowView(transaction: transaction)
                                    .padding(.vertical, 4)
                                
                                if transaction.id != viewModel.recentTransactions.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("總覽")
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview("有資料") {
    let viewModel = TransactionViewModel()
    viewModel.transactions = [
        Transaction(title: "午餐", amount: 120, category: .food, type: .expense),
        Transaction(title: "計程車", amount: 250, category: .transport, type: .expense),
        Transaction(title: "薪水", amount: 50000, category: .salary, type: .income),
        Transaction(title: "電影票", amount: 300, category: .entertainment, type: .expense),
        Transaction(title: "投資", amount: 10000, category: .investment, type: .expense)
    ]
    return OverviewView()
        .environmentObject(viewModel)
}

#Preview("無資料") {
    OverviewView()
        .environmentObject(TransactionViewModel())
}
