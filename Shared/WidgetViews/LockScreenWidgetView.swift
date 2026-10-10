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
        case .morningDhikr:                  [.accessoryRectangular]
        case .ramadan, .eid, .nationalDay, .foundingDay:
                                             [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        case .istighfar:                     [.accessoryCircular, .accessoryRectangular]
        case .specialOccasion:               [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        case .prayerRing:                    [.accessoryCircular, .accessoryInline]
        case .prayerBar:                     [.accessoryRectangular]
        case .prayerList, .prayerDay:        [.accessoryRectangular]
        case .salary, .citizenAccount, .hafiz, .retirement, .socialSecurity, .studentBonus, .rehabilitation, .budget:
                                             [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        case .paydays, .obligations:         [.accessoryRectangular, .accessoryInline]
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
        case (.morningDhikr, _):
            dhikrRectangular
        case (.prayerRing, _), (.prayerBar, _), (.prayerList, _), (.prayerDay, _):
            PrayerLockView(kind: kind, date: date, family: family, style: style)
        case (.paydays, _):
            PaydaysLockView(date: date, family: family, style: style)
        case (.obligations, _):
            ObligationsLockView(date: date, family: family, style: style)
        case (.budget, _):
            BudgetLockView(date: date, family: family, style: style)
        case (.ramadan, _), (.eid, _), (.nationalDay, _), (.foundingDay, _), (_, _) where kind.payday != nil:
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
        case _ where kind.payday != nil:
            guard let payday = kind.payday else { return nil }
            let cycle = payday.cycle(from: date)
            self.init(title: payday.displayName, symbol: payday.symbol, days: cycle.days,
                      progress: cycle.progress, detail: DateHelper.weekdayDayMonth(cycle.next))
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

// MARK: - الصلاة
struct PrayerLockView: View {
    let kind: WidgetKind
    let date: Date
    let family: WidgetFamily
    var style: WidgetStyle = .default

    var body: some View {
        if let moment = PrayerSchedule.moment(at: date) {
            switch family {
            case .accessoryInline:
                Label(LockText.inline(style.text("\(moment.next.title) \(PrayerSchedule.format(moment.nextTime))")),
                      systemImage: moment.next.symbol)
            case .accessoryCircular:
                Gauge(value: moment.progress(at: date)) { EmptyView() } currentValueLabel: {
                    VStack(spacing: 0) {
                        Image(systemName: moment.next.symbol).font(.system(size: 10))
                        Text(style.text(PrayerSchedule.format(moment.nextTime)))
                            .font(style.font(.number, 14))
                            .minimumScaleFactor(0.5)
                        Text(moment.next.title).font(style.font(.label, 8))
                    }
                }
                .gaugeStyle(.accessoryCircularCapacity)
            default:
                if kind == .prayerList || kind == .prayerDay { schedule(moment) } else { next(moment) }
            }
        }
    }

    /// الصلاة القادمة والوقت المتبقي
    private func next(_ moment: PrayerSchedule.Moment) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Label("\(moment.next.title) \(style.text(PrayerSchedule.format(moment.nextTime)))",
                  systemImage: moment.next.symbol)
                .font(style.font(.labelBold, 14))
            Text(moment.nextTime, style: .timer)
                .font(style.font(.number, 20))
                .monospacedDigit()
                .environment(\.locale, Locale(identifier: style.numerals == .arabic ? "ar@numbers=arab" : "en"))
            ProgressView(value: moment.progress(at: date))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// الصلوات الخمس بأعمدة صغيرة، والقادمة بخط عريض
    private func schedule(_ moment: PrayerSchedule.Moment) -> some View {
        let highlighted = PrayerHighlight.upcomingFard(moment)
        return HStack(spacing: 2) {
            ForEach(PrayerName.fard) { prayer in
                let isOn = prayer == highlighted
                VStack(spacing: 2) {
                    Text(prayer.title)
                        .font(style.font(isOn ? .labelBold : .label, 10))
                    Text(style.text(PrayerSchedule.format(moment.today.time(prayer))))
                        .font(style.font(.number, isOn ? 13 : 12))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(isOn ? .primary : .secondary)
                .background {
                    if isOn { RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.18)) }
                }
            }
        }
    }
}

// MARK: - مواعيد الصرف
/// أقرب الدفعات: السطر الواحد يعرض الأقرب، والمستطيل يعرض ثلاثاً
struct PaydaysLockView: View {
    let date: Date
    let family: WidgetFamily
    var style: WidgetStyle = .default

    private var cycles: [PaydayCycle] {
        Payday.allCases.filter(\.isListed).map { $0.cycle(from: date) }.sorted { $0.next < $1.next }
    }

    var body: some View {
        let cycles = cycles
        if family == .accessoryInline {
            if let first = cycles.first {
                Label(LockText.inline(style.text("\(first.payday.displayName) \(PaydayFormat.remaining(first.days))")),
                      systemImage: first.payday.symbol)
            }
        } else {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(cycles.prefix(3).enumerated()), id: \.element.payday) { index, cycle in
                    HStack(spacing: 4) {
                        Image(systemName: cycle.payday.symbol).font(.system(size: 10)).frame(width: 14)
                        Text(cycle.payday.displayName)
                        Spacer(minLength: 2)
                        Text(style.text(PaydayFormat.remaining(cycle.days)))
                    }
                    .font(style.font(index == 0 ? .labelBold : .label, 12))
                    .foregroundStyle(index == 0 ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
