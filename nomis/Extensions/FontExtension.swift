import SwiftUI

extension Font {
    static func customFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .system(size: size, weight: weight, design: .rounded)
    }
}

struct CustomFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content.font(.customFont(size: size, weight: weight))
    }
}

extension View {
    func customFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(CustomFontModifier(size: size, weight: weight))
    }
} 
