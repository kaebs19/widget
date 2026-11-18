//
//  NameWidgets.swift
//  Widgets
//
//  ودجات «الأيام والشهور» (مدفوعة). التصميم من حزمة Widgets-Days-Months:
//  الأشكال ٠١–٠٧ في `StyledNameWidget`، و٠٦ و٠٨ و٠٩ بعدها، ثم الأفكار الست (الشكل ١٠).
//

import SwiftUI
import WidgetKit

// MARK: - الموزّع
struct NameWidget: View {
    let kind: WidgetKind
    let date: Date
    var size: WidgetSize = .medium
    var options: NameOptions

    var body: some View {
        let parts = DateParts(date)
        let compact = size == .small
        switch kind {
        case .styledHijriMonth, .styledGregorianMonth where size == .large:
            LargeMonthWidget(kind: kind, date: date, parts: parts, shape: options.shape)
        case .styledDay, .styledHijriMonth, .styledGregorianMonth:
            StyledNameWidget(kind: kind, parts: parts, shape: options.shape, compact: compact)
        case .bothDates where size == .large:
            VStack(spacing: 0) {
                BothDatesWidget(parts: parts).frame(height: 160)
                MonthGrid(month: .hijri(date))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            }
        case .monthBehind:
            MonthBehindWidget(parts: parts, calendar: options.calendar, compact: compact)
        case .dayNumber:
            DayNumberWidget(parts: parts, layout: options.dayLayout, compact: compact)
        case .monthNumber:
            MonthNumberWidget(parts: parts, calendar: options.calendar, layout: options.monthLayout, compact: compact)
        case .bothDates:      BothDatesWidget(parts: parts)
        case .weekRibbon:     WeekRibbonWidget(date: date, parts: parts)
        case .monthProgress:  MonthProgressWidget(parts: parts)
        case .bigNumber:      BigNumberWidget(parts: parts)
        case .hijriCountdown: HijriCountdownWidget(date: date, target: options.target, compact: compact)
        case .circleBadge:    CircleBadgeWidget(parts: parts, compact: compact)
        default:              EmptyView()
        }
    }
}

/// النصوص الصغيرة المساعدة بخط IBM Plex كما في التصميم
private func caption(_ size: CGFloat, weight: AppFontWeight = .medium) -> Font {
    .app(.ibmPlexArabic, size: size, weight: weight)
}

/// خط فاصل رأسي رفيع بين جزأين
private struct Rule: View {
    var height: CGFloat
    @Environment(\.widgetStyle) private var style
    var body: some View {
        Rectangle().fill(style.primary.opacity(0.12)).frame(width: 1, height: height)
    }
}

// MARK: - ٠١–٠٥ و٠٧: الاسم بالخط
private struct StyledNameWidget: View {
    let kind: WidgetKind
    let parts: DateParts
    let shape: NameShape
    let compact: Bool
    @Environment(\.widgetStyle) private var style

    private var calendar: NameCalendar { kind == .styledGregorianMonth ? .gregorian : .hijri }
    private var isDay: Bool { kind == .styledDay }

    private var arabic: String {
        if isDay {
            return shape == .naskh ? NameTables.weekdaysVowelled[parts.weekday] : NameTables.weekdays[parts.weekday]
        }
        return parts.monthName(calendar, vowelled: shape == .naskh)
    }

    private var english: String {
        isDay ? NameTables.weekdaysEnglish[parts.weekday] : parts.monthEnglish(calendar)
    }

    private var scale: CGFloat { compact ? 0.55 : 0.88 }

