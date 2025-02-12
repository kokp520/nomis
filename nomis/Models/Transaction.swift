import Foundation

public struct Transaction: Identifiable, Codable {
    public let id: String
    public var title: String
    public var amount: Double
    public var date: Date
    public var category: Category
    public var type: TransactionType
    public var note: String?
    
    public init(id: String = UUID().uuidString, title: String, amount: Double, date: Date = Date(), category: Category, type: TransactionType, note: String? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.type = type
        self.note = note
    }
} 