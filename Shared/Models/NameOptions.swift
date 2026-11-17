//
//  NameOptions.swift
//  Widgets
//
//  خيارات ودجات «الأيام والشهور» وأسماؤها. الخيار يُحفظ لكل نوع في المساحة المشتركة،
//  ويُغيَّر من صفحة الودجت في التطبيق.
//

import SwiftUI

// MARK: - الشكل (الخط)
nonisolated enum NameShape: String, Codable, CaseIterable, Identifiable, Sendable {
    case naskh, ruqaa, nastaliq, kufi, dots, english

    var id: Self { self }

    var title: String {
        switch self {
        case .naskh:    L10n.text("نسخ مشكّل")
        case .ruqaa:    L10n.text("رقعة ورقي")
        case .nastaliq: L10n.text("نستعليق ذهبي")
        case .kufi:     L10n.text("كوفي + إنجليزي")
        case .dots:     L10n.text("هندسي نقطي")
        case .english:  "English"
        }
    }

    /// ألوان التصميم الأصلي؛ تُستخدم ما دام المستخدم لم يخصّص شكل هذا النوع
    var palette: (card: UInt32, ink: UInt32, accent: UInt32) {
        switch self {
        case .naskh:    (0x1C1C1E, 0xEDE8DC, 0xC9A45C)
        case .ruqaa:    (0xF1ECE0, 0x1B1A17, 0x8A6A2E)
        case .nastaliq: (0x0F2A22, 0xE3C98A, 0xE3C98A)
        case .kufi:     (0x161618, 0xFFFFFF, 0xF5A623)
        case .dots:     (0x15171C, 0xFFB84D, 0xFFB84D)
        case .english:  (0x1C1C1E, 0xF2EEE2, 0xC9A45C)
        }
    }
}

nonisolated enum NameCalendar: String, Codable, CaseIterable, Identifiable, Sendable {
    case hijri, gregorian
    var id: Self { self }
    var title: String { L10n.text(self == .hijri ? "هجري" : "ميلادي") }
}

/// تخطيط «اليوم + الرقم» (الشكل ٠٨)
nonisolated enum DayNumberLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case behind, beside, above
    var id: Self { self }
    var title: String {
        switch self {
        case .behind: L10n.text("الرقم خلف الاسم")
        case .beside: L10n.text("الرقم بجانب الاسم")
        case .above:  L10n.text("اليوم فوق الرقم")
        }
    }
}

/// تخطيط «الشهر + الرقم» (الشكل ٠٩)
nonisolated enum MonthNumberLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case beside, above
    var id: Self { self }
    var title: String { L10n.text(self == .beside ? "الرقم بجانب الشهر" : "الرقم فوق الشهر") }
}

/// المناسبات الهجرية للعدّ التنازلي
nonisolated enum HijriTarget: String, Codable, CaseIterable, Identifiable, Sendable {
    case ramadan, eidFitr, arafah, eidAdha, newYear, ashura
    var id: Self { self }

    var title: String {
        switch self {
        case .ramadan: L10n.text("رمضان")
        case .eidFitr: L10n.text("عيد الفطر")
        case .arafah:  L10n.text("يوم عرفة")
        case .eidAdha: L10n.text("عيد الأضحى")
        case .newYear: L10n.text("رأس السنة الهجرية")
        case .ashura:  L10n.text("عاشوراء")
        }
    }

    var monthDay: (month: Int, day: Int) {
        switch self {
        case .ramadan: (9, 1)
        case .eidFitr: (10, 1)
        case .arafah:  (12, 9)
        case .eidAdha: (12, 10)
        case .newYear: (1, 1)
        case .ashura:  (1, 10)
        }
    }

    var symbol: String { self == .ramadan ? "moon" : self == .newYear ? "sparkles" : "star" }
}

// MARK: - الخيارات المحفوظة
nonisolated struct NameOptions: Codable, Hashable, Sendable {
    var shape: NameShape = .naskh
    var calendar: NameCalendar = .hijri
    var dayLayout: DayNumberLayout = .beside
    var monthLayout: MonthNumberLayout = .beside
    var target: HijriTarget = .ramadan

    private static let key = "names.options"

    static func load(for kind: WidgetKind, in defaults: UserDefaults = AppGroup.defaults) -> NameOptions {
        guard let data = (defaults.dictionary(forKey: key) as? [String: Data])?[kind.rawValue],
              let options = try? JSONDecoder().decode(NameOptions.self, from: data) else { return NameOptions(kind: kind) }
        return options
    }

    static func save(_ options: NameOptions, for kind: WidgetKind, in defaults: UserDefaults = AppGroup.defaults) {
        var all = (defaults.dictionary(forKey: key) as? [String: Data]) ?? [:]
        all[kind.rawValue] = try? JSONEncoder().encode(options)
        defaults.set(all, forKey: key)
    }

    /// الافتراضي لكل نوع
    init(kind: WidgetKind? = nil) {
        if kind == .styledGregorianMonth || kind == .monthBehind { calendar = .gregorian }
    }
}

extension NameOptions {
    /// ألوان التصميم: الخط المختار له ألوانه، والبقية داكنة بنص عاجي ولون برتقالي
    static func designStyle(for kind: WidgetKind) -> WidgetStyle {
        var palette: (card: UInt32, ink: UInt32, accent: UInt32) = (0x1C1C1E, 0xF2EEE2, 0xF5A623)
        if kind.usesShape { palette = load(for: kind).shape.palette }
        if kind == .monthNumber || kind == .monthBehind { palette.accent = 0xE3C98A }
        var style = WidgetStyle.default
        style.background = .color(Color.Resolved(hex: palette.card))
        style.textColor = Color.Resolved(hex: palette.ink)
        style.accentColor = Color.Resolved(hex: palette.accent)
        return style
    }
}

