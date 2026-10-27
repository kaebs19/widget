//
//  HijriDateComplication.swift
//  WidgetsWatchComplications
//
//  Created by Mohammed Saleh on 28/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - التاريخ الهجري على وجه الساعة
// يتبدّل عند منتصف الليل، والمستطيل يعرض أقرب مناسبة كذلك.

struct HijriDateEntry: TimelineEntry {
    let date: Date
}

struct HijriDateProvider: TimelineProvider {
    func placeholder(in context: Context) -> HijriDateEntry { HijriDateEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (HijriDateEntry) -> Void) {
        completion(HijriDateEntry(date: .now))
    }

    /// اليوم وثلاثة أيام قادمة، كل واحد من منتصف ليله
    func getTimeline(in context: Context, completion: @escaping (Timeline<HijriDateEntry>) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let days = (1...3).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        let entries = [HijriDateEntry(date: .now)] + days.map(HijriDateEntry.init)
        completion(Timeline(entries: entries, policy: .after(days.last ?? today)))
    }
}

struct HijriDateComplicationView: View {
    let entry: HijriDateEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .environment(\.layoutDirection, AppLanguage.current.isRightToLeft ? .rightToLeft : .leftToRight)
            .containerBackground(.clear, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        let date = entry.date
        switch family {
        case .accessoryCircular:
            VStack(spacing: -2) {
                Text(DateHelper.hijriDay(date))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .widgetAccentable()
                Text(DateHelper.hijriMonth(date))
                    .font(.system(size: 9, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(4)
        case .accessoryCorner:
            Text(DateHelper.hijriDay(date))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .widgetCurvesContent()
                .widgetLabel(DateHelper.hijriMonth(date))
        case .accessoryInline:
            // سطر شاشة القفل نص عادي حتى لا تنعكس الكلمات
            Text("\(DateHelper.hijriDayMonth(date)) \(DateHelper.hijriYear(date))")
        default:
            VStack(alignment: .leading, spacing: 1) {
                Text(DateHelper.weekday(date))
                    .font(.system(size: 13, weight: .semibold))
                    .widgetAccentable()
                Text("\(DateHelper.hijriDayMonth(date)) \(DateHelper.hijriYear(date))")
                    .font(.system(size: 16, weight: .bold))
                Text(DateHelper.gregorianFull(date))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if let next = UpcomingOccasions.list(from: date).first {
                    Label("\(next.title) · \(next.remaining)", systemImage: next.symbol)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HijriDateComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "watch.hijriDate", provider: HijriDateProvider()) { entry in
            HijriDateComplicationView(entry: entry)
        }
        .configurationDisplayName(L10n.text("التاريخ الهجري"))
        .description(L10n.text("تاريخ اليوم بالهجري وأقرب مناسبة."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
