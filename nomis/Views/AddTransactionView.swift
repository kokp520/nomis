import SwiftUI

struct AddTransactionView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var type: TransactionType = .expense
    @State private var category: Category = .other
    @State private var note: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("交易類型")) {
                    Picker("類型", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("基本資訊")) {
                    TextField("標題", text: $title)
                    TextField("金額", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("分類")) {
                    Picker("分類", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
                Section(header: Text("備註")) {
                    TextEditor(text: $note)
                        .frame(height: 100)
                }
            }
            .navigationTitle("新增交易")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("儲存") {
                    saveTransaction()
                }
                .disabled(title.isEmpty || amount.isEmpty)
            )
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(
            title: title,
            amount: amountValue,
            date: date,
            category: category,
            type: type,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.addTransaction(transaction)
        dismiss()
    }
} 