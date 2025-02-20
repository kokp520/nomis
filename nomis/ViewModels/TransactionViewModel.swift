import FirebaseFirestore
import Foundation
import SwiftUI

@MainActor
class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var selectedPeriod: DatePeriod = .month
    @Published private var budgets: [Category: Double] = [:]
    @Published var categoryExpenses: [CategoryExpense] = []
    private var firebaseService = FirebaseService.shared
    private var groupChangeObserver: NSObjectProtocol?
    
    // 快取計算結果
    private var cachedTotalIncome: Double?
    private var cachedTotalExpenses: Double?
    private var cachedBalance: Double?
    
    enum DatePeriod {
        case week, month, year, all
    }
    
    var totalIncome: Double {
        if cachedTotalIncome == nil {
            cachedTotalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        }
        return cachedTotalIncome ?? 0
    }
    
    var totalExpenses: Double {
        if cachedTotalExpenses == nil {
            cachedTotalExpenses = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        }
        return cachedTotalExpenses ?? 0
    }
    
    var balance: Double {
        if cachedBalance == nil {
            cachedBalance = transactions.reduce(0) { result, transaction in
                result + (transaction.type == .income ? transaction.amount : -transaction.amount)
            }
        }
        return cachedBalance ?? 0
    }
    
    struct CategoryExpense: Identifiable {
        let category: Category
        let amount: Double
        var id: Category { category }
    }
    
    var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(10))
    }
    
    private func invalidateCache() {
        cachedTotalIncome = nil
        cachedTotalExpenses = nil
        cachedBalance = nil
    }
    
    @MainActor func addTransaction(_ transaction: Transaction) {
        guard let group = FirebaseService.shared.selectedGroup else {
            print("DEBUG: 添加交易失敗：沒有選擇群組")
            return
        }
        
        Task {
            do {
                try await FirebaseService.shared.addTransaction(transaction, groupID: group.id)
                await MainActor.run {
                    self.transactions.append(transaction)
                    self.invalidateCache()
                    self.updateCategoryExpenses()
                }
            } catch {
                print("DEBUG: 保存交易時發生錯誤: \(error)")
            }
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions.remove(at: index)
            invalidateCache()
            updateCategoryExpenses()
        }
    }
    
    func filterTransactions(for period: DatePeriod) -> [Transaction] {
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = transactions.filter { transaction in
            switch period {
            case .week:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(transaction.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    
    func expenses(for category: Category) -> Double {
        transactions
            .filter { $0.type == .expense && $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }
    
    func budget(for category: Category) -> Double? {
        budgets[category]
    }
    
    func setBudget(_ amount: Double, for category: Category) {
        budgets[category] = amount
        saveBudgets()
    }
    
    func clearAllData() {
        transactions = []
        budgets = [:]
        saveTransactions()
        saveBudgets()
    }
    
    func exportData() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = try? encoder.encode(transactions)
        return exportData ?? Data()
    }
    
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: "transactions")
        }
    }
    
    private func loadTransactions() {
        if let data = UserDefaults.standard.data(forKey: "transactions"),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data)
        {
            transactions = decoded
        }
    }
    
    private func saveBudgets() {
        if let encoded = try? JSONEncoder().encode(budgets) {
            UserDefaults.standard.set(encoded, forKey: "budgets")
        }
    }
    
    private func loadBudgets() {
        if let data = UserDefaults.standard.data(forKey: "budgets"),
           let decoded = try? JSONDecoder().decode([Category: Double].self, from: data)
        {
            budgets = decoded
        }
    }
    
    // 獲取特定類別最近的5筆記錄標題
    func getRecentTitles(for category: Category) -> [String] {
        let filteredTransactions = transactions
            .filter { $0.category == category }
            .sorted { $0.date > $1.date }
        
        return Array(Set(filteredTransactions.prefix(5).map { $0.title }))
    }
    
    func updateCategoryExpenses() {
        var expensesByCategory: [Category: Double] = [:]
        
        for transaction in transactions where transaction.type == .expense {
            expensesByCategory[transaction.category, default: 0] += transaction.amount
        }
        
        categoryExpenses = expensesByCategory.map { category, amount in
            CategoryExpense(category: category, amount: amount)
        }.sorted { $0.amount > $1.amount }
    }
    
    func fetchTransactions() async {
        guard let group = await FirebaseService.shared.selectedGroup else { return }
        
        do {
            let transactions = try await FirebaseService.shared.fetchTransactions(groupID: group.id)
            
            DispatchQueue.main.async {
                self.transactions = transactions
                self.updateCategoryExpenses()
            }
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    init(firebaseService: FirebaseService = FirebaseService.shared) {
        self.firebaseService = firebaseService
        
        setupGroupChangeObserver()
        
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Preview 數據
            transactions = [
                Transaction(title: "午餐", amount: 100, date: Date(), category: .food, type: .expense),
                Transaction(title: "工資", amount: 50000, date: Date(), category: .salary, type: .income),
                Transaction(title: "交通", amount: 30, date: Date(), category: .transport, type: .expense),
                Transaction(title: "購物", amount: 500, date: Date(), category: .shopping, type: .expense)
            ]
            updateCategoryExpenses()
        }
        #endif
    }
    
    private func setupGroupChangeObserver() {
        groupChangeObserver = NotificationCenter.default.addObserver(
            forName: .groupDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.fetchTransactions()
            }
        }
    }
    
    deinit {
        if let observer = groupChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

#if DEBUG
extension TransactionViewModel {
    static var preview: TransactionViewModel {
        @MainActor get {
            let viewModel = TransactionViewModel(firebaseService: FirebaseService.preview)
            
            // 創建跨越不同時間的交易記錄
            let calendar = Calendar.current
            let now = Date()
            
            // 本月交易
            viewModel.transactions = [
                Transaction(title: "午餐", amount: 120, date: now, category: Category.food, type: TransactionType.expense),
                Transaction(title: "計程車", amount: 250, date: now, category: Category.transport, type: TransactionType.expense),
                Transaction(title: "工資", amount: 50000, date: now, category: Category.salary, type: TransactionType.income),
                Transaction(title: "購物", amount: 1500, date: now, category: Category.shopping, type: TransactionType.expense),
                Transaction(title: "電影", amount: 300, date: now, category: Category.entertainment, type: TransactionType.expense),
                
                // 上週交易
                Transaction(title: "超市", amount: 800, 
                           date: calendar.date(byAdding: .day, value: -7, to: now)!, 
                           category: Category.food, type: TransactionType.expense),
                
                // 上月交易
                Transaction(title: "投資收入", amount: 10000, 
                           date: calendar.date(byAdding: .month, value: -1, to: now)!, 
                           category: Category.investment, type: TransactionType.income),
                
                // 更早的交易
                Transaction(title: "年終獎金", amount: 100000, 
                           date: calendar.date(byAdding: .month, value: -2, to: now)!, 
                           category: Category.salary, type: TransactionType.income)
            ]
            
            // 設定一些預算
            viewModel.setBudget(5000, for: Category.food)
            viewModel.setBudget(3000, for: Category.transport)
            viewModel.setBudget(2000, for: Category.entertainment)
            viewModel.setBudget(10000, for: Category.shopping)
            
            viewModel.updateCategoryExpenses()
            return viewModel
        }
    }
}
#endif
