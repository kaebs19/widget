//
//  WidgetTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import WidgetKit

nonisolated struct WidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let kind: WidgetKind
}

/// كل الـ Widgets تُحسب من التاريخ فقط (التقويم، العدادات، الذكر اللي يتبدّل كل ساعة)،
/// فنجهّز مدخلاً عند بداية كل ساعة لـ ٢٤ ساعة قادمة، وبعدها يطلب النظام جدولاً جديداً.
/// بداية الساعة تغطي أيضاً منتصف الليل، فيتغيّر التاريخ في وقته.
nonisolated struct WidgetTimelineProvider: TimelineProvider {
    let kind: WidgetKind

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, kind: kind)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(WidgetEntry(date: .now, kind: kind))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entries = TimelineSchedule.hourly().map { WidgetEntry(date: $0, kind: kind) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

nonisolated enum TimelineSchedule {
    /// الآن، ثم بداية كل ساعة لـ ٢٤ ساعة قادمة
    static func hourly(from now: Date = .now, calendar: Calendar = .current) -> [Date] {
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return [now] + (1...24).compactMap { calendar.date(byAdding: .hour, value: $0, to: currentHour) }
    }
}
