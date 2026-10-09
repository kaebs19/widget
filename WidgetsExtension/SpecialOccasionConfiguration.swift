//
//  SpecialOccasionConfiguration.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - إعدادات المستخدم
// تظهر عند الضغط المطوّل على الـ Widget ثم «تعديل الودجت»
struct SpecialOccasionIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "مناسبة خاصة"
    static var description: IntentDescription? { IntentDescription("اكتب اسم مناسبتك وتاريخها") }

    @Parameter(title: "اسم المناسبة", default: "مناسبتي")
    var name: String

    @Parameter(title: "التاريخ")
    var date: Date?

    @Parameter(title: "تتكرر كل سنة", default: true)
    var repeatsYearly: Bool

    @Parameter(title: "ذكّرني قبل يوم", default: false)
    var remindsDayBefore: Bool

    @Parameter(title: "النمط")
    var style: SavedStyleEntity?
}

// MARK: - الجدول الزمني
nonisolated struct SpecialOccasionEntry: TimelineEntry, Sendable {
    let date: Date
    let name: String
    let occasionDate: Date?
    let repeatsYearly: Bool
    var styleID: UUID? = nil
}

nonisolated struct SpecialOccasionProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SpecialOccasionEntry {
        sample(at: .now)
    }

    func snapshot(for configuration: SpecialOccasionIntent, in context: Context) async -> SpecialOccasionEntry {
        // في معرض إضافة الـ Widgets نعرض مثالاً بدل إعدادات فاضية
        context.isPreview ? sample(at: .now) : entry(for: configuration, at: .now)
    }

    func timeline(for configuration: SpecialOccasionIntent, in context: Context) async -> Timeline<SpecialOccasionEntry> {
        // كل تعديل على الودجت يطلب جدولاً جديداً، فنحدّث التذكيرات معه
        await OccasionReminders.sync()
        // عدّاد الساعات يتغيّر كل ساعة
        let entries = TimelineSchedule.hourly().map { entry(for: configuration, at: $0) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(for configuration: SpecialOccasionIntent, at date: Date) -> SpecialOccasionEntry {
        SpecialOccasionEntry(date: date, name: configuration.name,
                             occasionDate: configuration.date, repeatsYearly: configuration.repeatsYearly,
                             styleID: configuration.style?.id)
    }

    private func sample(at date: Date) -> SpecialOccasionEntry {
        SpecialOccasionEntry(date: date, name: "عيد ميلاد سارة",
                             occasionDate: date.addingTimeInterval((13 * 24 + 6) * 3600), repeatsYearly: false)
    }
}

// MARK: - الـ Widget
struct SpecialOccasionHomeWidget: Widget {
    private let kind = WidgetKind.specialOccasion

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind.rawValue, intent: SpecialOccasionIntent.self,
                               provider: SpecialOccasionProvider()) { entry in
            let style = WidgetStyleStorage.style(for: WidgetKind.specialOccasion.rawValue, savedStyleID: entry.styleID)
            SpecialOccasionWidget(name: entry.name, occasionDate: entry.occasionDate,
                                  repeatsYearly: entry.repeatsYearly, date: entry.date)
                .environment(\.widgetStyle, style)
                .environment(\.layoutDirection, .rightToLeft)
                .containerBackground(for: .widget) { WidgetBackgroundView(background: style.background) }
        }
        .configurationDisplayName(kind.title)
        .description(kind.subtitle)
        .supportedFamilies(kind.supportedSizes.map(\.family))
        .contentMarginsDisabled()
    }
}
