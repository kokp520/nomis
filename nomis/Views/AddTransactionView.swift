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
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            
            action(key)
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                if key == "⌫" {
                    Image(systemName: "delete.left.fill")
                        .font(.title2)
                } else {
                    Text(key)
                        .font(.system(size: isOperator ? 24 : 28, weight: isOperator ? .medium : .regular))
                }
            }
        }
        .frame(width: 75, height: isEnter ? 65 : 60)
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
                return .blue.opacity(0.25)
            } else {
                return Color(.systemGray5)
            }
        } else {
            if key == "⌫" {
                return Color(.systemGray5)
            } else if isOperator {
                return .blue.opacity(0.15)
            } else {
                return Color(.systemGray6)
            }
        }
    }
    
    private var foregroundColor: Color {
        if isOperator {
            return .blue
        } else if key == "⌫" {
            return .red.opacity(0.8)
        } else {
            return .primary
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
        VStack(spacing: 12) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal)
            
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 36, height: 5)
                .padding(.vertical, 4)
            
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key: key, action: onKeyPress, isEnter: false, hasOperator: hasOperator)
                    }
                }
            }
            
            KeypadButton(
                key: hasOperator ? "=" : "↵",
                action: onKeyPress,
                isEnter: true,
                hasOperator: hasOperator
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: -5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                        .foregroundColor(.adaptiveSecondaryText)
                        .font(.system(size: 24))
                        .bold()
                    Spacer()
                    Text(amount.isEmpty ? "0" : amount)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.adaptiveText)
                        .minimumScaleFactor(0.5)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.adaptiveBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)
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
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(formatDate(selectedDate))
                            .foregroundColor(.adaptiveSecondaryText)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.adaptiveSecondaryText)
                            .font(.system(size: 12))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
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
            HStack {
                Text("選擇類別")
                    .font(.headline)
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dismiss()
                        }
                    }) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(category == selectedCategory ? 
                                        Color.blue.opacity(0.15) : 
                                        Color.adaptiveBackground)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(category == selectedCategory ?
                                                Color.blue.opacity(0.3) :
                                                Color.primary.opacity(0.1),
                                                lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.05),
                                        radius: 4, x: 0, y: 2)
                                
                                Text(category.icon)
                                    .font(.system(size: 32))
                            }
                            .scaleEffect(category == selectedCategory ? 1.1 : 1.0)
                            
                            Text(category.rawValue)
                                .font(.system(size: 14))
                                .foregroundColor(category == selectedCategory ?
                                    .blue : .adaptiveText)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            Button(action: {
                dismiss()
            }) {
                Text("取消")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .padding()
        }
        .background(Color.adaptiveGroupedBackground)
        .presentationDetents([.height(380)])
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
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    private var inputBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 類別選擇
            VStack(spacing: 0) {
                Button(action: {
                    showCategoryPicker = true
                }) {
                    HStack(alignment: .center) {
                        Text("類別")
                            .foregroundColor(.adaptiveSecondaryText)
                            .frame(width: 60, alignment: .leading)
                        
                        HStack(spacing: 8) {
                            Text(category.icon)
                                .font(.title3)
                            Text(category.rawValue)
                                .foregroundColor(.adaptiveText)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(colorScheme == .dark ? 
                                    Color.blue.opacity(0.2) : 
                                    Color.blue.opacity(0.1))
                        )
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.adaptiveSecondaryText)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(cardBackground)
                }
            }
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                   radius: 4, x: 0, y: 2)
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $category, title: $title, type: type)
            }
            
            // 名稱輸入
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("名稱")
                        .foregroundColor(.adaptiveSecondaryText)
                        .frame(width: 60, alignment: .leading)
                    
                    TextField("點擊以編輯", text: $title, onEditingChanged: { editing in
                        isEditingTitle = editing
                    })
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isEditingTitle ? inputBackground : .clear)
                    )
                    .foregroundColor(title.isEmpty ? .adaptiveSecondaryText : .adaptiveText)
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(cardBackground)
                
                if isEditingTitle {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("最近使用")
                            .font(.footnote)
                            .foregroundColor(.adaptiveSecondaryText)
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
                                            HStack(spacing: 6) {
                                                Text(category.icon)
                                                    .font(.subheadline)
                                                Text(historyTitle)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(colorScheme == .dark ? 
                                                        Color.blue.opacity(0.2) : 
                                                        Color.blue.opacity(0.1))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                    .background(cardBackground)
                }
            }
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                   radius: 4, x: 0, y: 2)
            
            // 備忘錄輸入
            HStack(alignment: .center) {
                Text("備忘錄")
                    .foregroundColor(.adaptiveSecondaryText)
                    .frame(width: 60, alignment: .leading)
                
                TextField("點擊以編輯", text: $note)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(note.isEmpty ? .clear : inputBackground)
                    )
                    .foregroundColor(note.isEmpty ? .adaptiveSecondaryText : .adaptiveText)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(cardBackground)
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05),
                   radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
