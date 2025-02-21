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
                                    Button(action: {
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
                                    }) {
                                        HStack {
                                            // 類別圖示
                                            Text(transaction.category.icon)
                                                .font(.title3)
                                                .padding(8)
                                                .background(
                                                    Circle()
                                                        .fill(Color.blue.opacity(0.1))
                                                )
                                            
                                            // 標題和備註
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(transaction.title)
                                                    .foregroundColor(.primary)
                                                if let note = transaction.note {
                                                    Text(note)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // 金額
                                            Text("$\(String(format: "%.2f", transaction.amount))")
                                                .foregroundColor(transaction.type == .income ? .green : .red)
                                                .font(.headline)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        .scaleEffect(selectedTransaction?.id == transaction.id && isSelected ? 0.95 : 1.0)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "搜尋交易...")
                    .navigationTitle("交易記錄")
                    .background(Color(.systemGroupedBackground))
                    .sheet(isPresented: $showingOptions) {
                        VStack(spacing: 0) {
                            Text("交易選項")
                                .font(.headline)
                                .padding()
                            
                            Divider()
                            
                            Button(action: {
                                showingOptions = false
                                showingEditSheet = true
                            }) {
                                Label("編輯", systemImage: "pencil")
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                if let transaction = selectedTransaction {
                                    Task {
                                        do {
                                            try await FirebaseService.shared.deleteTransaction(transaction)
                                            viewModel.deleteTransaction(transaction)
                                            showingOptions = false
                                        } catch {
                                            print("刪除交易時發生錯誤：\(error)")
                                        }
                                    }
                                }
                            } label: {
                                Label("刪除", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                            
                            Divider()
                            
                            Button(action: {
                                showingOptions = false
                            }) {
                                Text("取消")
                                    .foregroundColor(.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(Color(.systemBackground))
                        .presentationDetents([.height(250)])
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
                }
            } else {
                LoginView()
            }
        }
    }
}

/*
struct EditTransactionView: View {
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: TransactionViewModel
    @State private var title: String
    @State private var amount: String
    @State private var category: Category
    @State private var date: Date
    @State private var note: String
    
    init(transaction: Transaction) {
        self.transaction = transaction
        _title = State(initialValue: transaction.title)
        _amount = State(initialValue: String(format: "%.2f", transaction.amount))
        _category = State(initialValue: transaction.category)
        _date = State(initialValue: transaction.date)
        _note = State(initialValue: transaction.note ?? "")
    }
    
    var body: some View {
        List {
            Group {
                HStack {
                    Text("標題")
                    Spacer()
                    TextField("請輸入標題", text: $title)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("金額")
                    Spacer()
                    TextField("請輸入金額", text: $amount)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                
                HStack {
                    Text("類別")
                    Spacer()
                    Picker("", selection: $category) {
                        ForEach(transaction.type == .income ? Category.incomeCategories : Category.expenseCategories, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                
                HStack {
                    Text("備註")
                    Spacer()
                    TextField("選填", text: $note)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("編輯交易")
        .navigationBarItems(
            leading: Button("取消") {
                dismiss()
            },
            trailing: Button("儲存") {
                saveTransaction()
            }
        )
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let updatedTransaction = Transaction(
            id: transaction.id,
            title: title,
            amount: amountValue,
            date: date,
            category: category,
            type: transaction.type,
            note: note.isEmpty ? nil : note
        )
        
        Task {
            do {
                try await FirebaseService.shared.updateTransaction(updatedTransaction)
                viewModel.updateTransaction(updatedTransaction)
                dismiss()
            } catch {
                print("更新交易時發生錯誤：\(error)")
            }
        }
    }
}
*/

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
