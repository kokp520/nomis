import CloudKit
import SwiftUI

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    static let preview = CloudKitManager(isPreview: true)
    
    let container: CKContainer
    @Published var isSignedIn = false
    @Published var userName: String = ""
    private let isPreview: Bool
    
    private init(isPreview: Bool = false) {
        self.isPreview = isPreview
        self.container = isPreview ? CKContainer(identifier: "iCloud.preview") : CKContainer.default()
        if !isPreview {
            checkUserStatus()
        } else {
            self.isSignedIn = true
            self.userName = "預覽使用者"
        }
    }
    
    func checkUserStatus() {
        guard !isPreview else { return }
        
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isSignedIn = true
                    self?.fetchUserName()
                default:
                    self?.isSignedIn = false
                }
            }
        }
    }
    
    private func fetchUserName() {
        guard !isPreview else { return }
        
        container.fetchUserRecordID { [weak self] recordID, error in
            if let recordID = recordID {
                self?.container.publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
                    DispatchQueue.main.async {
                        if let record = record {
                            self?.userName = record["givenName"] as? String ?? "Unknown"
                        }
                    }
                }
            }
        }
    }
    
    func shareExpense(expense: Expense, completion: @escaping (CKShare?, Error?) -> Void) {
        guard !isPreview else {
            let share = CKShare(rootRecord: CKRecord(recordType: "Expense"))
            completion(share, nil)
            return
        }
        
        let record = expense.toCKRecord()
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "共享支出記錄" as CKRecordValue
        
        let operation = CKModifyRecordsOperation(recordsToSave: [record, share])
        operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecords, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(share, nil)
                }
            }
        }
        container.privateCloudDatabase.add(operation)
    }
    
    func fetchSharedExpenses(completion: @escaping ([Expense], Error?) -> Void) {
        guard !isPreview else {
            let previewExpenses = [
                Expense(title: "預覽支出1", amount: 100, category: .food, creatorID: "preview"),
                Expense(title: "預覽支出2", amount: 200, category: .shopping, creatorID: "preview")
            ]
            completion(previewExpenses, nil)
            return
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Expense", predicate: predicate)
        
        container.sharedCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion([], error)
                } else if let records = records {
                    let expenses = records.compactMap { Expense(record: $0) }
                    completion(expenses, nil)
                }
            }
        }
    }
} 