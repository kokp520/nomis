import SwiftUI

struct CategoryExpense: Identifiable {
    let id = UUID()
    let category: Category
    let amount: Double
} 