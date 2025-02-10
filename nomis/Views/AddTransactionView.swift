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
    let isEnter: Bool
    let hasOperator: Bool
    @State private var isPressed = false
    
    init(key: String, action: @escaping (String) -> Void, isEnter: Bool = false, hasOperator: Bool = false) {
        self.key = key
        self.action = action
        self.isEnter = isEnter
        self.hasOperator = hasOperator
    }
    
    var body: some View {
        Button(action: {
            // 觸覺反饋
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            // 延遲重置按壓狀態
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            
            action(key)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.title2)
                } else {
                    Text(key)
                        .font(.title2)
                        .fontWeight(isOperator ? .medium : .regular)
                }
            }
        }
        .frame(width: 80, height: isEnter ? 60 : 55)
        .foregroundColor(foregroundColor)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .buttonStyle(.plain)
    }
    
    private var isOperator: Bool {
        ["÷", "×", "-", "+", "="].contains(key)
    }
    
    private var backgroundColor: Color {
        if isPressed {
            if key == "⌫" {
                return Color(.systemGray4)
            } else if isOperator {
                return .blue.opacity(0.3)
            } else {
                return Color(.systemGray5)
            }
        } else {
            if key == "⌫" {
                return Color(.systemGray5)
            } else if isOperator {
                return .blue.opacity(0.2)
            } else {
                return Color(.systemGray6)
            }
        }
    }
    
    private var foregroundColor: Color {
        if isOperator {
            return isPressed ? .blue.opacity(0.8) : .blue
        } else {
            return isPressed ? .primary.opacity(0.8) : .primary
        }
    }
}

// 數字鍵盤視圖
private struct NumericKeypad: View {
    let onKeyPress: (String) -> Void
    let hasOperator: Bool
    
    private let keys = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        [".", "0", "⌫", "+"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // 分隔線
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal)
            
            // 拖動指示器
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.vertical, 4)
            
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key: key, action: onKeyPress, hasOperator: hasOperator)
                    }
                }
            }
            // Enter/等號 按鈕
            KeypadButton(
                key: hasOperator ? "=" : "↵",
                action: onKeyPress,
                isEnter: true,
                hasOperator: hasOperator
            )
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

// 金額顯示視圖
private struct AmountDisplayView: View {
    let amount: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("TWD")
                    .foregroundColor(.gray)
                Spacer()
                Text(amount.isEmpty ? "0" : amount)
                    .font(.system(size: 40, weight: .regular))
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// 類別選擇器視圖
private struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: Category
    let type: TransactionType
    
    var categories: [Category] {
        switch type {
        case .expense:
            return [.food, .transport, .entertainment, .shopping, .other]
        case .income:
            return [.salary, .investment, .other]
        default:
            return []
        }
    }
    
    var body: some View {
        NavigationView {
            List(categories, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                    dismiss()
                }) {
                    HStack {
                        Text(category.icon)
                        Text(category.rawValue)
                        Spacer()
                        if category == selectedCategory {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("選擇類別")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 詳細資訊視圖
private struct DetailInputView: View {
    @Binding var category: Category
    @Binding var title: String
    @Binding var note: String
    let type: TransactionType
    @State private var showCategoryPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("類別")
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    showCategoryPicker = true
                }) {
                    HStack {
                        Text(category.icon)
                        Text(category.rawValue)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
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
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerView(selectedCategory: $category, type: type)
        }
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
    @State private var showKeypad = false
    @State private var expression = ""
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HeaderView(dismiss: dismiss, onSave: saveTransaction)
                
                Picker("交易類型", selection: $type) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                AmountDisplayView(amount: amount) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showKeypad = true
                        isAmountFocused = true
                    }
                }
                
                ScrollView {
                    DetailInputView(category: $category, title: $title, note: $note, type: type)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showKeypad = false
                                isAmountFocused = false
                            }
                        }
                }
                .padding(.bottom, showKeypad ? 300 : 0)
            }
            .background(Color(.systemGroupedBackground))
            
            if showKeypad {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showKeypad = false
                            isAmountFocused = false
                        }
                    }
                
                NumericKeypad(
                    onKeyPress: handleKeyPress,
                    hasOperator: amount.contains { ["÷", "×", "-", "+"].contains($0) }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .alert("錯誤", isPresented: $showAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text("請填寫標題和有效的金額")
        }
    }
    
    private func handleKeyPress(_ key: String) {
        switch key {
        case "↵", "=":
            if key == "=" {
                calculateResult()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showKeypad = false
                isAmountFocused = false
            }
        case "⌫":
            if !amount.isEmpty {
                amount.removeLast()
            }
        case "C":
            amount = ""
            expression = ""
        case "+", "-", "×", "÷":
            if !amount.isEmpty && !amount.hasSuffix(" \(key) ") {
                expression = amount
                amount += " \(key) "
            }
        case ".":
            let components = amount.components(separatedBy: " ")
            if let lastNumber = components.last, !lastNumber.contains(".") {
                amount += key
            }
        default:
            amount += key
        }
    }
    
    private func calculateResult() {
        let components = amount.components(separatedBy: " ")
        guard components.count == 3,
              let num1 = Double(components[0]),
              let num2 = Double(components[2])
        else {
            return
        }
        
        let result: Double
        switch components[1] {
        case "+": result = num1 + num2
        case "-": result = num1 - num2
        case "×": result = num1 * num2
        case "÷": result = num2 != 0 ? num1 / num2 : 0
        default: return
        }
        
        amount = String(format: "%.2f", result)
        expression = ""
    }
    
    private func saveTransaction() {
        guard !title.isEmpty,
              let amountValue = Double(amount.components(separatedBy: " ").first ?? ""),
              amountValue > 0
        else {
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
