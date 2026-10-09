//
//  CalendarWidgets.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - ورقة التقويم (صغير)
// شريط علوي بلون التمييز فيه الشهر والسنة واسم اليوم، وتحته رقم اليوم كبيراً
struct TearOffCalendarWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                HStack {
                    Text(style.text(DateHelper.gregorianMonthName(date)))
                    Spacer()
                    Text(style.number(DateHelper.gregorian.component(.year, from: date)))
                }
                .font(style.font(.labelBold, 11))
                Text(DateHelper.weekday(date))
                    .font(style.font(.textBold, 20))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(style.onAccent)
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(style.accent)
            .widgetAccentable()

            Text(style.number(DateHelper.gregorian.component(.day, from: date)))
                .font(style.font(.number, 60))
                .foregroundStyle(style.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - التاريخان (صغير)
// السنتان أعلى، ثم اسم اليوم، ثم اليوم الهجري والميلادي
struct DualDateWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(style.text(DateHelper.hijriYear(date)))
                Spacer()
                Text(style.number(DateHelper.gregorian.component(.year, from: date)))
            }
            .font(style.font(.labelBold, 11))
            .foregroundStyle(style.secondary)

            Text(DateHelper.weekday(date))
                .font(style.font(.textBold, 20))
                .foregroundStyle(style.primary)

            Rectangle()
                .fill(style.primary.opacity(0.15))
                .frame(height: 1)
                .padding(.vertical, 2)

            Spacer(minLength: 0)
            Text(style.text(DateHelper.hijriDayMonth(date)))
                .font(style.font(.textBold, 18))
                .foregroundStyle(style.accent)
                .widgetAccentable()
            Text(style.text(DateHelper.gregorianDayMonth(date)))
                .font(style.font(.textBold, 18))
                .foregroundStyle(style.primary)
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .widgetContent()
    }
}

// MARK: - تقويم الشهر (متوسط)
// شبكة الشهر وبجانبها بطاقة اليوم. الميلادي والهجري بنفس القالب.
struct MonthCalendarWidget: View {
    let date: Date
    let isHijri: Bool
    @Environment(\.widgetStyle) private var style

    var body: some View {
        HStack(spacing: 12) {
            MonthGrid(month: isHijri ? .hijri(date) : .gregorian(date))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            infoCard
                .frame(width: 128)
        }
        .padding(12)
    }

    private var infoCard: some View {
        VStack(spacing: 6) {
            Text(DateHelper.weekday(date))
                .font(style.font(.textBold, 22))
                .foregroundStyle(style.primary)
            Rectangle()
                .fill(style.accent.opacity(0.5))
                .frame(height: 1)
                .widgetAccentable()
            // التاريخ الأساسي أولاً ثم الآخر
            Text(style.text(isHijri ? hijriLine : gregorianLine))
                .font(style.font(.labelBold, 12))
                .foregroundStyle(style.primary)
            Text(style.text(isHijri ? gregorianLine : hijriLine))
                .font(style.font(.label, 11))
                .foregroundStyle(style.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(10)
        .frame(maxHeight: .infinity)
        .background(style.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var hijriLine: String { "\(DateHelper.hijriDayMonth(date)) \(DateHelper.hijriYear(date))" }
    private var gregorianLine: String { DateHelper.gregorianFull(date) }
}

/// أيام شهر واحد: عددها، وأي يوم أسبوع يبدأ به، واليوم الحالي
struct MonthLayout {
    let dayCount: Int
    /// يوم الأسبوع لأول الشهر بترتيب Calendar (الأحد = ١)
    let firstWeekday: Int
    let today: Int

    static func gregorian(_ date: Date) -> MonthLayout {
        let calendar = DateHelper.gregorian
        let start = calendar.dateInterval(of: .month, for: date)?.start ?? date
        return MonthLayout(dayCount: calendar.range(of: .day, in: .month, for: date)?.count ?? 30,
                           firstWeekday: calendar.component(.weekday, from: start),
                           today: calendar.component(.day, from: date))
    }

    /// الشهر الهجري بعد تصحيح المستخدم؛ أيام الأسبوع تُحسب من التاريخ الميلادي الفعلي
    static func hijri(_ date: Date) -> MonthLayout {
        let adjusted = DateHelper.hijriAdjusted(date)
        let calendar = DateHelper.hijri
        let today = calendar.component(.day, from: adjusted)
        let actualStart = DateHelper.gregorian.date(byAdding: .day, value: 1 - today, to: date) ?? date
        return MonthLayout(dayCount: calendar.range(of: .day, in: .month, for: adjusted)?.count ?? 30,
                           firstWeekday: DateHelper.gregorian.component(.weekday, from: actualStart),
                           today: today)
    }
}

struct MonthGrid: View {
    let month: MonthLayout
    @Environment(\.widgetStyle) private var style
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // يبدأ الأسبوع من اليوم المختار في الإعدادات
        let start = AppSettings.weekStart
        let order = (0..<7).map { (start - 1 + $0) % 7 }
        let leading = (month.firstWeekday - start + 7) % 7
        let cells: [Int?] = Array(repeating: nil, count: leading) + (1...month.dayCount).map { $0 }
        let rows = stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<min($0 + 7, cells.count)]) }

        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(order, id: \.self) { index in
                    Text(WeekdayLetters.all[index])
                        .frame(maxWidth: .infinity)
                }
            }
            .font(style.font(.labelBold, 10))
            .foregroundStyle(style.secondary)
            .frame(maxHeight: .infinity)

            ForEach(rows.indices, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        let day = column < rows[row].count ? rows[row][column] : nil
                        dayCell(day)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Int?) -> some View {
        if let day {
            let isToday = day == month.today
            Text(style.number(day))
                .font(style.font(isToday ? .labelBold : .label, 11))
                .foregroundStyle(isToday && renderingMode == .fullColor ? style.onAccent : style.primary)
                .minimumScaleFactor(0.6)
                .frame(width: 20, height: 20)
                .background {
                    if isToday {
                        Circle()
                            .fill(renderingMode == .fullColor ? style.accent : style.accent.opacity(0.35))
                            .widgetAccentable()
                    }
                }
        } else {
            Color.clear
        }
    }
}

/// الحرف المميّز لكل يوم، بترتيب Calendar: الأحد = ١
enum WeekdayLetters {
    static let all = ["ح", "ن", "ث", "ر", "خ", "ج", "س"]
}
