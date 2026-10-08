//
//  Theme.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - الألوان
// كل ألوان التطبيق في مكان واحد. لو غيرت لون هنا، يتغير في التطبيق والودجت مع بعض.
enum Theme {
    static let background    = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let cardTop       = Color(white: 0.17)
    static let cardBottom    = Color(white: 0.10)
    static let border        = Color.white.opacity(0.08)
    static let gold          = Color(red: 0.92, green: 0.80, blue: 0.55)   // #EBCB8B
    static let cream         = Color(red: 0.95, green: 0.93, blue: 0.89)   // زر الاستغفار
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.6)

    static var cardGradient: LinearGradient {
        LinearGradient(colors: [cardTop, cardBottom], startPoint: .top, endPoint: .bottom)
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
