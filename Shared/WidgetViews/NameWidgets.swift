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
        case .styledDay, .styledHijriMonth, .styledGregorianMonth:
            StyledNameWidget(kind: kind, parts: parts, shape: options.shape, compact: compact)
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

    private var yearLine: String { "\(style.number(parts.year(calendar))) \(calendar == .hijri ? "هـ" : "م")" }

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
                column("هجري", "\(style.number(parts.hDay)) \(parts.monthName(.hijri)) \(style.number(parts.hYear))")
                Rule(height: 44)
                column("ميلادي", "\(style.number(parts.gDay)) \(parts.monthName(.gregorian)) \(style.number(parts.gYear))")
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
                Text(days == 0 ? target.title : "باقي على \(target.title)")
                    .font(caption(compact ? 14 : 19))
                    .foregroundStyle(style.secondary)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            if days == 0 {
                Text("اليوم")
                    .font(DisplayFont.ruqaa.font(compact ? 48 : 72))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text(style.number(days))
                        .font(DisplayFont.interHeavy.font(compact ? 64 : 104))
                        .foregroundStyle(style.primary)
                        .lineLimit(1).minimumScaleFactor(0.5)
                    Text(days == 1 ? "يوم" : (3...10).contains(days) ? "أيام" : "يوماً")
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
            Text("ودجات الأيام والشهور")
                .font(caption(compact ? 13 : 15, weight: .bold))
                .foregroundStyle(style.primary)
            Text("اشترك من التطبيق لفتحها")
                .font(caption(compact ? 11 : 13))
                .foregroundStyle(style.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
