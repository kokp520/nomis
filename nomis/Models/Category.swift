import Foundation
import SwiftUI

public enum Category: String, Codable, CaseIterable {
    case food = "食物"
    case transport = "交通"
    case entertainment = "娛樂"
    case shopping = "購物"
    case salary = "薪資"
    case investment = "投資"
    case other = "其他"

    public var icon: String {
        switch self {
        case .food: return "🍽️"
        case .transport: return "🚗"
        case .entertainment: return "🎮"
        case .shopping: return "🛍️"
        case .salary: return "💰"
        case .investment: return "📈"
        case .other: return "📦"
        }
    }
    
    public var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .entertainment: return .purple
        case .shopping: return .pink
        case .salary: return .green
        case .investment: return .mint
        case .other: return .gray
        }
    }
}

public enum TransactionType: String, Codable {
    case income = "收入"
    case expense = "支出"
}
