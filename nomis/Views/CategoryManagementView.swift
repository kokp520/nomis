import SwiftUI

struct CategoryManagementView: View {
    @StateObject private var viewModel = CategoryViewModel()
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var showingDeleteAlert = false
    @State private var categoryToDelete: Category?
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("預設分類")) {
                    ForEach(Category.defaultCategories) { category in
                        CategoryRow(category: category, isDefault: true)
                    }
                }
                
                Section(header: Text("自定義分類")) {
                    ForEach(viewModel.categories.filter { $0.groupId != nil }) { category in
                        CategoryRow(category: category, isDefault: false)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    categoryToDelete = category
                                    showingDeleteAlert = true
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                                
                                Button {
                                    editingCategory = category
                                } label: {
                                    Label("編輯", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                    
                    Button {
                        showingAddCategory = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("新增分類")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("分類管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(mode: .add) { newCategory in
                    viewModel.addCategory(newCategory)
                    showingAddCategory = false
                }
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditView(mode: .edit, category: category) { updatedCategory in
                    viewModel.updateCategory(updatedCategory)
                    editingCategory = nil
                }
            }
            .alert("確定要刪除此分類嗎？", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("刪除", role: .destructive) {
                    if let category = categoryToDelete {
                        viewModel.deleteCategory(category)
                    }
                }
            } message: {
                Text("這個操作無法復原，使用此分類的交易將會保留但分類會設為「其他」。")
            }
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let isDefault: Bool
    
    var body: some View {
        HStack {
            Text(category.icon)
                .font(.title)
                .padding(8)
                .background(category.color.opacity(0.2))
                .clipShape(Circle())
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            if isDefault {
                Text("預設")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CategoryEditView: View {
    enum Mode {
        case add
        case edit
    }
    
    let mode: Mode
    var category: Category?
    let onSave: (Category) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedIcon: String = "📦"
    @State private var selectedColor: Color = .gray
    
    private let availableIcons = ["🍽️", "🚗", "🎮", "🛍️", "💰", "📈", "📦", "🏠", "📱", "👕", "💄", "🍺", "🎬", "🎵", "✈️", "🏥", "📚", "💼", "🧾", "💊", "🧪", "⚽️", "🏆", "🎨", "🧶", "🔧", "⚙️", "🧰", "🚿", "🧹", "🛌", "🎁", "🎊", "🎂", "🎯", "🎲", "🎭", "🎟️", "🎫", "🖼️", "🖥️", "📞", "📨", "📝", "🧾", "🗓️", "⏰", "☂️", "🧤", "👓", "👜", "🧢", "👞"]
    
    private let availableColors: [Color] = [.red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .gray, .brown]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("分類資訊")) {
                    TextField("名稱", text: $name)
                    
                    HStack {
                        Text("圖示")
                        Spacer()
                        Menu {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Text(icon)
                                            .font(.title2)
                                    }
                                }
                            }
                        } label: {
                            Text(selectedIcon)
                                .font(.title2)
                                .padding(8)
                                .background(selectedColor.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    
                    HStack {
                        Text("顏色")
                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(availableColors, id: \.self) { color in
                                    Circle()
                                        .fill(color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(color == selectedColor ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture {
                                            selectedColor = color
                                        }
                                }
                            }
                        }
                        .frame(height: 40)
                    }
                }
                
                Section {
                    HStack {
                        Spacer()
                        Button(mode == .add ? "新增" : "儲存") {
                            let newCategory = Category(
                                id: category?.id ?? UUID().uuidString,
                                name: name,
                                icon: selectedIcon,
                                color: selectedColor,
                                groupId: category?.groupId
                            )
                            onSave(newCategory)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Spacer()
                    }
                }
            }
            .navigationTitle(mode == .add ? "新增分類" : "編輯分類")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let existingCategory = category {
                    name = existingCategory.name
                    selectedIcon = existingCategory.icon
                    selectedColor = existingCategory.color
                }
            }
        }
    }
}

struct CategoryManagementView_Previews: PreviewProvider {
    static var previews: some View {
        CategoryManagementView()
    }
} 