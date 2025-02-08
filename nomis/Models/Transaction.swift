import Foundation

struct Transaction: Identifiable, Codable {
    let id: UUID
    var title: String
    var amount: Double
    var date: Date
    var category: Category
    var type: TransactionType
    var note: String?
    
    init(id: UUID = UUID(), title: String, amount: Double, date: Date = Date(), category: Category, type: TransactionType, note: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.type = type
        self.note = note
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Income"
    case expense = "Expense"
}

enum Category: String, Codable, CaseIterable {
    case food = "Food"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case salary = "Salary"
    case investment = "Investment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .food: return "🍽️"
        case .transport: return "🚗"
        case .entertainment: return "🎮"
        case .shopping: return "🛍️"
        case .salary: return "💰"
        case .investment: return "📈"
        case .other: return "��"
        }
    }
} 