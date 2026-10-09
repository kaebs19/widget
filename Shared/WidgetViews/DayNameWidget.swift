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

    private var medium: some View {
        VStack(alignment: .leading) {
            WidgetHeader(icon: .asset(.iconCategoryCalendar), title: "اليوم",
                         trailing: DateHelper.gregorianFull(date))
            Spacer()
            dayName(height: 68)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .widgetContent()
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
