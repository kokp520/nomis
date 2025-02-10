import SwiftUI

// 頂部標題列視圖
private struct HeaderView: View {
    let dismiss: () -> Void
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
    @Binding var selectedDate: Date
    @State private var showDatePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text("TWD")
                        .foregroundColor(.adaptiveText)
                        .font(.system(size: 40))
                        .bold()
                    Spacer()
                    Text(amount.isEmpty ? "0" : amount)
                        .font(.system(size: 40, weight: .regular))
                        .foregroundColor(.adaptiveText)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.horizontal)
            
            HStack {
                Spacer()
                Button(action: {
                    showDatePicker.toggle()
                }) {
                    HStack(spacing: 4) {
                        Text(formatDate(selectedDate))
                            .foregroundColor(.adaptiveSecondaryText)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.adaptiveSecondaryText)
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color.adaptiveBackground)
        .sheet(isPresented: $showDatePicker) {
            DatePickerView(selectedDate: $selectedDate, isPresented: $showDatePicker)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "今天 " + formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日 HH:mm"
            return formatter.string(from: date)
        }
    }
}

// 日期選擇器視圖
private struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            DatePicker("選擇日期", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.wheel)
                .labelsHidden()
                .navigationTitle("選擇日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            isPresented = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("確定") {
                            isPresented = false
                        }
                    }
                }
        }
    }
}

// 類別選擇器視圖
private struct CategoryPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCategory: Category
    @Binding var title: String
    let type: TransactionType
    @EnvironmentObject var viewModel: TransactionViewModel
    
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
        VStack(spacing: 0) {
            // 類別網格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(category == selectedCategory ? Color.blue.opacity(0.2) : Color.adaptiveBackground)
                                    .frame(width: 60, height: 60)
                                
                                Text(category.icon)
                                    .font(.title2)
                            }
                            
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(.adaptiveText)
                        }
                    }
                }
            }
            .padding()
            
            // 取消按鈕
            Button(action: {
                dismiss()
            }) {
                Text("取消")
                    .foregroundColor(.adaptiveText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.adaptiveBackground)
                    .cornerRadius(12)
            }
            .padding()
        }
        .background(Color.adaptiveGroupedBackground)
        .presentationDetents([.height(300)])
    }
}

// 詳細資訊視圖
private struct DetailInputView: View {
    @Binding var category: Category
    @Binding var title: String
    @Binding var note: String
    let type: TransactionType
    @State private var showCategoryPicker = false
    @State private var isEditingTitle = false
    @EnvironmentObject var viewModel: TransactionViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("類別")
                    .foregroundColor(.adaptiveText)
                    .frame(width: 60, alignment: .leading)
                Spacer()
                Button(action: {
                    showCategoryPicker = true
                }) {
                    HStack {
                        Text(category.rawValue)
                            .foregroundColor(.adaptiveText)
                        Spacer()
                        Text(category.icon)
                            .foregroundColor(.adaptiveText)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                }
            }
            .padding()
            .background(Color.adaptiveBackground)
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $category, title: $title, type: type)
            }
            
            VStack(spacing: 0) {
                HStack {
                    Text("名稱")
                        .foregroundColor(.adaptiveText)
                        .frame(width: 60, alignment: .leading)
                    TextField("點擊以編輯", text: $title, onEditingChanged: { editing in
                        isEditingTitle = editing
                    })
                        .multilineTextAlignment(.leading)
                        .foregroundColor(title.isEmpty ? .adaptiveSecondaryText : .adaptiveText)
                }
                .padding()
                .background(Color.adaptiveBackground)
                
                if isEditingTitle {
                    VStack(spacing: 8) {
                        Text("最近使用")
                            .font(.caption)
                            .foregroundColor(.adaptiveSecondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        let recentTitles = viewModel.getRecentTitles(for: category)
                        if !recentTitles.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(recentTitles, id: \.self) { historyTitle in
                                        Button(action: {
                                            title = historyTitle
                                            isEditingTitle = false
                                        }) {
                                            HStack(spacing: 4) {
                                                Text(category.icon)
                                                    .font(.subheadline)
                                                Text(historyTitle)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(16)
                                        }
                                        .foregroundColor(.adaptiveText)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color.adaptiveBackground.opacity(0.5))
                }
            }
            
            HStack {
                Text("備忘錄")
                    .foregroundColor(.adaptiveText)
                    .frame(width: 60, alignment: .leading)
                TextField("點擊以編輯", text: $note)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(note.isEmpty ? .adaptiveSecondaryText : .adaptiveText)
            }
            .padding()
            .background(Color.adaptiveBackground)
        }
        .padding(.vertical)
    }
}

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: TransactionViewModel
    @State var amount = ""
    @State var category: Category = .food
    @State var title = ""
    @State var note = ""
    @State var showKeypad = false
    @State var isAmountFocused = false
    @State var selectedDate = Date()
    @State var showAlert = false
    @State var expression = ""
    let type: TransactionType
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HeaderView(dismiss: {
                    isPresented = false
                }, onSave: {
                    saveTransaction()
                    isPresented = false
                })
                
                Text(type == .expense ? "支出" : "收入")
                    .font(.headline)
                    .foregroundColor(.adaptiveText)
                    .padding(.vertical, 8)
                
                AmountDisplayView(amount: amount, onTap: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showKeypad = true
                        isAmountFocused = true
                    }
                }, selectedDate: $selectedDate)
                
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
            .background(Color.adaptiveGroupedBackground)
            
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
            date: selectedDate,
            category: category,
            type: type,
            note: note.isEmpty ? nil : note
        )
        
        viewModel.addTransaction(transaction)
    }
}

#Preview("新增支出") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        
        var body: some View {
            AddTransactionView(isPresented: $isPresented, type: .expense)
                .environmentObject(TransactionViewModel())
        }
    }
    
    return PreviewWrapper()
}

#Preview("新增收入") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        
        var body: some View {
            AddTransactionView(isPresented: $isPresented, type: .income)
                .environmentObject(TransactionViewModel())
        }
    }
    
    return PreviewWrapper()
}