    var body: some View {
        Group {
            switch shape {
            case .naskh:
                name(arabic, .amiri, 80)
            case .ruqaa:
                name(arabic, .ruqaa, 84)
            case .nastaliq:
                // النستعليق يحتاج ارتفاع سطر أكبر حتى لا تُقص الحروف
                name(arabic, .gulzar, 60).padding(.vertical, 8)
            case .kufi:
                VStack(spacing: compact ? 4 : 8) {
                    name(arabic, .reemKufi, 68)
                    Text(english.uppercased())
                        .font(DisplayFont.inter.font(15 * scale))
                        .tracking(15 * scale * 0.3)
                        .foregroundStyle(style.accent)
                        .lineLimit(1).minimumScaleFactor(0.6)
                        .widgetAccentable()
                }
            case .dots:
                name(arabic, .handjet, 96)
            case .english:
                VStack(spacing: compact ? 8 : 14) {
                    Text(english.uppercased())
                        .font(DisplayFont.cormorant.font(40 * scale * (compact ? 1.1 : 1.15)))
                        .tracking(40 * scale * 0.2)
                        .foregroundStyle(style.primary)
                        .lineLimit(1).minimumScaleFactor(0.4)
                        .environment(\.layoutDirection, .leftToRight)
                    Rectangle().fill(style.accent).frame(width: 40, height: 1).widgetAccentable()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, compact ? 10 : 18)
    }

    private func name(_ text: String, _ font: DisplayFont, _ size: CGFloat) -> some View {
        Text(text)
            .font(font.font(size * scale))
            .foregroundStyle(style.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .widgetAccentable()
    }
}

// MARK: - كبير: اسم الشهر بالخط فوق تقويمه
private struct LargeMonthWidget: View {
    let kind: WidgetKind
    let date: Date
    let parts: DateParts
    let shape: NameShape
    @Environment(\.widgetStyle) private var style

    private var calendar: NameCalendar { kind == .styledGregorianMonth ? .gregorian : .hijri }

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Group {
                    if shape == .english {
                        Text(parts.monthEnglish(calendar).uppercased())
                            .font(DisplayFont.cormorant.font(34)).tracking(5)
                    } else {
                        Text(parts.monthName(calendar, vowelled: shape == .naskh)).font(font(54))
                    }
                }
                .foregroundStyle(style.primary)
                .lineLimit(1).minimumScaleFactor(0.4)
                .widgetAccentable()
                Spacer(minLength: 8)
                Text("\(style.number(parts.year(calendar))) \(L10n.text(calendar == .hijri ? "هـ" : "م"))")
                    .font(caption(15, weight: .semibold))
                    .foregroundStyle(style.accent)
            }
            Rectangle().fill(style.primary.opacity(0.12)).frame(height: 1)
            MonthGrid(month: calendar == .hijri ? .hijri(date) : .gregorian(date))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private func font(_ size: CGFloat) -> Font {
        switch shape {
        case .naskh: DisplayFont.amiri.font(size)
        case .ruqaa: DisplayFont.ruqaa.font(size)
        case .nastaliq: DisplayFont.gulzar.font(size * 0.8)
        case .kufi: DisplayFont.reemKufi.font(size * 0.85)
        case .dots: DisplayFont.handjet.font(size * 1.1)
        case .english: DisplayFont.cormorant.font(size * 0.6)
        }
    }
}

// MARK: - ٠٦: الرقم خلف اسم الشهر
private struct MonthBehindWidget: View {
    let parts: DateParts
    let calendar: NameCalendar
    let compact: Bool
    @Environment(\.widgetStyle) private var style

    var body: some View {
        ZStack {
            Text(style.number(parts.day(calendar)))
                .font(DisplayFont.interHeavy.font(compact ? 130 : 170))
                .foregroundStyle(style.primary.opacity(0.13))
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(parts.monthName(calendar))
                .font(DisplayFont.ruqaa.font(compact ? 40 : 66))
                .foregroundStyle(style.primary)
                .lineLimit(1).minimumScaleFactor(0.4)
                .padding(.horizontal, 14)
                .widgetAccentable()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ٠٨: يوم الأسبوع + الرقم
private struct DayNumberWidget: View {
    let parts: DateParts
    let layout: DayNumberLayout
    let compact: Bool
    @Environment(\.widgetStyle) private var style

    private var dayName: String { NameTables.weekdays[parts.weekday] }
    private var hijriLine: String { "\(parts.monthName(.hijri)) \(style.number(parts.hYear))" }
    private var gregorianLine: String { "\(parts.monthName(.gregorian)) \(style.number(parts.gYear))" }

    var body: some View {
        Group {
            switch layout {
            case .behind:
                ZStack {
                    Text(style.number(parts.gDay))
                        .font(DisplayFont.interHeavy.font(compact ? 130 : 170))
                        .foregroundStyle(style.primary.opacity(0.13))
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(dayName)
                        .font(DisplayFont.ruqaa.font(compact ? 42 : 66))
                        .foregroundStyle(style.primary)
                        .lineLimit(1).minimumScaleFactor(0.4)
                        .padding(.horizontal, 14)
                        .widgetAccentable()
                }
            case .beside where !compact:
                HStack(spacing: 22) {
                    Text(style.number(parts.gDay))
                        .font(DisplayFont.interHeavy.font(88))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                    Rule(height: 76)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayName)
                            .font(DisplayFont.reemKufi.font(44))
                            .foregroundStyle(style.primary)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Text(hijriLine)
                            .font(caption(15))
                            .foregroundStyle(style.secondary)
                    }
                }
            case .beside, .above:
                VStack(spacing: compact ? 0 : 2) {
                    Text(dayName)
                        .font(compact && layout == .beside ? DisplayFont.reemKufi.font(28) : caption(compact ? 16 : 19, weight: .bold))
                        .foregroundStyle(layout == .beside ? style.primary : style.accent)
                        .widgetAccentable(layout == .above)
                    Text(style.number(parts.gDay))
                        .font(DisplayFont.interHeavy.font(compact ? 64 : 76))
                        .foregroundStyle(layout == .beside ? style.accent : style.primary)
                        .widgetAccentable(layout == .beside)
                    Text(layout == .beside ? hijriLine : gregorianLine)
                        .font(caption(compact ? 12 : 15))
                        .foregroundStyle(style.secondary)
                }
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ٠٩: الشهر + الرقم
private struct MonthNumberWidget: View {
    let parts: DateParts
    let calendar: NameCalendar
    let layout: MonthNumberLayout
    let compact: Bool
    @Environment(\.widgetStyle) private var style

    private var yearLine: String { "\(style.number(parts.year(calendar))) \(L10n.text(calendar == .hijri ? "هـ" : "م"))" }

    var body: some View {
        Group {
            if layout == .beside && !compact {
                HStack(spacing: 20) {
                    Text(style.number(parts.day(calendar)))
                        .font(DisplayFont.interHeavy.font(84))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                    Rule(height: 76)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(parts.monthName(calendar))
                            .font(DisplayFont.ruqaa.font(46))
                            .foregroundStyle(style.primary)
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Text(yearLine)
                            .font(caption(14))
                            .foregroundStyle(style.secondary)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    Text(style.number(parts.day(calendar)))
                        .font(DisplayFont.interHeavy.font(compact ? 66 : 80))
                        .foregroundStyle(layout == .beside ? style.accent : style.primary)
                    Text(parts.monthName(calendar))
                        .font(DisplayFont.ruqaa.font(compact ? 28 : 36))
                        .foregroundStyle(layout == .beside ? style.primary : style.accent)
                        .lineLimit(1).minimumScaleFactor(0.5)
                        .widgetAccentable()
                    if layout == .beside {
                        Text(yearLine).font(caption(12)).foregroundStyle(style.secondary)
                    }
                }
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 12)
    }
}

// MARK: - ١٠-١: التاريخان معاً
private struct BothDatesWidget: View {
    let parts: DateParts
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(NameTables.weekdays[parts.weekday])
                .font(.custom("Amiri-Bold", fixedSize: 60))
                .foregroundStyle(style.primary)
                .lineLimit(1).minimumScaleFactor(0.5)
                .widgetAccentable()
            Spacer(minLength: 0)
            HStack(spacing: 22) {
                column(L10n.text("هجري"), "\(style.number(parts.hDay)) \(parts.monthName(.hijri)) \(style.number(parts.hYear))")
                Rule(height: 44)
                column(L10n.text("ميلادي"), "\(style.number(parts.gDay)) \(parts.monthName(.gregorian)) \(style.number(parts.gYear))")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }

    private func column(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(caption(12, weight: .bold)).foregroundStyle(style.accent).widgetAccentable()
            Text(value).font(caption(18, weight: .semibold)).foregroundStyle(style.primary)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
    }
}

// MARK: - ١٠-٢: شريط الأسبوع
private struct WeekRibbonWidget: View {
    let date: Date
    let parts: DateParts
    @Environment(\.widgetStyle) private var style
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let calendar = DateHelper.gregorian
        let shift = (parts.weekday - (AppSettings.weekStart - 1) + 7) % 7
        let start = calendar.date(byAdding: .day, value: -shift, to: calendar.startOfDay(for: date)) ?? date
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(parts.monthName(.gregorian))
                    .font(DisplayFont.ruqaa.font(30))
                    .foregroundStyle(style.primary)
                Spacer()
                Text("\(parts.monthName(.hijri)) \(style.number(parts.hYear))")
                    .font(caption(13))
                    .foregroundStyle(style.secondary)
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                ForEach(days, id: \.self) { day in
                    let p = DateParts(day)
                    let isToday = calendar.isDate(day, inSameDayAs: date)
                    let filled = isToday && renderingMode == .fullColor
                    VStack(spacing: 8) {
                        Text(WeekdayLetters.all[p.weekday])
                            .font(caption(13))
                            .foregroundStyle(style.secondary)
                        Text(style.number(p.gDay))
                            .font(DisplayFont.interHeavy.font(19))
                            .foregroundStyle(filled ? style.onAccent : style.primary)
                            .frame(width: 42, height: 42)
                            .background { if filled { Circle().fill(style.accent) } }
                            .overlay { if isToday && !filled { Circle().strokeBorder(style.accent, lineWidth: 2) } }
                            .widgetAccentable(isToday)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
    }
}

// MARK: - ١٠-٣: تقدّم الشهر
private struct MonthProgressWidget: View {
    let parts: DateParts
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(parts.monthName(.hijri))
                    .font(DisplayFont.ruqaa.font(54))
                    .foregroundStyle(style.primary)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Spacer(minLength: 8)
                Text("\(style.number(parts.hDay)) / \(style.number(parts.hMonthLength))")
                    .font(DisplayFont.interHeavy.font(30))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                    .environment(\.layoutDirection, .leftToRight)
            }
            Spacer(minLength: 0)
            HStack(spacing: 4) {
                ForEach(1...parts.hMonthLength, id: \.self) { day in
                    Capsule()
                        .fill(day <= parts.hDay ? style.primary : style.primary.opacity(0.15))
                        .frame(height: 30)
                        .widgetAccentable(day <= parts.hDay)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 22)
    }
}

// MARK: - ١٠-٤: رقم عملاق
private struct BigNumberWidget: View {
    let parts: DateParts
    @Environment(\.widgetStyle) private var style

    var body: some View {
        HStack(spacing: 22) {
            VStack(alignment: .leading, spacing: 2) {
                Text(NameTables.weekdays[parts.weekday])
                    .font(caption(17, weight: .bold))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text(parts.monthName(.gregorian))
                    .font(DisplayFont.ruqaa.font(46))
                    .foregroundStyle(style.primary)
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(style.number(parts.gYear))
                    .font(caption(16))
                    .foregroundStyle(style.secondary)
            }
            Rule(height: 120)
            Text(style.number(parts.gDay))
                .font(DisplayFont.interHeavy.font(130))
                .foregroundStyle(style.primary)
                .lineLimit(1).minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
    }
}

// MARK: - ١٠-٥: عدّ تنازلي لمناسبة هجرية
private struct HijriCountdownWidget: View {
    let date: Date
    let target: HijriTarget
    let compact: Bool
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let days = DateHelper.daysUntilHijri(month: target.monthDay.month, day: target.monthDay.day, from: date)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: target.symbol)
                    .font(.system(size: compact ? 15 : 19, weight: .semibold))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text(days == 0 ? target.title : String(format: L10n.text("باقي على %@"), target.title))
                    .font(caption(compact ? 14 : 19))
                    .foregroundStyle(style.secondary)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            if days == 0 {
                Text(L10n.text("اليوم"))
                    .font(DisplayFont.ruqaa.font(compact ? 48 : 72))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(style.number(days))
                        .font(DisplayFont.interHeavy.font(compact ? 64 : 104))
                        .foregroundStyle(style.primary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(L10n.text(days == 1 ? "يوم" : (3...10).contains(days) ? "أيام" : "يوماً"))
                        .font(DisplayFont.ruqaa.font(compact ? 26 : 40))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(compact ? 16 : 22)
    }
}

// MARK: - ١٠-٦: شارة دائرية
private struct CircleBadgeWidget: View {
    let parts: DateParts
    let compact: Bool
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let diameter: CGFloat = compact ? 78 : 96
        VStack(spacing: compact ? 6 : 8) {
            Text(NameTables.weekdays[parts.weekday])
                .font(DisplayFont.reemKufi.font(compact ? 20 : 26))
                .foregroundStyle(style.primary)
            Text(style.number(parts.hDay))
                .font(DisplayFont.interHeavy.font(compact ? 34 : 44))
                .foregroundStyle(style.primary)
                .frame(width: diameter, height: diameter)
                .overlay(Circle().strokeBorder(style.accent, lineWidth: 2.5).widgetAccentable())
            Text("\(parts.monthName(.hijri)) \(style.number(parts.hYear))")
                .font(caption(compact ? 12 : 15, weight: .semibold))
                .foregroundStyle(style.secondary)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - القفل
/// يُعرض فوق ودجات الاشتراك في الشاشة الرئيسية إن لم يكن المستخدم مشتركاً
struct PremiumLockedView: View {
    var compact = false
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: compact ? 20 : 24, weight: .semibold))
                .foregroundStyle(style.accent)
                .widgetAccentable()
            Text(L10n.text("ودجات الأيام والشهور"))
                .font(caption(compact ? 13 : 15, weight: .bold))
                .foregroundStyle(style.primary)
            Text(L10n.text("اشترك من التطبيق لفتحها"))
                .font(caption(compact ? 11 : 13))
                .foregroundStyle(style.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - شاشة القفل
// لون واحد يحدده النظام، فالتمييز بالحجم والشفافية. الخطوط العربية نفسها تبقى هي الزينة.
extension WidgetKind {
    var nameLockFamilies: [WidgetFamily] {
        switch self {
        case .styledDay, .styledHijriMonth, .styledGregorianMonth: [.accessoryRectangular, .accessoryInline]
        case .monthBehind, .weekRibbon:                           [.accessoryRectangular]
        case .dayNumber, .monthNumber, .bigNumber, .monthProgress: [.accessoryCircular, .accessoryRectangular]
        case .bothDates:                                          [.accessoryRectangular, .accessoryInline]
        case .hijriCountdown:                                     [.accessoryCircular, .accessoryRectangular, .accessoryInline]
        case .circleBadge:                                        [.accessoryCircular]
        default:                                                  []
        }
    }
}

struct NameLockView: View {
    let kind: WidgetKind
    let date: Date
    let family: WidgetFamily
    var options: NameOptions
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let parts = DateParts(date)
        Group {
            switch family {
            case .accessoryInline: inline(parts)
            case .accessoryCircular: circular(parts)
            default: rectangular(parts)
            }
        }
        .lockScreenContainer(family: family)
    }

    // السطر فوق الساعة: نص عادي فقط
    @ViewBuilder
    private func inline(_ p: DateParts) -> some View {
        switch kind {
        case .hijriCountdown:
            let days = countdownDays
            Label(LockText.inline(days == 0 ? options.target.title
                                  : "\(options.target.title) · \(style.number(days)) \(L10n.text(days == 1 ? "يوم" : (3...10).contains(days) ? "أيام" : "يوماً"))"),
                  systemImage: options.target.symbol)
        case .bothDates:
            Label(LockText.inline("\(style.number(p.hDay)) \(p.monthName(.hijri)) · \(style.number(p.gDay)) \(p.monthName(.gregorian))"),
                  systemImage: "calendar")
        default:
            Label(LockText.inline("\(NameTables.weekdays[p.weekday]) · \(style.number(p.hDay)) \(p.monthName(.hijri))"),
                  systemImage: "moon")
        }
    }

    @ViewBuilder
    private func circular(_ p: DateParts) -> some View {
        switch kind {
        case .monthProgress:
            Gauge(value: Double(p.hDay), in: 0...Double(p.hMonthLength)) {
                Text(p.monthName(.hijri))
            } currentValueLabel: {
                Text(style.number(p.hDay)).font(DisplayFont.interHeavy.font(18))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        case .hijriCountdown:
            let days = countdownDays
            VStack(spacing: -1) {
                Image(systemName: options.target.symbol).font(.system(size: 11, weight: .semibold))
                Text(style.number(days)).font(DisplayFont.interHeavy.font(20)).minimumScaleFactor(0.5)
                Text(L10n.text(days == 1 ? "يوم" : (3...10).contains(days) ? "أيام" : "يوماً")).font(caption(9))
            }
        case .monthNumber:
            VStack(spacing: -2) {
                Text(style.number(p.day(options.calendar))).font(DisplayFont.interHeavy.font(22))
                Text(p.monthName(options.calendar)).font(DisplayFont.ruqaa.font(13)).minimumScaleFactor(0.5)
            }
        case .circleBadge:
            VStack(spacing: -1) {
                Text(NameTables.weekdays[p.weekday]).font(DisplayFont.reemKufi.font(10)).minimumScaleFactor(0.6)
                Text(style.number(p.hDay)).font(DisplayFont.interHeavy.font(22))
                Text(p.monthName(.hijri)).font(caption(8)).minimumScaleFactor(0.6)
            }
            .padding(4)
            .overlay(Circle().strokeBorder(lineWidth: 1.5).opacity(0.5))
        default: // اليوم والرقم، الرقم العملاق
            VStack(spacing: -2) {
                Text(NameTables.weekdays[p.weekday]).font(DisplayFont.reemKufi.font(11)).minimumScaleFactor(0.6)
                Text(style.number(p.gDay)).font(DisplayFont.interHeavy.font(24))
            }
        }
    }

    @ViewBuilder
    private func rectangular(_ p: DateParts) -> some View {
        switch kind {
        case .styledDay, .styledHijriMonth, .styledGregorianMonth:
            let calendar: NameCalendar = kind == .styledGregorianMonth ? .gregorian : .hijri
            let name = kind == .styledDay
                ? (options.shape == .naskh ? NameTables.weekdaysVowelled[p.weekday] : NameTables.weekdays[p.weekday])
                : p.monthName(calendar, vowelled: options.shape == .naskh)
            let english = kind == .styledDay ? NameTables.weekdaysEnglish[p.weekday] : p.monthEnglish(calendar)
            VStack(spacing: 0) {
                if options.shape == .english {
                    Text(english.uppercased()).font(DisplayFont.cormorant.font(24)).tracking(3)
                } else {
                    Text(name).font(scriptFont(options.shape, 34))
                }
                Text(subtitle(p, kind: kind))
                    .font(caption(11)).foregroundStyle(.secondary)
            }
            .lineLimit(1).minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity)
        case .monthBehind:
            ZStack {
                Text(style.number(p.day(options.calendar))).font(DisplayFont.interHeavy.font(52)).opacity(0.25)
                Text(p.monthName(options.calendar)).font(DisplayFont.ruqaa.font(30)).minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
        case .weekRibbon:
            let shift = (p.weekday - (AppSettings.weekStart - 1) + 7) % 7
            let calendar = DateHelper.gregorian
            let start = calendar.date(byAdding: .day, value: -shift, to: calendar.startOfDay(for: date)) ?? date
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = calendar.date(byAdding: .day, value: offset, to: start) ?? date
                    let d = DateParts(day)
                    let isToday = offset == shift
                    VStack(spacing: 2) {
                        Text(WeekdayLetters.all[d.weekday]).font(caption(10)).foregroundStyle(.secondary)
                        Text(style.number(d.gDay)).font(DisplayFont.interHeavy.font(13))
                            .frame(width: 22, height: 22)
                            .background { if isToday { Circle().fill(.primary.opacity(0.25)) } }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        case .monthProgress:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(p.monthName(.hijri)).font(DisplayFont.ruqaa.font(22))
                    Spacer()
                    Text("\(style.number(p.hDay))/\(style.number(p.hMonthLength))").font(DisplayFont.interHeavy.font(13))
                        .environment(\.layoutDirection, .leftToRight)
                }
                HStack(spacing: 2) {
                    ForEach(1...p.hMonthLength, id: \.self) { day in
                        Capsule().opacity(day <= p.hDay ? 1 : 0.25).frame(height: 10)
                    }
                }
            }
        case .hijriCountdown:
            let days = countdownDays
            HStack(alignment: .center, spacing: 8) {
                Text(style.number(days)).font(DisplayFont.interHeavy.font(40)).minimumScaleFactor(0.5)
                VStack(alignment: .leading, spacing: 0) {
                    Label(options.target.title, systemImage: options.target.symbol).font(caption(13, weight: .bold))
                    Text(L10n.text(days == 1 ? "يوم" : (3...10).contains(days) ? "أيام" : "يوماً"))
                        .font(DisplayFont.ruqaa.font(18))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .bothDates:
            VStack(alignment: .leading, spacing: 0) {
                Text(NameTables.weekdays[p.weekday]).font(.custom("Amiri-Bold", fixedSize: 24))
                Text("\(style.number(p.hDay)) \(p.monthName(.hijri)) \(style.number(p.hYear))").font(caption(12, weight: .semibold))
                Text("\(style.number(p.gDay)) \(p.monthName(.gregorian)) \(style.number(p.gYear))").font(caption(11)).foregroundStyle(.secondary)
            }
            .lineLimit(1).minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: .leading)
        case .monthNumber:
            HStack(spacing: 8) {
                Text(style.number(p.day(options.calendar))).font(DisplayFont.interHeavy.font(40))
                VStack(alignment: .leading, spacing: 0) {
                    Text(p.monthName(options.calendar)).font(DisplayFont.ruqaa.font(24)).minimumScaleFactor(0.5)
                    Text("\(style.number(p.year(options.calendar))) \(L10n.text(options.calendar == .hijri ? "هـ" : "م"))")
                        .font(caption(11)).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default: // اليوم والرقم، الرقم العملاق
            HStack(spacing: 8) {
                Text(style.number(p.gDay)).font(DisplayFont.interHeavy.font(42))
                VStack(alignment: .leading, spacing: 0) {
                    Text(NameTables.weekdays[p.weekday]).font(DisplayFont.reemKufi.font(20))
                    Text(kind == .bigNumber ? "\(p.monthName(.gregorian)) \(style.number(p.gYear))"
                                            : "\(p.monthName(.hijri)) \(style.number(p.hYear))")
                        .font(caption(11)).foregroundStyle(.secondary)
                }
                .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var countdownDays: Int {
        DateHelper.daysUntilHijri(month: options.target.monthDay.month, day: options.target.monthDay.day, from: date)
    }

    private func subtitle(_ p: DateParts, kind: WidgetKind) -> String {
        switch kind {
        case .styledGregorianMonth: "\(style.number(p.gDay)) · \(style.number(p.gYear))"
        case .styledHijriMonth: "\(style.number(p.hDay)) · \(style.number(p.hYear)) \(L10n.text("هـ"))"
        default: "\(style.number(p.hDay)) \(p.monthName(.hijri)) · \(style.number(p.gDay)) \(p.monthName(.gregorian))"
        }
    }

    private func scriptFont(_ shape: NameShape, _ size: CGFloat) -> Font {
        switch shape {
        case .naskh: DisplayFont.amiri.font(size)
        case .ruqaa: DisplayFont.ruqaa.font(size)
        case .nastaliq: DisplayFont.gulzar.font(size * 0.8)
        case .kufi: DisplayFont.reemKufi.font(size * 0.85)
        case .dots: DisplayFont.handjet.font(size * 1.1)
        case .english: DisplayFont.cormorant.font(size * 0.7)
        }
    }
}

/// قفل ودجات «برو» في شاشة القفل لغير المشتركين
struct PremiumLockedAccessory: View {
    let family: WidgetFamily
    var body: some View {
        Group {
            switch family {
            case .accessoryInline: Label(L10n.text("ويدجت برو"), systemImage: "lock.fill")
            case .accessoryCircular: Image(systemName: "lock.fill").font(.system(size: 20, weight: .semibold))
            default:
                Label(L10n.text("اشترك من التطبيق لفتحها"), systemImage: "lock.fill")
                    .font(caption(13, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .lockScreenContainer(family: family)
    }
}
