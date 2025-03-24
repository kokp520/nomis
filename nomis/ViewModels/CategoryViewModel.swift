import SwiftUI
import FirebaseFirestore
import Combine

@MainActor
class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private var firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 當選擇的群組發生變化時，重新載入該群組的分類
        NotificationCenter.default
            .publisher(for: .selectedGroupChanged)
            .sink { [weak self] _ in
                self?.loadCategories()
            }
            .store(in: &cancellables)
        
        // 初始載入分類
        loadCategories()
    }
    
    // 載入目前選擇群組的分類
    func loadCategories() {
        // 先加載預設分類
        categories = Category.defaultCategories
        
        // 如果有選擇群組，則加載該群組的自定義分類
        guard let selectedGroup = firebaseService.selectedGroup else {
            return
        }
        
        Task {
            do {
                let customCategories = try await firebaseService.fetchCategories(groupID: selectedGroup.id)
                
                // 更新 UI
                await MainActor.run {
                    // 添加自定義分類，保留預設分類
                    for customCategory in customCategories {
                        if !self.categories.contains(where: { $0.id == customCategory.id }) {
                            self.categories.append(customCategory)
                        }
                    }
                }
            } catch {
                print("DEBUG: 載入分類時發生錯誤: \(error)")
            }
        }
    }
    
    // 添加新分類
    func addCategory(_ category: Category) {
        guard let selectedGroup = firebaseService.selectedGroup else {
            print("DEBUG: 無法添加分類：未選擇群組")
            return
        }
        
        // 建立帶有群組 ID 的新分類
        var newCategory = category
        newCategory.groupId = selectedGroup.id
        
        Task {
            do {
                try await firebaseService.addCategory(newCategory, groupID: selectedGroup.id)
                
                // 更新 UI
                await MainActor.run {
                    if !self.categories.contains(where: { $0.id == newCategory.id }) {
                        self.categories.append(newCategory)
                    }
                }
            } catch {
                print("DEBUG: 保存分類時發生錯誤: \(error)")
            }
        }
    }
    
    // 刪除分類
    func deleteCategory(_ category: Category) {
        // 檢查是否為預設分類
        if Category.defaultCategories.contains(where: { $0.id == category.id }) {
            print("DEBUG: 無法刪除預設分類")
            return
        }
        
        guard let groupId = category.groupId,
              let selectedGroup = firebaseService.selectedGroup,
              selectedGroup.id == groupId else {
            print("DEBUG: 無法刪除分類：不屬於當前群組")
            return
        }
        
        Task {
            do {
                try await firebaseService.deleteCategory(category.id, groupID: groupId)
                
                // 更新 UI
                await MainActor.run {
                    self.categories.removeAll { $0.id == category.id }
                }
            } catch {
                print("DEBUG: 刪除分類時發生錯誤: \(error)")
            }
        }
    }
    
    // 更新分類
    func updateCategory(_ category: Category) {
        // 檢查是否為預設分類
        if Category.defaultCategories.contains(where: { $0.id == category.id }) {
            print("DEBUG: 無法修改預設分類")
            return
        }
        
        guard let groupId = category.groupId,
              let selectedGroup = firebaseService.selectedGroup,
              selectedGroup.id == groupId else {
            print("DEBUG: 無法更新分類：不屬於當前群組")
            return
        }
        
        Task {
            do {
                try await firebaseService.updateCategory(category, groupID: groupId)
                
                // 更新 UI
                await MainActor.run {
                    if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
                        self.categories[index] = category
                    }
                }
            } catch {
                print("DEBUG: 更新分類時發生錯誤: \(error)")
            }
        }
    }
    
    // 根據類型篩選分類
    func categoriesForType(_ type: TransactionType) -> [Category] {
        switch type {
        case .income:
            return categories.filter { $0 == Category.salary || $0 == Category.investment || $0 == Category.other }
        case .expense:
            return categories.filter { $0 != Category.salary && $0 != Category.investment }
        }
    }
}

// 用於通知選擇的群組已經變化
extension Notification.Name {
    static let selectedGroupChanged = Notification.Name("selectedGroupChanged")
}

#if DEBUG
extension CategoryViewModel {
    static var preview: CategoryViewModel {
        @MainActor get {
            let viewModel = CategoryViewModel()
            viewModel.categories = Category.defaultCategories
            return viewModel
        }
    }
}
#endif 