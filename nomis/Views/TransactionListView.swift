import SwiftUI

// 交易項目視圖
struct TransactionItemView: View {
    let transaction: Transaction
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // 類別圖示
                Text(transaction.category.icon)
                    .font(.title3)
                    .padding(8)
                    .background(transaction.category.color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(transaction.title)
                        .font(.headline)
                    Text(transaction.category.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(transaction.type == .expense ? "-\(transaction.amount)" : "+\(transaction.amount)")
                        .font(.headline)
                        .foregroundColor(transaction.type == .expense ? .red : .green)
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.95 : 1.0)
    }
}

// 交易選項表單視圖
struct TransactionOptionsView: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("交易選項")
                .font(.headline)
                .padding()
            
            Divider()
            
            Button(action: onEdit) {
                Label("編輯", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .padding()
            
            Divider()
            
            Button(action: onDelete) {
                Label("刪除", systemImage: "trash")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
            }
            .padding()
            
            Divider()
            
            Button(action: onDismiss) {
                Text("取消")
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .presentationDetents([.height(250)])
    }
}

struct TransactionListView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var sidebarViewModel: SidebarViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var searchText = ""
    @State private var selectedTransaction: Transaction?
    @State private var showingOptions = false
    @State private var showingEditSheet = false
    @State private var isSelected = false
    
    private var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return viewModel.transactions
        } else {
            return viewModel.transactions.filter { transaction in
                transaction.title.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.name.localizedCaseInsensitiveContains(searchText)
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
                                    TransactionItemView(
                                        transaction: transaction,
                                        isSelected: selectedTransaction?.id == transaction.id && isSelected,
                                        onSelect: {
                                            selectedTransaction = transaction
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                isSelected = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    isSelected = false
                                                    showingOptions = true
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .navigationTitle("交易記錄")
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
                    .searchable(text: $searchText, prompt: "搜尋交易...")
                }
                .sheet(isPresented: $showingOptions) {
                    TransactionOptionsView(
                        onEdit: {
                            showingOptions = false
                            showingEditSheet = true
                        },
                        onDelete: {
                            if let transaction = selectedTransaction {
                                viewModel.deleteTransaction(transaction)
                            }
                            showingOptions = false
                        },
                        onDismiss: {
                            showingOptions = false
                        }
                    )
                }
                .sheet(isPresented: $showingEditSheet) {
                    if let transaction = selectedTransaction {
                        NavigationView {
                            AddTransactionView(
                                isPresented: $showingEditSheet,
                                type: transaction.type,
                                editingTransaction: transaction
                            )
                        }
                    }
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
        .environmentObject(SidebarViewModel.shared)
} 
