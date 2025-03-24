import SwiftUI

struct MainTabView: View {
    @StateObject private var viewModel = TransactionViewModel()
    @StateObject private var sidebarViewModel = SidebarViewModel.shared
    @ObservedObject private var firebaseService = FirebaseService.shared
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAddTransaction = false
    @State private var selectedTab = 0
    @State private var transactionType: TransactionType = .expense
    
    var body: some View {
        SwiftUI.Group {
            if authViewModel.isAuthenticated {
                ZStack {
                    TabView(selection: $selectedTab) {
                        OverviewView(
                            transactionViewModel: viewModel,
                            authViewModel: authViewModel
                        )
                            .environmentObject(sidebarViewModel)
                            .tabItem {
                                Label("", systemImage: "house.fill")
                            }
                            .tag(0)
                        
                        TransactionListView()
                            .environmentObject(viewModel)
                            .environmentObject(sidebarViewModel)
                            .tabItem {
                                Label("", systemImage: "calendar")
                            }
                            .tag(1)
                        
                        // 中間的加號按鈕（特殊處理）
                        Color.clear
                            .overlay(
                                // 這個 ZStack 作為視覺佔位符，但不參與實際點擊
                                ZStack {
                                    Circle()
                                        .foregroundColor(.black)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "plus")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .offset(y: -30)
                            )
                            .tabItem {
                                Text("")
                            }
                            .tag(2)
                        
                        BudgetView()
                            .environmentObject(viewModel)
                            .environmentObject(sidebarViewModel)
                            .tabItem {
                                Label("", systemImage: "bell.fill")
                            }
                            .tag(3)
                        
                        SettingsView()
                            .environmentObject(viewModel)
                            .environmentObject(sidebarViewModel)
                            .tabItem {
                                Label("", systemImage: "person.fill")
                            }
                            .tag(4)
                    }
                    .onChange(of: selectedTab) { _, newValue in
                        if newValue == 2 {
                            showAddTransaction = true
                            selectedTab = 0  // 回到首頁
                        }
                    }
                    .onAppear {
                        // 設置標籤欄風格
                        let appearance = UITabBarAppearance()
                        appearance.configureWithDefaultBackground()
                        appearance.backgroundColor = UIColor.systemBackground
                        
                        // 設置選中和未選中的文字顏色
                        let tabBarItemAppearance = UITabBarItemAppearance()
                        tabBarItemAppearance.normal.iconColor = UIColor.systemGray
                        tabBarItemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemGray]
                        tabBarItemAppearance.selected.iconColor = UIColor.label
                        tabBarItemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
                        
                        appearance.stackedLayoutAppearance = tabBarItemAppearance
                        appearance.inlineLayoutAppearance = tabBarItemAppearance
                        appearance.compactInlineLayoutAppearance = tabBarItemAppearance
                        
                        UITabBar.appearance().standardAppearance = appearance
                        if #available(iOS 15.0, *) {
                            UITabBar.appearance().scrollEdgeAppearance = appearance
                        }
                    }
                    
                    // 中間的大加號按鈕（實際點擊區域）
                    VStack {
                        Spacer()
                        
                        Button(action: {
                            showAddTransaction = true
                        }) {
                            ZStack {
                                Circle()
                                    .foregroundColor(.black)
                                    .frame(width: 56, height: 56)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(y: -60)
                        
                        Spacer().frame(height: 30)
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
        .environmentObject(AuthViewModel(firebaseService: FirebaseService.shared))
}
