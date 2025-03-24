import SwiftUI

struct SidebarView: View {
    @ObservedObject var firebaseService: FirebaseService
    @Binding var showingSidebar: Bool
    @Binding var showingCreateGroup: Bool
    let geometry: GeometryProxy
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: Group?
    @State private var offset: CGFloat = -UIScreen.main.bounds.width
    @State private var isDragging = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var newGroupName = ""

    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black
                .opacity(max(0, min(0.5, (offset + UIScreen.main.bounds.width) / UIScreen.main.bounds.width * 0.5)))
                .ignoresSafeArea()
                .onTapGesture {
                    closeSidebar()
                }
            
            // 側邊欄內容
            HStack(spacing: 0) {
                VStack(spacing: 30) {
                    // 頂部標題區域
                    HStack {
                        Text("群組")
                            .font(.system(size: 32, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 80)
                    .padding(.bottom, 24)
                    .background(Color(.systemBackground))
                    
                    // 群組列表
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if firebaseService.groups.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.3")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("尚未加入任何群組")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.gray)
                                    Text("建立或加入群組來開始記帳")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                // 我的群組
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("我的群組")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                    
                                    ForEach(firebaseService.groups.filter { $0.owner == firebaseService.currentUser?.id }) { group in
                                        GroupRowView(
                                            group: group,
                                            isSelected: firebaseService.selectedGroup?.id == group.id,
                                            onSelect: {
                                                firebaseService.selectGroup(group)
                                                closeSidebar()
                                            },
                                            onDelete: {
                                                groupToDelete = group
                                                showingDeleteAlert = true
                                            },
                                            canDelete: true
                                        )
                                    }
                                }
                                
                                // 參與的群組
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("參與的群組")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 24)
                                    
                                    ForEach(firebaseService.groups.filter { group in
                                        if let currentUserId = firebaseService.currentUser?.id {
                                            return group.owner != currentUserId && 
                                                   group.members.contains(currentUserId)
                                        }
                                        return false
                                    }) { group in
                                        GroupRowView(
                                            group: group,
                                            isSelected: firebaseService.selectedGroup?.id == group.id,
                                            onSelect: {
                                                firebaseService.selectGroup(group)
                                                closeSidebar()
                                            },
                                            onDelete: {
                                                groupToDelete = group
                                                showingDeleteAlert = true
                                            },
                                            canDelete: false
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    
                    Spacer()
                    
                    Divider()
                    
                    // 底部按鈕區域
                    VStack(spacing: 12) {
                        // 建立新群組按鈕
                        Button(action: {
                            showingCreateGroup = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("建立新群組")
                                    .font(.headline)
                                Spacer()
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                        }
                        
                        // 分類管理按鈕
                        NavigationLink(destination: CategoryManagementView()) {
                            HStack {
                                Image(systemName: "tag.circle.fill")
                                    .font(.title2)
                                Text("分類管理")
                                    .font(.headline)
                                Spacer()
                            }
                            .foregroundColor(.green)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .frame(width: min(UIScreen.main.bounds.width * 0.85, 340))
                .background(Color(.systemBackground))
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            if value.translation.width < 0 {
                                state = value.translation.width
                            }
                        }
                        .onChanged { _ in
                            isDragging = true
                        }
                        .onEnded { value in
                            isDragging = false
                            let threshold = UIScreen.main.bounds.width * 0.2
                            if value.translation.width < -threshold {
                                closeSidebar()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    offset = 0
                                }
                            }
                        }
                )
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                offset = 0
            }
        }
        .sheet(isPresented: $showingCreateGroup) {
            NavigationView {
                Form {
                    Section {
                        TextField("群組名稱", text: $newGroupName)
                    }
                }
                .navigationTitle("建立新群組")
                .navigationBarItems(
                    leading: Button("取消") {
                        showingCreateGroup = false
                        newGroupName = ""
                    },
                    trailing: Button("建立") {
                        Task {
                            do {
                                try await firebaseService.createGroup(name: newGroupName)
                                showingCreateGroup = false
                                newGroupName = ""
                            } catch {
                                print("建立群組時發生錯誤：\(error)")
                            }
                        }
                    }
                    .disabled(newGroupName.isEmpty)
                )
            }
            .presentationDetents([.height(200)])
        }
        .alert("確定要刪除群組？", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("刪除", role: .destructive) {
                if let group = groupToDelete {
                    Task {
                        do {
                            try await firebaseService.deleteGroup(group)
                        } catch {
                            print("刪除群組時發生錯誤：\(error)")
                        }
                    }
                }
            }
        } message: {
            Text("此操作將會刪除群組中的所有交易記錄，且無法復原。")
        }
    }
    
    private func closeSidebar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -UIScreen.main.bounds.width
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showingSidebar = false
        }
    }
}

// 群組列表項目視圖
private struct GroupRowView: View {
    let group: Group
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let canDelete: Bool
    
    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(group.name.prefix(1)))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(isSelected ? .white : .gray)
                        )
                    
                    Text(group.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            
            if canDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
    }
} 