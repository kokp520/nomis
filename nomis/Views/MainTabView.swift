import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = TransactionViewModel()
    
    var body: some View {
        TabView {
            OverviewView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("總覽", systemImage: "chart.pie.fill")
                }
            
            TransactionListView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("交易", systemImage: "list.bullet")
                }
            
            AddTransactionView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("新增", systemImage: "plus.circle.fill")
                }
            
            BudgetView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("預算", systemImage: "banknote.fill")
                }
            
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
} 