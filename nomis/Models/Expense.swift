import Foundation

struct Expense: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let date: Date
    let category: Category
    
    enum Category: String, CaseIterable {
        case food = "Food"
        case transport = "Transport"
        case entertainment = "Entertainment"
        case shopping = "Shopping"
        case other = "Other"
    }
} 