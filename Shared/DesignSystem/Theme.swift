//
//  Theme.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الألوان
// كل ألوان التطبيق في مكان واحد. لو غيرت لون هنا، يتغير في التطبيق والودجت مع بعض.
// الألوان تتبدّل تلقائياً بين الداكن والفاتح، ولون التمييز يختاره المستخدم من الإعدادات.
enum Theme {
    static let background    = adaptive(dark: 0x121212, light: 0xF4F2EE)
    static let cardTop       = adaptive(dark: 0x2B2B2B, light: 0xFFFFFF)
    static let cardBottom    = adaptive(dark: 0x1A1A1A, light: 0xF7F5F1)
    static let border        = adaptive(dark: 0xFFFFFF, light: 0x000000, opacity: 0.08)
    static let cream         = Color(red: 0.95, green: 0.93, blue: 0.89)   // زر الاستغفار
    static let textPrimary   = adaptive(dark: 0xFFFFFF, light: 0x1C1B19)
    static let textSecondary = adaptive(dark: 0xFFFFFF, light: 0x1C1B19, opacity: 0.6)

    /// لون التمييز. يُقرأ عند كل رسم، والتطبيق يعيد بناء الواجهة عند تغييره
    static var gold: Color {
        let hex = AppAccent.current.hex
        return adaptive(dark: hex.dark, light: hex.light)
    }

    /// نص فوق لون التمييز: أسود فوق الذهبي الفاتح، وأبيض فوق الأغمق في الوضع الفاتح
    static let onAccent = adaptive(dark: 0x000000, light: 0xFFFFFF)

    static var cardGradient: LinearGradient {
        LinearGradient(colors: [cardTop, cardBottom], startPoint: .top, endPoint: .bottom)
    }

    private static func adaptive(dark: UInt32, light: UInt32, opacity: CGFloat = 1) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .light ? light : dark
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: opacity)
        })
    }
}

// MARK: - شكل الكرت
// ViewModifier = "ستايل" تقدر تعيد استخدامه على أي View، مثل الـ CSS class في الويب.
struct CardStyle: ViewModifier {
    var radius: CGFloat = 24

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(Theme.cardGradient, in: shape)
            .overlay(shape.strokeBorder(Theme.border, lineWidth: 1))
            .clipShape(shape)
    }
}

extension View {
    /// يطبق شكل الكرت الداكن بالحدود الشفافة
    func cardStyle(radius: CGFloat = 24) -> some View {
        modifier(CardStyle(radius: radius))
    }

    /// يخلي محتوى الودجت يملأ مساحته ويبدأ من أعلى البداية (اليمين في RTL)
    func widgetContent(padding: CGFloat = 14) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(padding)
    }
}
