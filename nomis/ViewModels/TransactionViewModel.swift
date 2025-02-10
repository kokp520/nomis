import Foundation
import SwiftUI

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var selectedPeriod: DatePeriod = .month
    @Published private var budgets: [Category: Double] = [:]
    
    enum DatePeriod {
        case week, month, year, all
    }
    
    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }
    
    var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpenses
    }
    
    struct CategoryExpense: Identifiable {
        let category: Category
        let amount: Double
        var id: Category { category }
    }
    
    var categoryExpenses: [CategoryExpense] {
        Dictionary(grouping: transactions.filter { $0.type == .expense }) { $0.category }
            .map { CategoryExpense(category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }
    }
    
    var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        saveTransactions()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions.remove(at: index)
            saveTransactions()
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
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
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
           let decoded = try? JSONDecoder().decode([Category: Double].self, from: data) {
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
    
    init() {
        loadTransactions()
        loadBudgets()
    }
} 