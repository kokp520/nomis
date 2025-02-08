import SwiftUI
import CloudKit
import UIKit

struct ShareExpenseView: View {
    let expense: Expense
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    @State private var share: CKShare?
    @State private var error: Error?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("分享支出記錄")
                .font(.custom("PressStart2P-Regular", size: 18))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("標題: \(expense.title)")
                Text("金額: $\(String(format: "%.2f", expense.amount))")
                Text("類別: \(expense.category.rawValue)")
                Text("日期: \(expense.date.formatted())")
            }
            .font(.custom("PressStart2P-Regular", size: 14))
            .foregroundColor(.green)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
            } else {
                Button(action: shareExpense) {
                    Text("分享")
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
            
            if let error = error {
                Text(error.localizedDescription)
                    .foregroundColor(.red)
                    .font(.custom("PressStart2P-Regular", size: 12))
            }
        }
        .padding()
        .background(Color.black)
        .sheet(isPresented: $showingShareSheet) {
            if let share = share {
                ShareSheet(activityItems: [share])
            }
        }
    }
    
    private func shareExpense() {
        isLoading = true
        CloudKitManager.shared.shareExpense(expense: expense) { share, error in
            isLoading = false
            if let error = error {
                self.error = error
            } else if let share = share {
                self.share = share
                self.showingShareSheet = true
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let previewExpense = Expense(
        title: "預覽支出",
        amount: 100,
        category: .food,
        creatorID: "preview"
    )
    
    return NavigationView {
        ShareExpenseView(expense: previewExpense)
            .environmentObject(CloudKitManager.preview)
    }
} 