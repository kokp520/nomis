import Foundation
import CloudKit

public struct Group: Identifiable, Equatable {
    public let id: String
    public var name: String
    public var owner: String
    public var members: [String]
    public var createdAt: Date
    
    public init(id: String = UUID().uuidString, name: String, owner: String, members: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.owner = owner
        self.members = members
        self.createdAt = createdAt
    }
    
    // CloudKit Record 轉換
    public init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let owner = record["owner"] as? String else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.name = name
        self.owner = owner
        self.members = record["members"] as? [String] ?? []
        self.createdAt = record.creationDate ?? Date()
    }
    
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Group")
        record["name"] = name
        record["owner"] = owner
        record["members"] = members
        return record
    }
    
    // 實作 Equatable
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.id == rhs.id
    }
} 