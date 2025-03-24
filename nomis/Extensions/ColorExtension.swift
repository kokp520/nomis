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
    
    // 從十六進位字串初始化顏色
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    // 將顏色轉為十六進位字串
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else {
            return nil
        }
        
        let r = components.count > 0 ? components[0] : 0.0
        let g = components.count > 1 ? components[1] : 0.0
        let b = components.count > 2 ? components[2] : 0.0
        
        return String(format: "#%02lX%02lX%02lX",
                     Int(r * 255),
                     Int(g * 255),
                     Int(b * 255))
    }
} 