extension WidgetKind {
    /// الودجات التي يُختار لها خط من الأشكال الستة
    nonisolated var usesShape: Bool { self == .styledDay || self == .styledHijriMonth || self == .styledGregorianMonth }
}

// MARK: - الأسماء
nonisolated enum NameTables {
    /// تبدأ من الأحد لتطابق `Calendar.component(.weekday)` (١ = الأحد)
    static let weekdays = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
    static let weekdaysVowelled = ["الأَحَد", "الاِثْنَيْن", "الثُّلَاثَاء", "الأَرْبِعَاء", "الخَمِيس", "الجُمُعَة", "السَّبْت"]
    static let weekdaysEnglish = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    static let hijri = ["محرم", "صفر", "ربيع الأول", "ربيع الآخر", "جمادى الأولى", "جمادى الآخرة",
                        "رجب", "شعبان", "رمضان", "شوال", "ذو القعدة", "ذو الحجة"]
    static let hijriVowelled = ["مُحَرَّم", "صَفَر", "رَبِيع الأَوَّل", "رَبِيع الآخِر", "جُمَادَى الأُولَى", "جُمَادَى الآخِرَة",
                                "رَجَب", "شَعْبَان", "رَمَضَان", "شَوَّال", "ذُو القَعْدَة", "ذُو الحِجَّة"]
    static let hijriEnglish = ["Muharram", "Safar", "Rabi I", "Rabi II", "Jumada I", "Jumada II",
                               "Rajab", "Shaban", "Ramadan", "Shawwal", "Dhu al-Qadah", "Dhu al-Hijjah"]

    static let gregorian = ["يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
                            "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"]
    static let gregorianVowelled = ["يَنَايِر", "فِبْرَايِر", "مَارِس", "أَبْرِيل", "مَايُو", "يُونْيُو",
                                    "يُولْيُو", "أَغُسْطُس", "سِبْتَمْبِر", "أُكْتُوبَر", "نُوفَمْبِر", "دِيسَمْبِر"]
    static let gregorianEnglish = ["January", "February", "March", "April", "May", "June",
                                   "July", "August", "September", "October", "November", "December"]
}

/// أجزاء التاريخ التي تحتاجها الودجات، بعد تعديل الهجري من الإعدادات
nonisolated struct DateParts {
    let weekday: Int        // ٠ = الأحد
    let gDay: Int, gMonth: Int, gYear: Int
    let hDay: Int, hMonth: Int, hYear: Int
    let hMonthLength: Int

    init(_ date: Date) {
        let g = DateHelper.gregorian.dateComponents([.weekday, .day, .month, .year], from: date)
        let adjusted = DateHelper.hijriAdjusted(date)
        let h = DateHelper.hijri.dateComponents([.day, .month, .year], from: adjusted)
        weekday = (g.weekday ?? 1) - 1
        gDay = g.day ?? 1; gMonth = g.month ?? 1; gYear = g.year ?? 2026
        hDay = h.day ?? 1; hMonth = h.month ?? 1; hYear = h.year ?? 1448
        hMonthLength = DateHelper.hijri.range(of: .day, in: .month, for: adjusted)?.count ?? 30
    }

    func day(_ calendar: NameCalendar) -> Int { calendar == .hijri ? hDay : gDay }
    func month(_ calendar: NameCalendar) -> Int { calendar == .hijri ? hMonth : gMonth }
    func year(_ calendar: NameCalendar) -> Int { calendar == .hijri ? hYear : gYear }

    func monthName(_ calendar: NameCalendar, vowelled: Bool = false) -> String {
        let index = month(calendar) - 1
        switch (calendar, vowelled) {
        case (.hijri, false): return NameTables.hijri[index]
        case (.hijri, true): return NameTables.hijriVowelled[index]
        case (.gregorian, false): return NameTables.gregorian[index]
        case (.gregorian, true): return NameTables.gregorianVowelled[index]
        }
    }

    func monthEnglish(_ calendar: NameCalendar) -> String {
        calendar == .hijri ? NameTables.hijriEnglish[hMonth - 1] : NameTables.gregorianEnglish[gMonth - 1]
    }
}

// MARK: - الخطوط الخاصة بهذه الودجات
// ليست ضمن خطوط التخصيص، فلها قائمتها وتحققها الخاص
nonisolated enum DisplayFont: String, CaseIterable, Sendable {
    case amiri = "Amiri-Regular"
    case ruqaa = "ArefRuqaa-Bold"
    case gulzar = "Gulzar-Regular"
    case reemKufi = "ReemKufi-Bold"
    case handjet = "Handjet-SemiBold"
    case cormorant = "CormorantGaramond-Medium"
    case inter = "Inter-Medium"
    case interHeavy = "Inter-ExtraBold"

    func font(_ size: CGFloat) -> Font { .custom(rawValue, fixedSize: size) }

    static func validateRegistration() {
        #if DEBUG && canImport(UIKit)
        let missing = allCases.filter { UIFont(name: $0.rawValue, size: 12) == nil }.map(\.rawValue)
        assert(missing.isEmpty, "خطوط غير مسجّلة في Info.plist: \(missing.joined(separator: ", "))")
        #endif
    }
}
