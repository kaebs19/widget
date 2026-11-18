//
//  CalligraphyDayComplication.swift
//  WidgetsWatchComplications
//
//  «ويدجت برو» على وجه الساعة: اسم اليوم بخط الرقعة مع التاريخ الهجري.
//  حالة الاشتراك تصل من الآيفون عبر المزامنة (premium.active وتاريخ انتهائه).
//

import SwiftUI
import WidgetKit

private enum WatchPremium {
    static var isActive: Bool {
        let defaults = AppGroup.defaults
        guard defaults.bool(forKey: "premium.active") else { return false }
        guard let expiry = defaults.object(forKey: "premium.expiry") as? Date else { return true }
        return expiry.addingTimeInterval(24 * 3600) > .now
    }
}

struct CalligraphyDayView: View {
    let entry: HijriDateEntry
    @Environment(\.widgetFamily) private var family

    private func ruqaa(_ size: CGFloat) -> Font { .custom("ArefRuqaa-Bold", fixedSize: size) }
    private func number(_ size: CGFloat) -> Font { .custom("Inter-ExtraBold", fixedSize: size) }

    var body: some View {
        Group {
            if WatchPremium.isActive { content } else { locked }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .containerBackground(.clear, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        let date = entry.date
        switch family {
        case .accessoryCircular:
            VStack(spacing: -3) {
                Text(DateHelper.hijriDay(date)).font(number(20)).widgetAccentable()
                Text(DateHelper.hijriMonth(date)).font(ruqaa(12)).lineLimit(1).minimumScaleFactor(0.5)
            }
            .padding(3)
        case .accessoryCorner:
            Text(DateHelper.hijriDay(date))
                .font(number(18))
                .widgetCurvesContent()
                .widgetLabel(DateHelper.weekday(date))
        case .accessoryInline:
            Text("\(DateHelper.weekday(date)) · \(DateHelper.hijriDayMonth(date))")
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(DateHelper.weekday(date))
                    .font(ruqaa(30))
                    .widgetAccentable()
                Text("\(DateHelper.hijriDayMonth(date)) \(DateHelper.hijriYear(date))")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var locked: some View {
        switch family {
        case .accessoryInline: Label(L10n.text("ويدجت برو"), systemImage: "lock.fill")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label(L10n.text("ويدجت برو"), systemImage: "lock.fill").font(.system(size: 14, weight: .semibold))
                Text(L10n.text("اشترك من التطبيق لفتحها")).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default: Image(systemName: "lock.fill").font(.system(size: 18, weight: .semibold))
        }
    }
}

struct CalligraphyDayComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "watch.calligraphyDay", provider: HijriDateProvider()) { entry in
            CalligraphyDayView(entry: entry)
        }
        .configurationDisplayName(L10n.text("اسم اليوم بالخط"))
        .description(L10n.text("اسم اليوم بخط الرقعة مع التاريخ الهجري (ويدجت برو)."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}
