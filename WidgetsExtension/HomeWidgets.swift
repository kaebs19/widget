//
//  HomeWidgets.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - الإعداد المشترك
// كل Widget في الشاشة الرئيسية يقابله نوع في `WidgetKind`، ومنه يأخذ اسمه ووصفه وأحجامه.
// لإضافة Widget جديد: أضف struct هنا ثم سطراً في `WidgetsBundle`.
protocol HomeWidget: Widget {
    static var kind: WidgetKind { get }
}

extension HomeWidget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: Self.kind.rawValue, intent: WidgetStyleIntent.self,
                               provider: WidgetTimelineProvider(kind: Self.kind)) { entry in
            HomeWidgetView(entry: entry)
        }
        .configurationDisplayName(Self.kind.title)
        .description(Self.kind.subtitle)
        .supportedFamilies(Self.kind.supportedSizes.map(\.family) + Self.kind.lockScreenFamilies)
        .contentMarginsDisabled()   // التصميم يضيف هوامشه بنفسه عبر widgetContent()
    }
}

struct HijriDateHomeWidget: HomeWidget { static let kind = WidgetKind.hijriDate }
struct DayNameHomeWidget: HomeWidget { static let kind = WidgetKind.dayName }
struct YearDotsHomeWidget: HomeWidget { static let kind = WidgetKind.yearDots }
struct MorningDhikrHomeWidget: HomeWidget { static let kind = WidgetKind.morningDhikr }
struct DailyVerseHomeWidget: HomeWidget { static let kind = WidgetKind.dailyVerse }
struct RamadanHomeWidget: HomeWidget { static let kind = WidgetKind.ramadan }
struct EidHomeWidget: HomeWidget { static let kind = WidgetKind.eid }
struct NationalDayHomeWidget: HomeWidget { static let kind = WidgetKind.nationalDay }
struct FoundingDayHomeWidget: HomeWidget { static let kind = WidgetKind.foundingDay }
struct NextMatchHomeWidget: HomeWidget { static let kind = WidgetKind.nextMatch }

// MARK: - العرض
// الشاشة الرئيسية: نفس `WidgetPreviewView` اللي يعرضه التطبيق في المعرض، فالتصميم واحد في المكانين.
// شاشة القفل: تصاميم خاصة بلون واحد في `LockScreenWidgetView`.
struct HomeWidgetView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        // الشكل يُقرأ عند كل رسم، فأي تخصيص يحفظه التطبيق يظهر مع أول تحديث
        let style = WidgetStyleStorage.style(for: entry.kind.rawValue, savedStyleID: entry.styleID)
        if family.isLockScreen {
            LockScreenWidgetView(kind: entry.kind, date: entry.date, family: family, style: style)
        } else {
            WidgetPreviewView(kind: entry.kind, date: entry.date, size: WidgetSize(family),
                              style: style, showsBackground: false)
                .containerBackground(for: .widget) { WidgetBackgroundView(background: style.background) }
        }
    }
}

// MARK: - تحويل الأحجام
extension WidgetSize {
    var family: WidgetFamily {
        switch self {
        case .small:  .systemSmall
        case .medium: .systemMedium
        case .large:  .systemLarge
        }
    }

    init(_ family: WidgetFamily) {
        switch family {
        case .systemMedium:                 self = .medium
        case .systemLarge, .systemExtraLarge: self = .large
        default:                            self = .small
        }
    }
}
