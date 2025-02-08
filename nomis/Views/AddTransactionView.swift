import SwiftUI

// 頂部標題列視圖
private struct HeaderView: View {
    let dismiss: DismissAction
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            Button("取消") {
                dismiss()
            }
            Spacer()
            Text("新增紀錄")
                .font(.headline)
            Spacer()
            Button("完成") {
                onSave()
            }
        }
        .padding()
    }
}

// 數字鍵盤按鈕
private struct KeypadButton: View {
    let key: String
    let action: (String) -> Void
    
    var body: some View {
        Button(action: { action(key) }) {
            if key == "⌫" {
                Image(systemName: "delete.left")
                    .font(.title2)
            } else {
                Text(key)
                    .font(.title2)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(key == "⌫" ? Color.blue.opacity(0.2) : Color(.systemGray6))
        .foregroundColor(.primary)
    }
}

// 數字鍵盤視圖
private struct NumericKeypad: View {
    let onKeyPress: (String) -> Void
    
    private let keys = [
        ["7", "8", "9", "+"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "×"],
        ["0", ".", "÷", "⌫"]
    ]
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key: key, action: onKeyPress)
                    }
                }
            }
        }
    }
}

// 金額顯示視圖
private struct AmountDisplayView: View {
    let amount: String
    
    var body: some View {
        HStack {
            Text("TWD")
                .foregroundColor(.gray)
            Spacer()
            Text(amount.isEmpty ? "0" : amount)
                .font(.system(size: 40, weight: .regular))
        }
        .padding()
    }
}

// 詳細資訊視圖
private struct DetailInputView: View {
    let category: Category
    @Binding var title: String
    @Binding var note: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("類別")
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    // TODO: 顯示類別選擇器
                }) {
                    Text(category.rawValue)
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            HStack {
                Text("名稱")
                    .foregroundColor(.gray)
                TextField("點擊以編輯", text: $title)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(Color(.systemBackground))
            
            HStack {
                Text("備忘錄")
                    .foregroundColor(.gray)
                TextField("點擊以編輯", text: $note)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .padding(.vertical)
    }
}

struct AddTransactionView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State var category: Category = .food
    @State var type: TransactionType = .expense
    @State private var note = ""
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView(dismiss: dismiss, onSave: saveTransaction)
            
            Picker("交易類型", selection: $type) {
                Text("支出").tag(TransactionType.expense)
                Text("收入").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            AmountDisplayView(amount: amount)
            
            NumericKeypad(onKeyPress: handleKeyPress)
            
            ScrollView {
                DetailInputView(category: category, title: $title, note: $note)
            }
        }
        .background(Color(.systemGroupedBackground))
        .alert("錯誤", isPresented: $showAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text("請填寫標題和有效的金額")
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case "+", "-", "×", "÷":
            // TODO: 處理運算符號
            break
        case ".":
            if !amount.contains(".") {
                amount += key
            }
        default:
            amount += key
        }
    }
    
    private func saveTransaction() {
        guard !title.isEmpty,
              let amountValue = Double(amount),
              amountValue > 0 else {
            showAlert = true
            return
        }
        
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

#Preview("新增支出") {
    AddTransactionView()
        .environmentObject(TransactionViewModel())
}

#Preview("新增收入") {
    let view = AddTransactionView()
    view.type = .income
    view.category = .salary
    return view
        .environmentObject(TransactionViewModel())
} 