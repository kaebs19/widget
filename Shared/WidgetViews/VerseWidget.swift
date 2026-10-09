//
//  VerseWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - آية اليوم
struct VerseWidget: View {
    let verse: Verse
    var size: WidgetSize = .large
    @Environment(\.widgetStyle) private var style

    /// أطول آية (بعدد الحروف بدون التشكيل) يتسع لها كل حجم دون أن تنقص.
    /// تصغر إذا كبّر المستخدم الخط، فالآية بخط المصحف دائماً ولا يتغيّر إلا حجمها.
    static func maxLetters(for size: WidgetSize, style: WidgetStyle = .default) -> Int {
        let base: Int
        switch size {
        case .small:  base = 40
        case .medium: base = 70
        case .large:  base = 220
        }
        return Int(Double(base) / (style.fontScale * style.fontScale))
    }

    var body: some View {
        VStack(spacing: size == .large ? 12 : 8) {
            WidgetHeader(icon: .asset(.iconMushaf), title: "آية اليوم",
                         trailing: size == .large ? nil : "سورة \(verse.surahName)")
            Spacer(minLength: 0)
            if size == .large { divider }
            // الآية بخط المصحف دائماً، والمستخدم يتحكم بحجمها ولونها فقط
            Text(verse.text)
                .font(style.font(.quran, size == .large ? 22 : 19))
                .foregroundStyle(style.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(size == .large ? 8 : 4)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
            if size == .large { divider }
            Spacer(minLength: 0)
            if size == .large {
                HStack {
                    Text("سورة \(verse.surahName)").font(style.font(.labelBold, 14)).foregroundStyle(style.primary)
                    Spacer()
                    Text("الآية \(style.number(verse.number))")
                        .font(style.font(.label, 11))
                        .foregroundStyle(style.accent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .overlay(Capsule().strokeBorder(style.accent.opacity(0.4)))
                        .widgetAccentable()
                }
            }
        }
        .widgetContent(padding: size == .large ? 16 : 14)
    }

    private var divider: some View {
        HStack(spacing: 8) {
            Rectangle().frame(height: 0.5)
            Image(systemName: "diamond").font(.system(size: 7))
            Rectangle().frame(height: 0.5)
        }
        .foregroundStyle(style.secondary.opacity(0.5))
    }
}

#Preview("أطول آية لكل حجم") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach([WidgetSize.medium, .large], id: \.self) { size in
                let longest = QuranLibrary.bundled.verses
                    .filter { $0.letterCount <= VerseWidget.maxLetters(for: size) }
                    .max { $0.letterCount < $1.letterCount }
                if let longest {
                    VerseWidget(verse: longest, size: size)
                        .frame(width: size.size.width, height: size.size.height)
                        .cardStyle()
                }
            }
        }
        .padding()
    }
    .background(Theme.background)
    .environment(\.layoutDirection, .rightToLeft)
    .preferredColorScheme(.dark)
}
