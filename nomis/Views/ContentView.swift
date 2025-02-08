import SwiftUI
import CloudKit

struct ContentView: View {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var expenses: [Expense] = []
    @State private var sharedExpenses: [Expense] = []
    @State private var showingAddExpense = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            personalExpensesView
                .tabItem {
                    Label("個人支出", systemImage: "person.fill")
                }
                .tag(0)
            
            sharedExpensesView
                .tabItem {
                    Label("共享支出", systemImage: "person.3.fill")
                }
                .tag(1)
        }
        .accentColor(.green)
        .onAppear {
            loadSharedExpenses()
        }
    }
    
    var personalExpensesView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 標題欄
                HStack {
                    if cloudKitManager.isSignedIn {
                        Text("歡迎, \(cloudKitManager.userName)")
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.green)
                    } else {
                        Text("請登入 iCloud")
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Text("\(expenses.count) 筆記錄")
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
                                .contextMenu {
                                    if cloudKitManager.isSignedIn {
                                        NavigationLink(destination: ShareExpenseView(expense: expense)) {
                                            Label("分享", systemImage: "square.and.arrow.up")
                                        }
                                    }
                                }
                        }
                        
                        Button(action: {
                            showingAddExpense = true
                        }) {
                            HStack {
                                Text("+ 新增支出")
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
            if cloudKitManager.isSignedIn {
                AddExpenseView(expenses: $expenses)
            } else {
                Text("請先登入 iCloud")
                    .font(.custom("PressStart2P-Regular", size: 16))
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    var sharedExpensesView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("共享支出")
                    .font(.custom("PressStart2P-Regular", size: 16))
                    .foregroundColor(.green)
                    .padding()
                
                if cloudKitManager.isSignedIn {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(sharedExpenses) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                        .padding()
                    }
                } else {
                    Text("請登入 iCloud 以查看共享支出")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }
    
    private func loadSharedExpenses() {
        guard cloudKitManager.isSignedIn else { return }
        
        CloudKitManager.shared.fetchSharedExpenses { expenses, error in
            if let error = error {
                print("Error fetching shared expenses: \(error.localizedDescription)")
            } else {
                self.sharedExpenses = expenses
            }
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.custom("PressStart2P-Regular", size: 14))
                Text(expense.category.rawValue)
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.green.opacity(0.7))
            }
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

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var cloudKitManager = CloudKitManager.preview
        @State private var expenses: [Expense] = [
            Expense(title: "午餐", amount: 150, category: .food, creatorID: "preview"),
            Expense(title: "計程車", amount: 200, category: .transport, creatorID: "preview")
        ]
        
        var body: some View {
            NavigationView {
                ContentView()
                    .environmentObject(cloudKitManager)
            }
        }
    }
    
    return PreviewWrapper()
}
