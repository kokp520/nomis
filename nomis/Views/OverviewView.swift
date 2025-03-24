// 已經經換成home view了 先註解
import Charts
import FirebaseCore
import SwiftUI
import Combine

// MARK: - ViewModel
@MainActor
class OverviewViewModel: ObservableObject {
    // 資料模型
    @Published var accounts: [AccountModel] = []
    @Published var categories: [CategoryModel] = []
    @Published var totalBalance: Double = 0
    @Published var isLoading: Bool = false
    @Published var error: ErrorModel? = nil
    
    // 服務依賴
    private let transactionService: TransactionViewModel
    private let authService: AuthViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // 懶加載計算最大分類金額
    private lazy var maxCategoryAmount: Double = {
        categories.map { $0.amount }.max() ?? 1.0
    }()
    
    init(transactionService: TransactionViewModel, authService: AuthViewModel) {
        self.transactionService = transactionService
        self.authService = authService
        
        // 設置初始模擬數據
        setupMockData()
        
        // 設置數據訂閱
        setupSubscriptions()
    }
    
    // 初始化模擬數據
    private func setupMockData() {
        accounts = [
            AccountModel(id: "1", title: "本地銀行 1", balance: 350000.00, icon: "building.columns.fill", color: .blue),
            AccountModel(id: "2", title: "信用卡", balance: 150000.00, icon: "creditcard.fill", color: .green)
        ]
        
        let investmentCategory = Category(name: "投資", icon: "📈", color: .blue)
        let housingCategory = Category(name: "房屋支出", icon: "🏠", color: .green)
        let techCategory = Category(name: "購買電腦", icon: "💻", color: .purple)
        
        categories = [
            CategoryModel(id: "1", category: investmentCategory, amount: 32000.00, icon: "chart.line.uptrend.xyaxis"),
            CategoryModel(id: "2", category: housingCategory, amount: 10000.00, icon: "house.fill"),
            CategoryModel(id: "3", category: techCategory, amount: 30000.00, icon: "desktopcomputer")
        ]
        
        calculateTotalBalance()
    }
    
    // 設置數據訂閱
    private func setupSubscriptions() {
        // 當交易數據變化時更新分類統計
        transactionService.$transactions
            .debounce(for: 0.5, scheduler: RunLoop.main)  // 防止頻繁更新
            .sink { [weak self] transactions in
                self?.updateCategoriesFromTransactions(transactions)
            }
            .store(in: &cancellables)
        
        // 監聽分類變化，更新最大金額
        $categories
            .sink { [weak self] _ in
                self?.updateMaxAmount()
            }
            .store(in: &cancellables)
    }
    
    // 從交易更新分類統計
    private func updateCategoriesFromTransactions(_ transactions: [Transaction]) {
        // 真實場景中應從交易計算分類金額
        // 此處保留模擬數據用於展示
    }
    
    // 更新最大分類金額
    private func updateMaxAmount() {
        maxCategoryAmount = categories.map { $0.amount }.max() ?? 1.0
    }
    
    // 計算總餘額
    private func calculateTotalBalance() {
        totalBalance = accounts.reduce(0) { $0 + $1.balance }
    }
    
    // 計算進度百分比
    func progressFor(amount: Double) -> Double {
        return amount / maxCategoryAmount
    }
    
    // 獲取用戶名稱
    var userName: String {
        authService.user?.name ?? authService.currentUser?.displayName ?? "Steve Young"
    }
    
    // 獲取用戶郵箱
    var userEmail: String {
        authService.user?.email ?? authService.currentUser?.email ?? "steve.young@gmail.com"
    }
    
    // 刷新數據
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 模擬網絡請求
            // 更新數據
            DispatchQueue.main.async {
                self.setupMockData()
            }
        } catch {
            DispatchQueue.main.async {
                self.error = ErrorModel(
                    title: "刷新失敗",
                    message: error.localizedDescription
                )
            }
        }
    }
}

// MARK: - 數據模型
struct AccountModel: Identifiable {
    let id: String
    let title: String
    let balance: Double
    let icon: String
    let color: Color
}

struct CategoryModel: Identifiable {
    let id: String
    let category: Category
    let amount: Double
    let icon: String
    
    var color: Color {
        return category.color
    }
    
    var title: String {
        return category.name
    }
}

struct ErrorModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - 組件化視圖
struct UserProfileHeaderView: View {
    let userName: String
    let userEmail: String
    
