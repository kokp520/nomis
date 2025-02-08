import Foundation
import CloudKit

struct Expense: Identifiable {
    let id: String
    let title: String
    let amount: Double
    let date: Date
    let category: Category
    let creatorID: String
    var shareReference: CKRecord.Reference?
    
    enum Category: String, CaseIterable, Codable {
        case food = "Food"
        case transport = "Transport"
        case entertainment = "Entertainment"
        case shopping = "Shopping"
        case other = "Other"
    }
    
    init(id: String = UUID().uuidString, title: String, amount: Double, date: Date = Date(), category: Category, creatorID: String, shareReference: CKRecord.Reference? = nil) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.creatorID = creatorID
        self.shareReference = shareReference
    }
    
    init?(record: CKRecord) {
        guard let title = record["title"] as? String,
              let amount = record["amount"] as? Double,
              let date = record["date"] as? Date,
              let categoryRaw = record["category"] as? String,
              let category = Category(rawValue: categoryRaw),
              let creatorID = record["creatorID"] as? String else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.creatorID = creatorID
        self.shareReference = record.parent
    }
    
    func toCKRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: "Expense", recordID: recordID)
        record["title"] = title
        record["amount"] = amount
        record["date"] = date
        record["category"] = category.rawValue
        record["creatorID"] = creatorID
        return record
    }
} 