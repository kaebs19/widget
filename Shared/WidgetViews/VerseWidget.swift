//
//  VerseWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - آية اليوم
struct VerseWidget: View {
    // بترميز مجمع الملك فهد (QPC) الذي يتطلبه خط حفص: U+0652 للصفر المستدير و U+06E1 للسكون
    var verse = "ٱلَّذِينَ ءَامَنُواْ وَتَطۡمَئِنُّ قُلُوبُهُم بِذِكۡرِ ٱللَّهِ ۗ أَلَا بِذِكۡرِ ٱللَّهِ تَطۡمَئِنُّ ٱلۡقُلُوبُ"
    var surah = "سورة الرعد"
    var ayah = 28
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 12) {
            WidgetHeader(icon: .asset(.iconMushaf), title: "آية اليوم")
            Spacer()
            divider
            // الآية بخط المصحف دائماً، والمستخدم يتحكم بحجمها ولونها فقط
            Text(verse)
                .font(style.font(.quran, 22))
                .foregroundStyle(style.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .minimumScaleFactor(0.7)
            divider
            Spacer()
            HStack {
                Text(surah).font(style.font(.labelBold, 14)).foregroundStyle(style.primary)
                Spacer()
                Text("الآية \(style.number(ayah))")
                    .font(style.font(.label, 11))
                    .foregroundStyle(style.accent)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(Capsule().strokeBorder(style.accent.opacity(0.4)))
            }
        }
        .widgetContent(padding: 16)
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