    var body: some View {
        HStack(spacing: 12) {
            // 用戶頭像
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(userEmail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 通知圖標
            ZStack {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundColor(.primary)
                
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.red)
                    .offset(x: 8, y: -8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct BalanceView: View {
    let balance: Double
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("總餘額")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("$\(String(format: "%.2f", balance))")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.primary)
                
            Text("Total Fund Balance")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct AccountCardView: View {
    let account: AccountModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            // 圖標
            ZStack {
                Circle()
                    .fill(account.color.opacity(0.1))
                    .frame(width: 36, height: 36)
                
                Image(systemName: account.icon)
                    .foregroundColor(account.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("$\(String(format: "%.2f", account.balance))")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ActionButtonView: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct CategoryItemView: View {
    let category: CategoryModel
    let progress: Double // 0.0-1.0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // 圖標
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(category.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", category.amount))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                // 進度條
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        Rectangle()
                            .fill(category.color)
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 錯誤處理和加載視圖
struct ErrorView: View {
    let error: ErrorModel
    let retryAction: () -> Void
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            
            Text(error.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(error.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button(action: dismissAction) {
                    Text("忽略")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: retryAction) {
                    Text("重試")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("加載中...")
                .font(.headline)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).opacity(0.8))
    }
}

// MARK: - 主視圖
struct OverviewView: View {
    @StateObject private var viewModel: OverviewViewModel
    @EnvironmentObject var sidebarViewModel: SidebarViewModel
    @State private var showAddTransaction = false
    @State private var transactionType: TransactionType = .expense
    @State private var showError = false
    @State private var isRefreshing = false
    @Environment(\.colorScheme) private var colorScheme
    
    // 依賴注入
    init(transactionViewModel: TransactionViewModel, authViewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: OverviewViewModel(
            transactionService: transactionViewModel,
            authService: authViewModel
        ))
    }
    
    var body: some View {
        ZStack {
            // 主內容
            ScrollView {
                VStack(spacing: 24) {
                    // 用戶資料頭部
                    UserProfileHeaderView(
                        userName: viewModel.userName,
                        userEmail: viewModel.userEmail
                    )
                    .transition(.opacity)
                    
                    // 餘額
                    BalanceView(balance: viewModel.totalBalance)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    
                    // 帳戶卡片
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.accounts) { account in
                            AccountCardView(account: account)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    
                    // 操作按鈕
                    HStack(spacing: 20) {
                        Spacer()
                        
                        ActionButtonView(title: "加入新賬單", icon: "plus.circle.fill") {
                            transactionType = .expense
                            showAddTransaction = true
                        }
                        
                        Spacer()
                        
                        ActionButtonView(title: "轉賬", icon: "arrow.left.arrow.right") {
                            // 轉賬功能
                        }
                        
                        Spacer()
                        
                        ActionButtonView(title: "申請貸款", icon: "dollarsign.circle") {
                            // 申請貸款功能
                        }
                        
                        Spacer()
                    }
                    
                    // 分類標題
                    HStack {
                        Text("分類")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("查看全部")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 分類列表
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.categories) { category in
                            CategoryItemView(
                                category: category,
                                progress: viewModel.progressFor(amount: category.amount)
                            )
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
                .opacity(viewModel.isLoading ? 0.6 : 1)
                .animation(.easeInOut, value: viewModel.isLoading)
                .refreshable {
                    isRefreshing = true
                    await viewModel.refresh()
                    isRefreshing = false
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // 加載指示器
            if viewModel.isLoading && !isRefreshing {
                LoadingView()
            }
            
            // 錯誤視圖
            if let error = viewModel.error {
                ErrorView(
                    error: error,
                    retryAction: {
                        Task {
                            await viewModel.refresh()
                        }
                    },
                    dismissAction: {
                        viewModel.error = nil
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    sidebarViewModel.showingSidebar.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.primary)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("主頁")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // 個人資料操作
                } label: {
                    Image(systemName: "person.crop.circle")
                        .foregroundColor(.primary)
                }
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
                    
//                    AddTransactionView(isPresented: $showAddTransaction, type: transactionType)
//                        .environmentObject(viewModel.transactionService)
                }
            }
        }
        .onAppear {
            // 初始化和數據獲取
            Task {
                await viewModel.refresh()
            }
        }
    }
}
