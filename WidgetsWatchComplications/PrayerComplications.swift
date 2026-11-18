//
//  PrayerComplications.swift
//  WidgetsWatchComplications
//
//  Created by Mohammed Saleh on 28/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - الصلاة القادمة على وجه الساعة
// تُحسب على الساعة بإعدادات الآيفون المحفوظة في المساحة المشتركة، وتتبدّل عند دخول كل وقت.

struct PrayerEntry: TimelineEntry {
    let date: Date
    let moment: PrayerSchedule.Moment?
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: .now, moment: PrayerSchedule.moment(at: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// إدخال الآن وإدخال عند كل وقت صلاة خلال ٢٤ ساعة؛ العد التنازلي والحلقة يتحركان وحدهما بينها
    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        let now = Date.now
        let dates = [now] + PrayerSchedule.transitions(from: now)
        let entries = dates.map { PrayerEntry(date: $0, moment: PrayerSchedule.moment(at: $0)) }
        completion(Timeline(entries: entries, policy: .after(dates.last ?? now.addingTimeInterval(3600))))
    }
}

struct PrayerComplicationView: View {
    let entry: PrayerEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .environment(\.layoutDirection, AppLanguage.current.isRightToLeft ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: AppSettings.numerals == .arabic ? "ar@numbers=arab" : "en"))
            .containerBackground(.clear, for: .widget)
    }

    /// الشروق ليس صلاة، فبعد الفجر ننتظر الظهر
    private var next: PrayerName {
        guard let moment = entry.moment else { return .fajr }
        return moment.next == .sunrise ? .dhuhr : moment.next
    }

    private var nextTime: Date? { entry.moment?.today.time(next) }

    private var timeText: String { nextTime.map(PrayerSchedule.format) ?? "--:--" }

    /// لون التمييز نفسه في التطبيق؛ في الأوجه الملوّنة بلون واحد يأخذ لون الوجه
    private var accent: Color {
        let hex = AppAccent.current.hex.dark
        return Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryCorner:
            Text(timeText)
                .font(.system(size: 20, weight: .semibold).monospacedDigit())
                .widgetCurvesContent()
                .widgetLabel { progress.tint(accent) }
        case .accessoryInline:
            // سطر شاشة القفل نص عادي حتى لا تنعكس الكلمات
            Text("\(next.title) \(timeText)")
        default:
            rectangular
        }
    }

    @ViewBuilder
    private var progress: some View {
        if let moment = entry.moment {
            ProgressView(timerInterval: moment.previousTime...moment.nextTime, countsDown: false) { EmptyView() }
                .environment(\.layoutDirection, .leftToRight)
        }
    }

    private var circular: some View {
        ZStack {
            progress
                .progressViewStyle(.circular)
                .tint(accent)
                .widgetAccentable()
            Image(systemName: next.symbol)
                .font(.system(size: 18, weight: .semibold))
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: next.symbol)
                    .foregroundStyle(accent)
                    .widgetAccentable()
                Text(next.title)
                Spacer(minLength: 2)
                Text(timeText).monospacedDigit()
            }
            .font(.system(size: 15, weight: .semibold))
            if let nextTime {
                Text(timerInterval: entry.date...max(entry.date, nextTime), countsDown: true)
                    .font(.system(size: 22, weight: .bold).monospacedDigit())
                    .environment(\.layoutDirection, .leftToRight)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text(PrayerLocation.current.city)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrayerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "watch.nextPrayer", provider: PrayerProvider()) { entry in
            PrayerComplicationView(entry: entry)
        }
        .configurationDisplayName(L10n.text("الصلاة القادمة"))
        .description(L10n.text("الصلاة القادمة ووقتها والعد التنازلي لها."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct WatchComplications: WidgetBundle {
    var body: some Widget {
        PrayerComplication()
        HijriDateComplication()
        CalligraphyDayComplication()
    }
}
