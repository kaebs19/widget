//
//  HijriDateWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - التاريخ الهجري
struct HijriDateWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if size == .small { small } else { medium }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(icon: .system("moon"), title: "التاريخ الهجري")
            Spacer()
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    monthName(height: 52)
                    Text(style.text("\(DateHelper.hijriYear(date)) هـ · \(DateHelper.weekday(date))"))
                        .font(style.font(.label, 11))
                        .foregroundStyle(style.accent)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(style.text(DateHelper.hijriDay(date)))
                        .font(style.font(.number, 52))
                        .foregroundStyle(style.primary)
                    Text(style.text(DateHelper.gregorianFull(date)))
                        .font(style.font(.label, 11))
                        .foregroundStyle(style.secondary)
                }
            }
            Spacer()
        }
        .widgetContent()
    }

    // التصميم ٠٨: السنة أعلى، اليوم كبير، والشهر تحته
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "moon")
                Spacer()
                Text(style.text("\(DateHelper.hijriYear(date)) هـ"))
            }
            .font(style.font(.labelBold, 11))
            .foregroundStyle(style.accent)

            Spacer(minLength: 0)
            Text(style.text(DateHelper.hijriDay(date)))
                .font(style.font(.number, 52))
                .foregroundStyle(style.primary)
            monthName(height: 36)
        }
        .widgetContent()
    }

    /// اسم الشهر بالخط العربي، أو نصاً بخط المستخدم إذا أوقف الخط العربي
    @ViewBuilder
    private func monthName(height: CGFloat) -> some View {
        if style.usesCalligraphy {
            Image(Calligraphy.hijriMonth(for: date))
                .calligraphy(height: height)
                .foregroundStyle(style.primary)
                .accessibilityLabel(DateHelper.hijriMonth(date))
        } else {
            Text(DateHelper.hijriMonth(date))
                .font(style.font(.textBold, height * 0.55))
                .foregroundStyle(style.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}
