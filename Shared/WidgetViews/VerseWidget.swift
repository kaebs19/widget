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

    var body: some View {
        VStack(spacing: 12) {
            WidgetHeader(icon: .asset(.iconMushaf), title: "آية اليوم")
            Spacer()
            divider
            Text(verse)
                .font(AppFont.quran(22))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .minimumScaleFactor(0.7)
            divider
            Spacer()
            HStack {
                Text(surah).font(AppFont.uiBold(14)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("الآية \(DateHelper.arabic(ayah))")
                    .font(AppFont.ui(11))
                    .foregroundStyle(Theme.gold)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.4)))
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
        .foregroundStyle(Theme.textSecondary.opacity(0.5))
    }
}
