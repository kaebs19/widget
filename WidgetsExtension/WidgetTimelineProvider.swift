//
//  WidgetTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import WidgetKit

// MARK: - إعدادات الودجت
// تظهر عند الضغط المطوّل على الـ Widget ثم «تعديل الودجت»
nonisolated struct WidgetStyleIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "شكل الودجت"
    static var description: IntentDescription? {
        IntentDescription("اختر نمطاً حفظته من التطبيق، أو اتركه فارغاً ليأخذ شكل هذا النوع")
    }

    @Parameter(title: "النمط")
    var style: SavedStyleEntity?
}

nonisolated struct WidgetEntry: TimelineEntry, Sendable {
    let date: Date
    let kind: WidgetKind
    /// النمط الذي اختاره المستخدم لهذه النسخة؛ nil تعني شكل النوع
    var styleID: UUID? = nil
}

/// كل الـ Widgets تُحسب من التاريخ فقط (التقويم، العدادات، الذكر اللي يتبدّل كل ساعة)،
/// فنجهّز مدخلاً عند بداية كل ساعة لـ ٢٤ ساعة قادمة، وبعدها يطلب النظام جدولاً جديداً.
/// بداية الساعة تغطي أيضاً منتصف الليل، فيتغيّر التاريخ في وقته.
nonisolated struct WidgetTimelineProvider: AppIntentTimelineProvider {
    let kind: WidgetKind

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, kind: kind)
    }

    func snapshot(for configuration: WidgetStyleIntent, in context: Context) async -> WidgetEntry {
        WidgetEntry(date: .now, kind: kind, styleID: configuration.style?.id)
    }

    func timeline(for configuration: WidgetStyleIntent, in context: Context) async -> Timeline<WidgetEntry> {
        let styleID = configuration.style?.id
        // ودجات الصلاة تتحدث باستمرار، فنجدّد معها تنبيهات الأذان حتى لو لم يُفتح التطبيق
        if kind.category == .prayer { await PrayerNotifications.reschedule() }
        let dates = kind.category == .prayer ? TimelineSchedule.prayer() : TimelineSchedule.hourly()
        let entries = dates.map { WidgetEntry(date: $0, kind: kind, styleID: styleID) }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

nonisolated enum TimelineSchedule {
    /// الصلاة: كل ٥ دقائق لـ ٦ ساعات (لتتقدم الحلقة)، مع بداية كل وقت صلاة خلال اليوم
    static func prayer(from now: Date = .now) -> [Date] {
        let steps = (0...72).map { now.addingTimeInterval(Double($0) * 300) }
        return (steps + PrayerSchedule.transitions(from: now)).sorted()
    }

    /// الآن، ثم بداية كل ساعة لـ ٢٤ ساعة قادمة
    static func hourly(from now: Date = .now, calendar: Calendar = .current) -> [Date] {
        let currentHour = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        return [now] + (1...24).compactMap { calendar.date(byAdding: .hour, value: $0, to: currentHour) }
    }
}
