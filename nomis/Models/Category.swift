import Foundation
import SwiftUI

// 可自定義的分類結構體
public struct Category: Identifiable, Codable, Equatable, Hashable {
    public var id: String
    public var name: String
    public var icon: String
    public var color: Color
    public var groupId: String?  // 所屬的群組ID，若為nil則為預設分類
    
    public init(id: String = UUID().uuidString, name: String, icon: String, color: Color, groupId: String? = nil) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.groupId = groupId
    }
    
    // Hashable 和 Equatable 實作
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Color 不能直接 Codable，需要自訂編碼和解碼
    private enum CodingKeys: String, CodingKey {
        case id, name, icon, colorHex, groupId
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        let colorHex = try container.decode(String.self, forKey: .colorHex)
        color = Color(hex: colorHex) ?? .gray
        groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        // 將Color轉為十六進位字串儲存
        let colorHex = color.toHex() ?? "#808080"
        try container.encode(colorHex, forKey: .colorHex)
        try container.encodeIfPresent(groupId, forKey: .groupId)
    }
}

// 預設分類
public extension Category {
    static let food = Category(name: "食物", icon: "🍽️", color: .orange)
    static let transport = Category(name: "交通", icon: "🚗", color: .blue)
    static let entertainment = Category(name: "娛樂", icon: "🎮", color: .purple)
    static let shopping = Category(name: "購物", icon: "🛍️", color: .pink)
    static let salary = Category(name: "薪資", icon: "💰", color: .green)
    static let investment = Category(name: "投資", icon: "📈", color: .mint)
    static let other = Category(name: "其他", icon: "📦", color: .gray)
    
    static var defaultCategories: [Category] {
        [food, transport, entertainment, shopping, salary, investment, other]
    }
}

public enum TransactionType: String, Codable {
    case income = "收入"
    case expense = "支出"
}
