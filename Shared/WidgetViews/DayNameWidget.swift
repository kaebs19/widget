//
//  DayNameWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - اسم اليوم
struct DayNameWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if size == .small { small } else { medium }
    }

    // التصميم ٠٢: اسم اليوم، وتحته شريط الأسبوع واليوم الحالي مميّز
    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(icon: .asset(.iconCategoryCalendar), title: "اليوم",
                         trailing: "\(DateHelper.gregorianFull(date)) · \(DateHelper.hijriDayMonth(date))")
            Spacer(minLength: 0)
            dayName(height: 64)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            weekStrip
        }
        .widgetContent()
    }

    /// الحرف المميّز لكل يوم، بترتيب Calendar: الأحد = ١
    private static let weekdayLetters = ["ح", "ن", "ث", "ر", "خ", "ج", "س"]

    private var weekStrip: some View {
        let today = DateHelper.gregorian.component(.weekday, from: date) - 1
        return HStack(spacing: 6) {
            ForEach(Self.weekdayLetters.indices, id: \.self) { index in
                let isToday = index == today
                let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
                Text(Self.weekdayLetters[index])
                    .font(style.font(.labelBold, 13))
                    .foregroundStyle(isToday ? style.onPrimary : style.secondary)
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(isToday ? style.primary : style.primary.opacity(0.05), in: shape)
                    .overlay(shape.strokeBorder(style.primary.opacity(isToday ? 0 : 0.1)))
            }
        }
    }

    // التصميم ٠٩: اسم اليوم، وتحته الميلادي ثم الهجري
    private var small: some View {
        VStack(alignment: .leading, spacing: 2) {
            WidgetHeader(icon: .asset(.iconCategoryCalendar), title: "اليوم")
            Spacer(minLength: 0)
            dayName(height: 56)
            Text(style.text(DateHelper.gregorianDayMonth(date)))
                .font(style.font(.labelBold, 14))
                .foregroundStyle(style.primary)
            Text(style.text(DateHelper.hijriDayMonth(date)))
                .font(style.font(.label, 12))
                .foregroundStyle(style.accent)
        }
        .widgetContent()
    }

    /// اسم اليوم بالخط العربي، أو نصاً بخط المستخدم إذا أوقف الخط العربي
    @ViewBuilder
    private func dayName(height: CGFloat) -> some View {
        if style.usesCalligraphy {
            Image(Calligraphy.weekday(for: date))
                .calligraphy(height: height)
                .foregroundStyle(style.primary)
                .accessibilityLabel(DateHelper.weekday(date))
        } else {
            Text(DateHelper.weekday(date))
                .font(style.font(.textBold, height * 0.6))
                .foregroundStyle(style.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}
