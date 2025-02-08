import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: TransactionViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingDeleteAlert = false
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section("外觀") {
                    Toggle("深色模式", isOn: $isDarkMode)
                }
                
                Section("資料") {
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("匯出資料", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("清除所有資料", systemImage: "trash")
                    }
                }
                
                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/yourusername/nomis")!) {
                        Label("GitHub", systemImage: "link")
                    }
                }
            }
            .navigationTitle("設定")
            .alert("確定要清除所有資料？", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
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
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("一般") {
    SettingsView()
        .environmentObject(TransactionViewModel())
}

#Preview("深色模式") {
    SettingsView()
        .environmentObject(TransactionViewModel())
        .preferredColorScheme(.dark)
} 