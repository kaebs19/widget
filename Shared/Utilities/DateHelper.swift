//
//  DateHelper.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

// كل حسابات التاريخ هنا، عشان التطبيق والودجت يستخدمون نفس المنطق بالضبط.
enum DateHelper {

    static let hijri     = Calendar(identifier: .islamicUmmAlQura)
    static let gregorian = Calendar(identifier: .gregorian)
    // "ar" وحده صار يعطي أرقام لاتينية في iOS الحديث، فنحدد الأرقام العربية صراحةً
    private static let arabic = Locale(identifier: "ar@numbers=arab")

    // MARK: - الأرقام العربية
    // NumberFormatter مكلف في الإنشاء، فنسويه مرة وحدة (static) ونعيد استخدامه.
    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = arabic
        return f
    }()

    private static let twoDigitFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = arabic
        f.minimumIntegerDigits = 2
        return f
    }()

    static func arabic(_ number: Int) -> String {
        numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    /// برقمين دائماً: ٠٦
    static func arabicTwoDigits(_ number: Int) -> String {
        twoDigitFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    // MARK: - التنسيق
    private static func formatter(_ format: String, calendar: Calendar) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = arabic
        f.dateFormat = format
        return f
    }

    private static let hijriMonthFmt  = formatter("MMMM", calendar: hijri)
    private static let gregorianFmt   = formatter("d MMMM y", calendar: gregorian)
    private static let weekdayFmt     = formatter("EEEE", calendar: gregorian)
    private static let dayMonthFmt    = formatter("d MMMM", calendar: gregorian)
    private static let weekdayDayMonthFmt = formatter("EEEE d MMMM", calendar: gregorian)
    private static let weekdayFullFmt = formatter("EEEE d MMMM y", calendar: gregorian)

    static func hijriDay(_ date: Date) -> String   { arabic(hijri.component(.day, from: date)) }
    static func hijriYear(_ date: Date) -> String  { arabic(hijri.component(.year, from: date)) }
    static func hijriMonth(_ date: Date) -> String { hijriMonthFmt.string(from: date) }
    static func gregorianFull(_ date: Date) -> String { gregorianFmt.string(from: date) }
    static func weekday(_ date: Date) -> String    { weekdayFmt.string(from: date) }
    /// ١١ أكتوبر
    static func gregorianDayMonth(_ date: Date) -> String { dayMonthFmt.string(from: date) }
    /// السبت ٢٤ أكتوبر
    static func weekdayDayMonth(_ date: Date) -> String { weekdayDayMonthFmt.string(from: date) }
    /// الخميس ٢٣ سبتمبر ٢٠٢٧
    static func weekdayFull(_ date: Date) -> String { weekdayFullFmt.string(from: date) }
    /// ٢٩ ربيع الآخر
    static func hijriDayMonth(_ date: Date) -> String { "\(hijriDay(date)) \(hijriMonth(date))" }

    // MARK: - العدادات
    /// كم يوم باقي على تاريخ هجري (مثلاً رمضان = شهر ٩ يوم ١)
    static func daysUntilHijri(month: Int, day: Int, from now: Date = .now) -> Int {
        daysUntil(DateComponents(month: month, day: day), calendar: hijri, from: now)
    }

    /// كم يوم باقي على تاريخ ميلادي (مثلاً اليوم الوطني = ٩/٢٣)
    static func daysUntilGregorian(month: Int, day: Int, from now: Date = .now) -> Int {
        daysUntil(DateComponents(month: month, day: day), calendar: gregorian, from: now)
    }

    /// تاريخ المناسبة الهجرية القادمة (أو اليوم إذا كانت اليوم)
    static func nextHijri(month: Int, day: Int, from now: Date = .now) -> Date {
        nextDate(DateComponents(month: month, day: day), calendar: hijri, from: now)
    }

    static func nextGregorian(month: Int, day: Int, from now: Date = .now) -> Date {
        nextDate(DateComponents(month: month, day: day), calendar: gregorian, from: now)
    }

    /// كم مضى (من ٠ إلى ١) من الانتظار بين المناسبة الهجرية السابقة والقادمة، للأشرطة والحلقات
    static func progressUntilHijri(month: Int, day: Int, from now: Date = .now) -> Double {
        progress(until: nextHijri(month: month, day: day, from: now), calendar: hijri, from: now)
    }

    static func progressUntilGregorian(month: Int, day: Int, from now: Date = .now) -> Double {
        progress(until: nextGregorian(month: month, day: day, from: now), calendar: gregorian, from: now)
    }

    private static func progress(until next: Date, calendar: Calendar, from now: Date) -> Double {
        guard let previous = calendar.date(byAdding: .year, value: -1, to: next) else { return 0 }
        let total = next.timeIntervalSince(previous)
        return total > 0 ? min(max(now.timeIntervalSince(previous) / total, 0), 1) : 0
    }

    // MARK: - العيد
    /// أقرب عيد قادم: الفطر (١ شوال) أو الأضحى (١٠ ذو الحجة)
    static func nextEid(from now: Date = .now) -> (name: String, date: Date, days: Int) {
        let fitr = (name: "عيد الفطر", date: nextHijri(month: 10, day: 1, from: now),
                    days: daysUntilHijri(month: 10, day: 1, from: now))
        let adha = (name: "عيد الأضحى", date: nextHijri(month: 12, day: 10, from: now),
                    days: daysUntilHijri(month: 12, day: 10, from: now))
        return fitr.days <= adha.days ? fitr : adha
    }

    private static func daysUntil(_ components: DateComponents, calendar: Calendar, from now: Date) -> Int {
        let today = calendar.startOfDay(for: now)
        let target = nextDate(components, calendar: calendar, from: now)
        return calendar.dateComponents([.day], from: today, to: target).day ?? 0
    }

    private static func nextDate(_ components: DateComponents, calendar: Calendar, from now: Date) -> Date {
        let today = calendar.startOfDay(for: now)
        // لو المناسبة اليوم نرجع اليوم، وإلا ندور أقرب تاريخ جاي يطابقها
        if calendar.date(today, matchesComponents: components) { return today }
        return calendar.nextDate(after: today, matching: components, matchingPolicy: .nextTime) ?? today
    }

    // MARK: - المناسبة الخاصة
    /// الأيام والساعات المتبقية حتى تاريخ معيّن (صفر إذا مضى)
    static func countdown(to target: Date, from now: Date = .now) -> (days: Int, hours: Int) {
        guard target > now else { return (0, 0) }
        let parts = gregorian.dateComponents([.day, .hour], from: now, to: target)
        return (parts.day ?? 0, parts.hour ?? 0)
    }

    /// إذا كانت المناسبة تتكرر كل سنة ومضى يومها، نرجع موعدها في السنة القادمة.
    /// يوم المناسبة نفسه يبقى «اليوم» حتى نهايته.
    static func nextOccurrence(of date: Date, repeatsYearly: Bool, from now: Date = .now) -> Date {
        let today = gregorian.startOfDay(for: now)
        guard repeatsYearly, date < today else { return date }
        let parts = gregorian.dateComponents([.month, .day, .hour, .minute], from: date)
        return gregorian.nextDate(after: today.addingTimeInterval(-1), matching: parts, matchingPolicy: .nextTime) ?? date
    }

    // MARK: - تقدم السنة
    static func yearProgress(_ date: Date = .now) -> (dayOfYear: Int, totalDays: Int, percent: Int) {
        let day   = gregorian.ordinality(of: .day, in: .year, for: date) ?? 1
        let total = gregorian.range(of: .day, in: .year, for: date)?.count ?? 365
        return (day, total, Int((Double(day) / Double(total) * 100).rounded()))
    }
}
