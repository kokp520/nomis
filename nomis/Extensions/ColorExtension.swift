import SwiftUI

extension Color {
    static var adaptiveText: Color {
        Color.primary
    }
    
    static var adaptiveBackground: Color {
        Color(.systemBackground)
    }
    
    static var adaptiveSecondaryText: Color {
        Color.secondary
    }
    
    static var adaptiveGroupedBackground: Color {
        Color(.systemGroupedBackground)
    }
    
    static var adaptiveSeparator: Color {
        Color(.separator)
    }
    
    static var adaptiveOverlay: Color {
        Color.primary.opacity(0.1)
    }
} 