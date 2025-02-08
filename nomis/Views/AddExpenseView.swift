import SwiftUI
import CloudKit

struct AddExpenseView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var expenses: [Expense]
    @StateObject private var cloudKitManager = CloudKitManager.shared
    
    @State private var title = ""
    @State private var amount = ""
    @State private var category = Expense.Category.other
    @State private var error: Error?
    @State private var isLoading = false
    @State private var creatorID: String = "unknown"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("新增支出")
                    .font(.custom("PressStart2P-Regular", size: 16))
                    .foregroundColor(.green)
                
                TextField("標題", text: $title)
                    .textFieldStyle(PixelTextFieldStyle())
                
                TextField("金額", text: $amount)
                    .textFieldStyle(PixelTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                Picker("類別", selection: $category) {
                    ForEach(Expense.Category.allCases, id: \.self) { category in
                        Text(category.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.green)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                } else {
                    Button("儲存") {
                        saveExpense()
                    }
                    .buttonStyle(PixelButtonStyle())
                    .disabled(!isValid)
                }
                
                if let error = error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .font(.custom("PressStart2P-Regular", size: 12))
                }
            }
            .padding()
        }
        .onAppear {
            fetchCreatorID()
        }
    }
    
    private var isValid: Bool {
        !title.isEmpty && !amount.isEmpty && Double(amount) != nil
    }
    
    private func fetchCreatorID() {
        cloudKitManager.container.fetchUserRecordID { recordID, error in
            if let recordID = recordID {
                DispatchQueue.main.async {
                    self.creatorID = recordID.recordName
                }
            }
        }
    }
    
    private func saveExpense() {
        guard let amountDouble = Double(amount) else { return }
        isLoading = true
        
        let expense = Expense(
            title: title,
            amount: amountDouble,
            date: Date(),
            category: category,
            creatorID: creatorID
        )
        
        let record = expense.toCKRecord()
        
        cloudKitManager.container.privateCloudDatabase.save(record) { _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    self.error = error
                } else {
                    expenses.append(expense)
                    dismiss()
                }
            }
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

#Preview {
    struct PreviewWrapper: View {
        @State private var expenses: [Expense] = []
        
        var body: some View {
            AddExpenseView(expenses: $expenses)
                .environmentObject(CloudKitManager.preview)
        }
    }
    
    return PreviewWrapper()
} 
