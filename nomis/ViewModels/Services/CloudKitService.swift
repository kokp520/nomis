import Foundation
import CloudKit

public class CloudKitService {
    public static let shared = CloudKitService()
    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    
    private init() {
        self.privateDatabase = container.privateCloudDatabase
    }
    
    public var selectedGroup: Group?
    
    public func saveRecord(_ record: CKRecord) async throws -> CKRecord {
        try await privateDatabase.save(record)
    }
    
    public func fetchRecords(matching query: CKQuery) async throws -> [(CKRecord.ID, Result<CKRecord, Error>)] {
        let result = try await privateDatabase.records(matching: query)
        return result.matchResults
    }
    
    // 在這裡添加 CloudKit 相關的方法
} 