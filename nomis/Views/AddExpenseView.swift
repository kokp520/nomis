import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var expenses: [Expense]
    
    @State private var title = ""
    @State private var amount = ""
    @State private var category = Expense.Category.other
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Add New Expense")
                    .font(.custom("PressStart2P-Regular", size: 16))
                    .foregroundColor(.green)
                
                TextField("Title", text: $title)
                    .textFieldStyle(PixelTextFieldStyle())
                
                TextField("Amount", text: $amount)
                    .textFieldStyle(PixelTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                Picker("Category", selection: $category) {
                    ForEach(Expense.Category.allCases, id: \.self) { category in
                        Text(category.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Button("Save") {
                    if let amountDouble = Double(amount) {
                        let expense = Expense(
                            title: title,
                            amount: amountDouble,
                            date: Date(),
                            category: category
                        )
                        expenses.append(expense)
                        dismiss()
                    }
                }
                .buttonStyle(PixelButtonStyle())
            }
            .padding()
        }
    }
}

struct PixelTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.custom("PressStart2P-Regular", size: 14))
            .padding()
            .background(Color.black)
            .foregroundColor(.green)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.green, lineWidth: 1)
            )
    }
}

struct PixelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.custom("PressStart2P-Regular", size: 14))
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? Color.green : Color.black)
            .foregroundColor(configuration.isPressed ? Color.black : Color.green)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.green, lineWidth: 1)
            )
    }
} 