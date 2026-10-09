//
//  TasbeehConfiguration.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - إعدادات المستخدم
// تظهر عند الضغط المطوّل على الـ Widget ثم «تعديل الودجت»
nonisolated struct TasbeehIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "عداد الذكر"
    static var description: IntentDescription? { IntentDescription("اختر الذكر الذي تعدّه") }

    @Parameter(title: "الذكر", default: .istighfar)
    var dhikr: TasbeehDhikr

    @Parameter(title: "النمط")
    var style: SavedStyleEntity?
}

// MARK: - الجدول الزمني
nonisolated struct TasbeehEntry: TimelineEntry, Sendable {
    let date: Date
    let dhikr: TasbeehDhikr
    var styleID: UUID? = nil
}

/// العدد يُقرأ عند كل رسم، فالجدول يحتاج فقط بداية كل ساعة (تغطي منتصف الليل فيبدأ العدد من صفر)
nonisolated struct TasbeehProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TasbeehEntry {
        TasbeehEntry(date: .now, dhikr: .istighfar)
    }

    func snapshot(for configuration: TasbeehIntent, in context: Context) async -> TasbeehEntry {
        TasbeehEntry(date: .now, dhikr: configuration.dhikr, styleID: configuration.style?.id)
    }

    func timeline(for configuration: TasbeehIntent, in context: Context) async -> Timeline<TasbeehEntry> {
        let entries = TimelineSchedule.hourly().map {
            TasbeehEntry(date: $0, dhikr: configuration.dhikr, styleID: configuration.style?.id)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - الـ Widget
struct IstighfarHomeWidget: Widget {
    private let kind = WidgetKind.istighfar

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind.rawValue, intent: TasbeehIntent.self, provider: TasbeehProvider()) { entry in
            let style = WidgetStyleStorage.style(for: WidgetKind.istighfar.rawValue, savedStyleID: entry.styleID)
            WidgetPreviewView(kind: .istighfar, date: entry.date, size: .small, style: style,
                              showsBackground: false, tasbeeh: entry.dhikr)
                .containerBackground(for: .widget) { WidgetBackgroundView(background: style.background) }
        }
        .configurationDisplayName(kind.title)
        .description(kind.subtitle)
        .supportedFamilies(kind.supportedSizes.map(\.family))
        .contentMarginsDisabled()
    }
}
