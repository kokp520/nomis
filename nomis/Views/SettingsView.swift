import SwiftUI

// 卡片視圖元件
private struct CustomCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

struct SettingsView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var sidebarViewModel: SidebarViewModel
    @ObservedObject private var firebaseService = FirebaseService.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingDeleteAlert = false
    @State private var showingExportSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 16) {
                    if let user = authViewModel.user {
                        // 會員資訊卡片
                        CustomCard {
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.name)
                                            .font(.headline)
                                        Text(user.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                Button(role: .destructive) {
                                    authViewModel.signOut()
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                        Text("登出")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // 資料管理卡片
                    CustomCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "externaldrive")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("資料管理")
                                    .font(.headline)
                                Spacer()
                            }

                            Button {
                                showingExportSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("匯出資料")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }

                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("清除所有資料")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(8)
                            }
                        }
                    }

                    // 關於卡片
                    CustomCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("關於")
                                    .font(.headline)
                                Spacer()
                            }

                            HStack {
                                Text("版本")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)

                            Link(destination: URL(string: "https://github.com/yourusername/nomis")!) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("GitHub")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .navigationTitle("設定")
                .background(Color(.systemGroupedBackground))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            sidebarViewModel.showingSidebar.toggle()
                        } label: {
                            Image(systemName: "line.3.horizontal")
                        }
                    }
                }
                
                // 側邊欄
                if sidebarViewModel.showingSidebar {
                    GeometryReader { geometry in
                        SidebarView(
                            firebaseService: firebaseService,
                            showingSidebar: $sidebarViewModel.showingSidebar,
                            showingCreateGroup: $sidebarViewModel.showingCreateGroup,
                            geometry: geometry
                        )
                    }
                    .ignoresSafeArea()
                }
            }
            .alert("確定要清除所有資料？", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) {}
                Button("清除", role: .destructive) {
                    viewModel.clearAllData()
                }
            } message: {
                Text("此操作無法復原")
            }
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [viewModel.exportData()])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

#Preview("一般") {
    SettingsView()
        .environmentObject(TransactionViewModel())
        .environmentObject(AuthViewModel())
        .environmentObject(SidebarViewModel.shared)
}

#Preview("深色模式") {
    SettingsView()
        .environmentObject(TransactionViewModel())
        .environmentObject(AuthViewModel())
        .environmentObject(SidebarViewModel.shared)
        .preferredColorScheme(.dark)
}
