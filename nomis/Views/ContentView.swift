import SwiftUI

struct ContentView: View {
    @State private var expenses: [Expense] = []
    @State private var showingAddExpense = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 標題欄
                HStack {
                    Text("ExpenseTracker")
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(.green)
                    Spacer()
                    Text("\(expenses.count)/? Tasks done")
                        .font(.custom("PressStart2P-Regular", size: 12))
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.black)
                
                // 支出列表
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(expenses) { expense in
                            ExpenseRow(expense: expense)
                        }
                        
                        Button(action: {
                            showingAddExpense = true
                        }) {
                            HStack {
                                Text("+ new expense")
                                    .font(.custom("PressStart2P-Regular", size: 14))
                                Spacer()
                            }
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.green, lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(expenses: $expenses)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            Text(expense.title)
                .font(.custom("PressStart2P-Regular", size: 14))
            Spacer()
            Text("$\(String(format: "%.2f", expense.amount))")
                .font(.custom("PressStart2P-Regular", size: 14))
        }
        .padding()
        .background(Color.black)
        .foregroundColor(.green)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green, lineWidth: 1)
        )
    }
} 