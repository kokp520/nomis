import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    private var mainContextObserver: NSObjectProtocol?
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "nomis")
        
        // 在主線程上初始化和加載存儲
        let group = DispatchGroup()
        group.enter()
        
        DispatchQueue.main.async {
            self.persistentContainer.loadPersistentStores { description, error in
                if let error = error {
                    print("CoreData 錯誤: \(error.localizedDescription)")
                    fatalError("無法加載 CoreData 存儲: \(error.localizedDescription)")
                }
                
                // 設置合併策略
                self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
                self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
                
                // 設置並發類型
                self.persistentContainer.viewContext.transactionAuthor = "main"
                self.persistentContainer.viewContext.shouldDeleteInaccessibleFaults = true
                
                // 設置 coordinator
                self.persistentContainer.viewContext.persistentStoreCoordinator.shouldInferMappingModelAutomatically = true
                self.persistentContainer.viewContext.persistentStoreCoordinator.shouldMigrateStoreAutomatically = true
                
                group.leave()
            }
        }
        
        // 等待初始化完成
        group.wait()
        
        // 設置通知觀察者
        setupNotificationObservers()
    }
    
    deinit {
        if let observer = mainContextObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupNotificationObservers() {
        // 監聽主內容的變更
        mainContextObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: persistentContainer.viewContext,
            queue: .main
        ) { [weak self] _ in
            self?.saveContext()
        }
    }
    
    var mainContext: NSManagedObjectContext {
        let context = persistentContainer.viewContext
        if !Thread.isMainThread {
            print("警告：在非主線程訪問主內容")
        }
        return context
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                if Thread.isMainThread {
                    try context.save()
                } else {
                    context.performAndWait {
                        try? context.save()
                    }
                }
            } catch {
                print("儲存 CoreData 內容時發生錯誤: \(error)")
            }
        }
    }
    
    // 創建後台內容
    func backgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }
    
    // 在後台內容執行操作
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = backgroundContext()
        context.perform {
            block(context)
            if context.hasChanges {
                try? context.save()
            }
        }
    }
} 