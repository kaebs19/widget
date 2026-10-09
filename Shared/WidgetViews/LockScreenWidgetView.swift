//
//  LockScreenWidgetView.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

extension WidgetKind {
    /// أحجام شاشة القفل لكل نوع (التصاميم ٢٢–٢٥ وما بُني عليها)
    var lockScreenFamilies: [WidgetFamily] {
        switch self {
        case .hijriDate:                     [.accessoryRectangular, .accessoryInline, .accessoryCircular]
        case .dayName:                       [.accessoryRectangular, .accessoryInline, .accessoryCircular]
        case .yearDots:                      [.accessoryCircular, .accessoryInline]
        case .morningDhikr:                  [.accessoryRectangular]
        case .ramadan, .eid, .nationalDay, .foundingDay:
                                             [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        case .istighfar:                     [.accessoryCircular, .accessoryRectangular]
        case .specialOccasion:               [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        default:                             []
        }
    }
}

extension WidgetFamily {
    var isLockScreen: Bool {
        switch self {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline: true
        default: false
        }
    }
}

// MARK: - شاشة القفل
// النظام يلوّن شاشة القفل بلون واحد، فالتمييز يكون بالوزن والشفافية (.secondary) لا بالألوان.
// الخطوط وشكل الأرقام من تخصيص المستخدم، فتطابق ودجات الشاشة الرئيسية.
struct LockScreenWidgetView: View {
    let kind: WidgetKind
    let date: Date
    let family: WidgetFamily
    var style: WidgetStyle = .default

    /// المستطيل يتسع لسطرين قصيرين فقط
    private static let dhikrMaxLetters = 40

    var body: some View {
        content
            .lockScreenContainer(family: family)
    }

    @ViewBuilder
    private var content: some View {
        switch (kind, family) {
        case (.hijriDate, .accessoryInline):
            // السطر الواحد يقبل نصاً وأيقونة فقط، وبخط النظام واتجاه لغة الجهاز.
            // نص عادي (لا LocalizedStringKey) حتى لا تُعزل أجزاؤه فينقلب ترتيبها، و\u{200F} يثبّته من اليمين.
            Label(LockText.inline(style.text(DateHelper.hijriDayMonth(date) + " " + DateHelper.hijriYear(date))),
                  systemImage: "moon")
        case (.hijriDate, .accessoryCircular):
            hijriCircular
        case (.hijriDate, _):
            hijriRectangular
        case (.dayName, .accessoryInline):
            Label(LockText.inline(style.text(DateHelper.weekdayDayMonth(date))), systemImage: "calendar")
        case (.dayName, .accessoryCircular):
            dayNameCircular
        case (.dayName, _):
            dayNameRectangular
        case (.yearDots, .accessoryInline):
            let progress = DateHelper.yearProgress(date)
            Label(LockText.inline(style.text("مضى ٪\(DateHelper.arabic(progress.percent)) من \(DateHelper.arabic(DateHelper.gregorian.component(.year, from: date)))")),
                  systemImage: "circle.grid.3x3")
        case (.yearDots, _):
            yearCircular
        case (.morningDhikr, _):
            dhikrRectangular
        case (.ramadan, _), (.eid, _), (.nationalDay, _), (.foundingDay, _):
            if let countdown = LockCountdown(kind: kind, date: date) {
                LockCountdownView(countdown: countdown, family: family, style: style)
            }
        default:
            EmptyView()
        }
    }

    // التصميم ٢٣
    private var hijriRectangular: some View {
        VStack(alignment: .leading, spacing: 0) {
            Label(DateHelper.weekday(date), systemImage: "moon")
                .font(style.font(.labelBold, 14))
            Text(style.text(DateHelper.hijriDayMonth(date)))
                .font(style.font(.textBold, 17))
            Text(style.text("\(DateHelper.hijriYear(date)) هـ · \(DateHelper.gregorianDayMonth(date))"))
                .font(style.font(.label, 12))
                .foregroundStyle(.secondary)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hijriCircular: some View {
        VStack(spacing: -2) {
            Text(style.text(DateHelper.hijriDay(date)))
                .font(style.font(.number, 22))
            Image(Calligraphy.hijriMonth(for: date))
                .calligraphy(height: 14)
        }
        .minimumScaleFactor(0.6)
    }

    private var dayNameRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(Calligraphy.weekday(for: date))
                .calligraphy(height: 30)
                .accessibilityLabel(DateHelper.weekday(date))
            Text(style.text("\(DateHelper.gregorianDayMonth(date)) · \(DateHelper.hijriDayMonth(date))"))
                .font(style.font(.label, 12))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dayNameCircular: some View {
        VStack(spacing: 0) {
            Image(Calligraphy.weekday(for: date))
                .calligraphy(height: 20)
            Text(style.text(DateHelper.arabic(DateHelper.gregorian.component(.day, from: date))))
                .font(style.font(.number, 15))
        }
        .accessibilityLabel(DateHelper.weekdayDayMonth(date))
    }

    private var yearCircular: some View {
        let progress = DateHelper.yearProgress(date)
        return Gauge(value: Double(progress.dayOfYear), in: 0...Double(progress.totalDays)) {
            EmptyView()
        } currentValueLabel: {
            VStack(spacing: -1) {
                Text(style.text("٪\(DateHelper.arabic(progress.percent))"))
                    .font(style.font(.number, 15))
                Text(style.number(DateHelper.gregorian.component(.year, from: date)))
                    .font(style.font(.label, 8))
            }
            .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    // التصميم ٢٤
    @ViewBuilder
    private var dhikrRectangular: some View {
        if let zikr = AzkarLibrary.bundled.rotatingZikr(in: ZikrGroup.morningID, at: date,
                                                         maxLetters: Self.dhikrMaxLetters) {
            VStack(alignment: .leading, spacing: 0) {
                Label("ذكر الصباح", systemImage: "sun.max")
                    .font(style.font(.label, 11))
                    .foregroundStyle(.secondary)
                Text(zikr.text)
                    .font(style.font(.text, 16))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let repeatLabel = DhikrWidget.repeatLabel(zikr.repeatCount) {
                    Text(style.text(repeatLabel))
                        .font(style.font(.label, 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - العدّادات
/// بيانات أي عدّاد تنازلي على شاشة القفل: رمضان، العيد، المناسبات الوطنية، المناسبة الخاصة
struct LockCountdown {
    let title: String
    let symbol: String
    let days: Int
    /// كم مضى من الانتظار (٠–١)؛ بدونه تظهر الدائرة بلا حلقة
    var progress: Double? = nil
    var detail: String? = nil

    init(title: String, symbol: String, days: Int, progress: Double? = nil, detail: String? = nil) {
        self.title = title
        self.symbol = symbol
        self.days = days
        self.progress = progress
        self.detail = detail
    }

    init?(kind: WidgetKind, date: Date) {
        switch kind {
        case .ramadan:
            let next = DateHelper.nextHijri(month: 9, day: 1, from: date)
            self.init(title: "رمضان", symbol: "moon.stars.fill",
                      days: DateHelper.daysUntilHijri(month: 9, day: 1, from: date),
                      progress: DateHelper.progressUntilHijri(month: 9, day: 1, from: date),
                      detail: "≈ \(DateHelper.gregorianFull(next))")
        case .eid:
            let eid = DateHelper.nextEid(from: date)
            self.init(title: eid.name, symbol: "sparkles", days: eid.days,
                      detail: "≈ \(DateHelper.gregorianFull(eid.date))")
        case .nationalDay:
            self.init(title: "اليوم الوطني", symbol: "flag.fill",
                      days: DateHelper.daysUntilGregorian(month: 9, day: 23, from: date),
                      progress: DateHelper.progressUntilGregorian(month: 9, day: 23, from: date),
                      detail: DateHelper.weekdayFull(DateHelper.nextGregorian(month: 9, day: 23, from: date)))
        case .foundingDay:
            self.init(title: "يوم التأسيس", symbol: "flag.fill",
                      days: DateHelper.daysUntilGregorian(month: 2, day: 22, from: date),
                      progress: DateHelper.progressUntilGregorian(month: 2, day: 22, from: date),
                      detail: DateHelper.weekdayFull(DateHelper.nextGregorian(month: 2, day: 22, from: date)))
        default:
            return nil
        }
    }
}

struct LockCountdownView: View {
    let countdown: LockCountdown
    let family: WidgetFamily
    var style: WidgetStyle = .default

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(LockText.inline(inlineText), systemImage: countdown.symbol)
        case .accessoryCircular:
            circular
        default:
            rectangular
        }
    }

    private var inlineText: String {
        countdown.days == 0 ? "\(countdown.title) اليوم" : style.text("\(countdown.title) بعد \(DateHelper.arabic(countdown.days)) يوم")
    }

    @ViewBuilder
    private var circular: some View {
        let center = VStack(spacing: 0) {
            Image(systemName: countdown.symbol)
                .font(.system(size: 9))
            Text(countdown.days == 0 ? "اليوم" : style.number(countdown.days))
                .font(style.font(.number, countdown.days == 0 ? 13 : 17))
                .minimumScaleFactor(0.5)
            if countdown.days > 0 {
                Text("يوم").font(style.font(.label, 9))
            }
        }
        if let progress = countdown.progress {
            Gauge(value: progress) { EmptyView() } currentValueLabel: { center }
                .gaugeStyle(.accessoryCircularCapacity)
        } else {
            center
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(countdown.title, systemImage: countdown.symbol)
                .font(style.font(.labelBold, 13))
                .lineLimit(1)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(countdown.days == 0 ? "اليوم" : style.number(countdown.days))
                    .font(style.font(.number, 22))
                if countdown.days > 0 {
                    Text("يوم متبقٍ").font(style.font(.label, 11)).foregroundStyle(.secondary)
                }
            }
            if let progress = countdown.progress {
                ProgressView(value: progress)
            } else if let detail = countdown.detail {
                Text(style.text(detail))
                    .font(style.font(.label, 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - عدّاد الذكر
/// العدّاد على شاشة القفل: الضغط على الدائرة يعدّ مباشرة بدون فتح الجهاز
struct TasbeehLockView: View {
    let dhikr: TasbeehDhikr
    let date: Date
    let family: WidgetFamily
    let style: WidgetStyle

    private var count: Int { TasbeehCounter.count(of: dhikr, on: date) }

    var body: some View {
        Button(intent: IncrementIstighfarIntent(dhikr: dhikr)) {
            if family == .accessoryCircular { circular } else { rectangular }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dhikr.title)
    }

    @ViewBuilder
    private var circular: some View {
        let center = VStack(spacing: -1) {
            Text(style.number(count))
                .font(style.font(.number, 18))
                .minimumScaleFactor(0.5)
            Image(systemName: "plus").font(.system(size: 9, weight: .bold))
        }
        if let goal = dhikr.goal {
            Gauge(value: Double(min(count, goal)), in: 0...Double(goal)) { EmptyView() } currentValueLabel: { center }
                .gaugeStyle(.accessoryCircularCapacity)
        } else {
            center
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(dhikr.title).font(style.font(.labelBold, 12))
                Spacer()
                Image(systemName: "plus.circle.fill").font(.system(size: 16))
            }
            Text(dhikr.isLong ? "لا إله إلا الله وحده" : dhikr.text)
                .font(style.font(.textBold, 15))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(style.number(count)).font(style.font(.number, 15))
                if let goal = dhikr.goal {
                    Text("/ \(style.number(goal))").font(style.font(.label, 10)).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - مساعدات
enum LockText {
    /// السطر الواحد بخط النظام: نص عادي يبدأ بعلامة RTL حتى لا ينقلب ترتيب كلماته
    static func inline(_ text: String) -> String { "\u{200F}" + text }
}

extension View {
    /// اتجاه عربي، وخلفية الدائرة التي يرسمها النظام لودجات الدائرة فقط
    func lockScreenContainer(family: WidgetFamily) -> some View {
        environment(\.layoutDirection, .rightToLeft)
            .containerBackground(for: .widget) {
                if family == .accessoryCircular { AccessoryWidgetBackground() } else { Color.clear }
            }
    }
}
