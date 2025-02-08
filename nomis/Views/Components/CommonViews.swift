import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        CardView {
            HStack(spacing: 15) {
                // 類別圖標
                ZStack {
                    Circle()
                        .fill(transaction.type == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(transaction.category.icon)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.headline)
                    Text(transaction.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.0f", transaction.amount))
                        .font(.headline)
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 