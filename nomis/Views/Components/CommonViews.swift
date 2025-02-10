import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) var colorScheme
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.adaptiveBackground)
            .cornerRadius(15)
            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
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
                        .font(.title)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .font(.subheadline)
                        .foregroundColor(.adaptiveText)
                    Text(transaction.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.adaptiveSecondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.0f", transaction.amount))
                        .font(.callout)
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.adaptiveSecondaryText)
                }
            }
        }
        .padding(.vertical, 1)
    }
} 