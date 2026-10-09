//
//  DayNameWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - اسم اليوم
struct DayNameWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style
    @Environment(\.widgetRenderingMode) private var renderingMode

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


    private var weekStrip: some View {
        let today = DateHelper.gregorian.component(.weekday, from: date) - 1
        // يبدأ الشريط من اليوم المختار في الإعدادات
        let start = AppSettings.weekStart - 1
        let order = (0..<7).map { (start + $0) % 7 }
        return HStack(spacing: 6) {
            ForEach(order, id: \.self) { index in
                let isToday = index == today
                // الوضع الملوّن يرسم كل شيء بلون واحد، فالنص الداكن فوق اليوم الحالي يختفي؛ نكتفي بإطار ملوّن
                let isFilled = isToday && renderingMode == .fullColor
                let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
                Text(WeekdayLetters.all[index])
                    .font(style.font(.labelBold, 13))
                    .foregroundStyle(isFilled ? style.onPrimary : isToday ? style.primary : style.secondary)
                    .frame(maxWidth: .infinity, minHeight: 28)
                    .background(isFilled ? style.primary : style.primary.opacity(0.05), in: shape)
                    .overlay(shape.strokeBorder(style.primary.opacity(isFilled ? 0 : isToday ? 0.9 : 0.1),
                                                lineWidth: isToday ? 1.5 : 1))
                    .widgetAccentable(isToday)
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
    private func dayName(height: CGFloat) -> some View {
        dayNameContent(height: height).widgetAccentable()
    }

    @ViewBuilder
    private func dayNameContent(height: CGFloat) -> some View {
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
