import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddTransaction = false
    @State private var selectedTab = 0
    @State private var transactionType: TransactionType = .expense
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    OverviewView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("總覽", systemImage: "chart.pie.fill")
                        }
                        .tag(0)
                    
                    TransactionListView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("交易", systemImage: "list.bullet")
                        }
                        .tag(1)
                    
                    Color.clear
                        .tabItem {
                            Label("新增", systemImage: "plus.circle.fill")
                        }
                        .tag(2)
                    
                    BudgetView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("預算", systemImage: "banknote.fill")
                        }
                        .tag(3)
                    
                    SettingsView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("設定", systemImage: "gear")
                        }
                        .tag(4)
                }
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 2 {
                        showAddTransaction = true
                        selectedTab = 1
                    }
                }
                .sheet(isPresented: $showAddTransaction) {
                    NavigationView {
                        VStack {
                            Picker("交易類型", selection: $transactionType) {
                                Text("支出").tag(TransactionType.expense)
                                Text("收入").tag(TransactionType.income)
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            
                            AddTransactionView(isPresented: $showAddTransaction, type: transactionType)
                                .environmentObject(viewModel)
                        }
                    }
                }
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(TransactionViewModel.preview)
        .environmentObject(AuthViewModel())
}
