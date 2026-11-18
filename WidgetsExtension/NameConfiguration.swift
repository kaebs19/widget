//
//  NameConfiguration.swift
//  WidgetsExtension
//
//  «تعديل الودجت» لودجات الأيام والشهور: كل نسخة على الشاشة تختار خطها أو تخطيطها أو مناسبتها،
//  فتقدر تضع اسم اليوم بالنسخ وآخر بالكوفي جنباً إلى جنب. الخيار الفارغ يأخذ المحفوظ في التطبيق.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - الاختيارات
extension NameShape: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "الخط"
    static let caseDisplayRepresentations: [NameShape: DisplayRepresentation] = [
        .naskh: "نسخ مشكّل", .ruqaa: "رقعة ورقي", .nastaliq: "نستعليق ذهبي",
        .kufi: "كوفي + إنجليزي", .dots: "هندسي نقطي", .english: "English",
    ]
}

extension NameCalendar: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "التقويم"
    static let caseDisplayRepresentations: [NameCalendar: DisplayRepresentation] = [.hijri: "هجري", .gregorian: "ميلادي"]
}

extension DayNumberLayout: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "التخطيط"
    static let caseDisplayRepresentations: [DayNumberLayout: DisplayRepresentation] = [
        .behind: "الرقم خلف الاسم", .beside: "الرقم بجانب الاسم", .above: "اليوم فوق الرقم",
    ]
}

extension MonthNumberLayout: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "التخطيط"
    static let caseDisplayRepresentations: [MonthNumberLayout: DisplayRepresentation] = [
        .beside: "الرقم بجانب الشهر", .above: "الرقم فوق الشهر",
    ]
}

extension HijriTarget: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "المناسبة"
    static let caseDisplayRepresentations: [HijriTarget: DisplayRepresentation] = [
        .ramadan: "رمضان", .eidFitr: "عيد الفطر", .arafah: "يوم عرفة",
        .eidAdha: "عيد الأضحى", .newYear: "رأس السنة الهجرية", .ashura: "عاشوراء",
    ]
}

// MARK: - النوايا
protocol NameIntent: WidgetConfigurationIntent {
    var style: SavedStyleEntity? { get }
    /// يطبّق ما اختاره المستخدم لهذه النسخة فوق المحفوظ في التطبيق
    func apply(to options: inout NameOptions)
}

nonisolated struct NameScriptIntent: NameIntent {
    static let title: LocalizedStringResource = "الخط"
    static var description: IntentDescription? { IntentDescription("اختر خط هذا الودجت، أو اتركه ليأخذ اختيار التطبيق") }
    @Parameter(title: "الخط") var shape: NameShape?
    @Parameter(title: "النمط") var style: SavedStyleEntity?
    func apply(to options: inout NameOptions) { if let shape { options.shape = shape } }
}

nonisolated struct NameCalendarIntent: NameIntent {
    static let title: LocalizedStringResource = "التقويم"
    static var description: IntentDescription? { IntentDescription("هجري أو ميلادي، أو اتركه ليأخذ اختيار التطبيق") }
    @Parameter(title: "التقويم") var calendar: NameCalendar?
    @Parameter(title: "النمط") var style: SavedStyleEntity?
    func apply(to options: inout NameOptions) { if let calendar { options.calendar = calendar } }
}

nonisolated struct DayLayoutIntent: NameIntent {
    static let title: LocalizedStringResource = "التخطيط"
    static var description: IntentDescription? { IntentDescription("طريقة عرض اسم اليوم ورقمه") }
    @Parameter(title: "التخطيط") var layout: DayNumberLayout?
    @Parameter(title: "النمط") var style: SavedStyleEntity?
    func apply(to options: inout NameOptions) { if let layout { options.dayLayout = layout } }
}

nonisolated struct MonthLayoutIntent: NameIntent {
    static let title: LocalizedStringResource = "التخطيط"
    static var description: IntentDescription? { IntentDescription("التقويم وطريقة عرض الشهر ورقمه") }
    @Parameter(title: "التقويم") var calendar: NameCalendar?
    @Parameter(title: "التخطيط") var layout: MonthNumberLayout?
    @Parameter(title: "النمط") var style: SavedStyleEntity?
    func apply(to options: inout NameOptions) {
        if let calendar { options.calendar = calendar }
        if let layout { options.monthLayout = layout }
    }
}

nonisolated struct HijriTargetIntent: NameIntent {
    static let title: LocalizedStringResource = "المناسبة"
    static var description: IntentDescription? { IntentDescription("المناسبة الهجرية التي يعدّ لها الودجت") }
    @Parameter(title: "المناسبة") var target: HijriTarget?
    @Parameter(title: "النمط") var style: SavedStyleEntity?
    func apply(to options: inout NameOptions) { if let target { options.target = target } }
}

// MARK: - الجدول
nonisolated struct NameProvider<Intent: NameIntent>: AppIntentTimelineProvider {
    let kind: WidgetKind

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: .now, kind: kind, nameOptions: NameOptions.load(for: kind))
    }

    func snapshot(for configuration: Intent, in context: Context) async -> WidgetEntry {
        entry(at: .now, configuration)
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<WidgetEntry> {
        await Premium.refresh()
        return Timeline(entries: TimelineSchedule.hourly().map { entry(at: $0, configuration) }, policy: .atEnd)
    }

    private func entry(at date: Date, _ configuration: Intent) -> WidgetEntry {
        var options = NameOptions.load(for: kind)
        configuration.apply(to: &options)
        return WidgetEntry(date: date, kind: kind, styleID: configuration.style?.id, nameOptions: options)
    }
}

// MARK: - الـ Widgets
protocol NameHomeWidget: Widget {
    associatedtype Intent: NameIntent
    static var kind: WidgetKind { get }
}

extension NameHomeWidget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind.rawValue, intent: Intent.self, provider: NameProvider<Intent>(kind: Self.kind)) { entry in
            HomeWidgetView(entry: entry)
        }
        .configurationDisplayName(Self.kind.title)
        .description(Self.kind.subtitle)
        .supportedFamilies(Self.kind.supportedSizes.map(\.family) + Self.kind.lockScreenFamilies)
        .contentMarginsDisabled()
    }
}

struct StyledDayHomeWidget: NameHomeWidget { typealias Intent = NameScriptIntent; static let kind = WidgetKind.styledDay }
struct StyledHijriMonthHomeWidget: NameHomeWidget { typealias Intent = NameScriptIntent; static let kind = WidgetKind.styledHijriMonth }
struct StyledGregorianMonthHomeWidget: NameHomeWidget { typealias Intent = NameScriptIntent; static let kind = WidgetKind.styledGregorianMonth }
struct MonthBehindHomeWidget: NameHomeWidget { typealias Intent = NameCalendarIntent; static let kind = WidgetKind.monthBehind }
struct DayNumberHomeWidget: NameHomeWidget { typealias Intent = DayLayoutIntent; static let kind = WidgetKind.dayNumber }
struct MonthNumberHomeWidget: NameHomeWidget { typealias Intent = MonthLayoutIntent; static let kind = WidgetKind.monthNumber }
struct HijriCountdownHomeWidget: NameHomeWidget { typealias Intent = HijriTargetIntent; static let kind = WidgetKind.hijriCountdown }
