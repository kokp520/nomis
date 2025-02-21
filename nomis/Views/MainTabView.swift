import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @StateObject private var sidebarViewModel = SidebarViewModel.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddTransaction = false
    @State private var selectedTab = 0
    @State private var transactionType: TransactionType = .expense
    @ObservedObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                ZStack {
                    TabView(selection: $selectedTab) {
                        OverviewView()
                            .environmentObject(viewModel)
                            .environmentObject(sidebarViewModel)
                            .tabItem {
                                Label("總覽", systemImage: "chart.pie.fill")
                            }
                            .tag(0)
                        
                        TransactionListView()
                            .environmentObject(viewModel)
                            .environmentObject(sidebarViewModel)
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
                            .environmentObject(sidebarViewModel)
                            .tabItem {
                                Label("預算", systemImage: "banknote.fill")
                            }
                            .tag(3)
                        
                        SettingsView()
                            .environmentObject(viewModel)
                            .environmentObject(sidebarViewModel)
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
                    
                    // 側邊欄
                    if sidebarViewModel.showingSidebar {
                        GeometryReader { geometry in
                            SidebarView(
                                firebaseService: firebaseService,
                                showingSidebar: $sidebarViewModel.showingSidebar,
                                showingCreateGroup: $sidebarViewModel.showingCreateGroup,
                                geometry: geometry
                            )
                        }
                        .ignoresSafeArea()
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
