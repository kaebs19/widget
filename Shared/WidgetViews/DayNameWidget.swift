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

    var body: some View {
        if size == .small { small } else { medium }
    }

    private var medium: some View {
        VStack(alignment: .leading) {
            WidgetHeader(icon: .asset(.iconCategoryCalendar), title: "اليوم",
                         trailing: DateHelper.gregorianFull(date))
            Spacer()
            dayCalligraphy(height: 68)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
        }
        .widgetContent()
    }

    // التصميم ٠٩: اسم اليوم بالخط، وتحته الميلادي ثم الهجري
    private var small: some View {
        VStack(alignment: .leading, spacing: 2) {
            WidgetHeader(icon: .asset(.iconCategoryCalendar), title: "اليوم")
            Spacer(minLength: 0)
            dayCalligraphy(height: 56)
            Text(DateHelper.gregorianDayMonth(date))
                .font(AppFont.uiBold(14))
                .foregroundStyle(Theme.textPrimary)
            Text(DateHelper.hijriDayMonth(date))
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.gold)
        }
        .widgetContent()
    }

    private func dayCalligraphy(height: CGFloat) -> some View {
        Image(Calligraphy.weekday(for: date))
            .calligraphy(height: height)
            .foregroundStyle(Theme.textPrimary)
            .accessibilityLabel(DateHelper.weekday(date))
    }
}
