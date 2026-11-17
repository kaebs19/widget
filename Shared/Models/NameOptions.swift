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
    /// لكل خط لوحته: مستوحاة من التصميم الأصلي مع تدرّج يعطيها عمقاً
    var palette: NamePalette {
        switch self {
        case .naskh:    NamePalette(0x2B3990, 0x161D52, ink: 0xF3EEDF, accent: 0xE8C77E)   // نيلي
        case .ruqaa:    NamePalette(0xF6F1E6, 0xE6DCC6, ink: 0x1B1A17, accent: 0x9A6B1F)   // ورقي
        case .nastaliq: NamePalette(0x14523F, 0x0A2C22, ink: 0xEBD198, accent: 0xEBD198)   // زمردي وذهبي
        case .kufi:     NamePalette(0x9B2335, 0x4E0F1C, ink: 0xFFFFFF, accent: 0xFFC56B)   // عنابي
        case .dots:     NamePalette(0x15171C, 0x0A0B0E, ink: 0xFFB84D, accent: 0xFFB84D)   // كهرماني على أسود
        case .english:  NamePalette(0x45285A, 0x22122F, ink: 0xF4EEE6, accent: 0xD9B36C)   // بنفسجي
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
        // خط افتراضي مختلف لكل ودجت، فتتنوّع الألوان في المعرض
        if kind == .styledHijriMonth { shape = .nastaliq }
        if kind == .styledGregorianMonth { shape = .kufi }
    }
}

extension NameOptions {
    /// ألوان التصميم: الخط المختار له ألوانه، والبقية داكنة بنص عاجي ولون برتقالي
    static func designStyle(for kind: WidgetKind) -> WidgetStyle {
        let palette = kind.usesShape ? load(for: kind).shape.palette : NamePalette.forKind(kind)
        var style = WidgetStyle.default
        style.background = palette.top == palette.bottom
            ? .color(Color.Resolved(hex: palette.top))
            : .gradient(Color.Resolved(hex: palette.top), Color.Resolved(hex: palette.bottom))
        style.textColor = Color.Resolved(hex: palette.ink)
        style.accentColor = Color.Resolved(hex: palette.accent)
        return style
    }
}

/// ألوان ودجت: تدرّج الخلفية من الأعلى للأسفل، ولون النص، ولون التمييز
nonisolated struct NamePalette: Sendable {
    let top: UInt32, bottom: UInt32, ink: UInt32, accent: UInt32
    init(_ top: UInt32, _ bottom: UInt32, ink: UInt32, accent: UInt32) {
        self.top = top; self.bottom = bottom; self.ink = ink; self.accent = accent
    }

    /// كل ودجت بلون مختلف حتى يتميّز في المعرض والشاشة الرئيسية
    static func forKind(_ kind: WidgetKind) -> NamePalette {
        switch kind {
        case .monthBehind:    NamePalette(0xC2415B, 0x6E1F45, ink: 0xFFF6EE, accent: 0xFFD27A)   // وردي غروبي
        case .dayNumber:      NamePalette(0x2477C9, 0x123F7A, ink: 0xFFFFFF, accent: 0xFFCF5C)   // أزرق
        case .monthNumber:    NamePalette(0x2F8F6A, 0x14503B, ink: 0xFFFFFF, accent: 0xF3D58A)   // أخضر
        case .bothDates:      NamePalette(0xF5EBDC, 0xE6D3B3, ink: 0x3A2E1F, accent: 0xA85A26)   // رملي
        case .weekRibbon:     NamePalette(0x6C4FD1, 0x37207A, ink: 0xFFFFFF, accent: 0xFFD166)   // بنفسجي
        case .monthProgress:  NamePalette(0x22A094, 0x0F5F58, ink: 0xFFFFFF, accent: 0xFFE08A)   // فيروزي
        case .bigNumber:      NamePalette(0xF29A3A, 0xC4470F, ink: 0xFFFFFF, accent: 0xFFF1D6)   // برتقالي
        case .hijriCountdown: NamePalette(0x1E2F57, 0x0A1228, ink: 0xF3EEDF, accent: 0xF5C26B)   // ليلي
        case .circleBadge:    NamePalette(0xFBFAF7, 0xECE7DD, ink: 0x1E1E1E, accent: 0xC27C0E)   // لؤلؤي
        default:              NamePalette(0x1C1C1E, 0x1C1C1E, ink: 0xF2EEE2, accent: 0xF5A623)
        }
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
