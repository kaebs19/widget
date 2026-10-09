//
//  NationalDayWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - اليوم الوطني
struct NationalDayWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    private var next: Date { DateHelper.nextGregorian(month: 9, day: 23, from: date) }
    private var days: Int { DateHelper.daysUntilGregorian(month: 9, day: 23, from: date) }
    /// الترقيم الرسمي: اليوم الوطني ٩٣ كان في ٢٠٢٣
    private var edition: Int { DateHelper.gregorian.component(.year, from: next) - 1930 }

    var body: some View {
        if size == .small {
            CountdownWidget(title: DateHelper.gregorianDayMonth(next), icon: .asset(.iconPalmSwords),
                            days: days, name: "اليوم الوطني \(DateHelper.arabic(edition))")
        } else {
            medium
        }
    }

    // التصميم ١٥: الاسم وشعاره، والعدد بجانبه، وشريط الانتظار أسفل
    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(style.accent).frame(width: 7, height: 7).widgetAccentable()
                Text(style.text("اليوم الوطني \(DateHelper.arabic(edition))"))
                Spacer()
                Text(style.text(DateHelper.weekdayFull(next)))
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)

            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("اليوم الوطني")
                        .font(style.font(.textBold, 30))
                        .foregroundStyle(style.primary)
                    Text("هي لنا دار")
                        .font(style.font(.labelBold, 13))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                if days == 0 {
                    Text("اليوم")
                        .font(style.font(.textBold, 30))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(style.number(days))
                            .font(style.font(.number, 46))
                            .foregroundStyle(style.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .widgetAccentable()
                        Text("يومًا")
                            .font(style.font(.label, 12))
                            .foregroundStyle(style.secondary)
                    }
                }
            }
            Spacer(minLength: 0)

            ProgressView(value: DateHelper.progressUntilGregorian(month: 9, day: 23, from: date))
                .tint(style.accent)
                .widgetAccentable()
        }
        .widgetContent()
    }
}
