//
//  Payday.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import Foundation
import UserNotifications
import WidgetKit

// MARK: - مواعيد الصرف
// كل دفعة شهرية لها يوم في الشهر الميلادي، وتُنقل إذا وقع في الإجازة الأسبوعية (الجمعة والسبت).
// المواعيد الرسمية المعروفة:
// - الرواتب الحكومية: يوم ٢٧، الجمعة ← الخميس، والسبت ← الأحد (وزارة المالية)
// - حساب المواطن: يوم ١٠، الجمعة ← الخميس، والسبت ← الأحد
// - حافز: يوم ٥ (صندوق تنمية الموارد البشرية «هدف»)
// - معاشات التقاعد: يوم ١، وتُقدَّم لآخر يوم عمل قبل الإجازة (التأمينات الاجتماعية)
// الإجازات الرسمية كالعيد تتغير كل سنة، فيعدّلها المستخدم بـ «موعد استثنائي».
nonisolated enum Payday: String, CaseIterable, Identifiable, Codable, Sendable {
    case salary, citizenAccount, hafiz, retirement

    var id: Self { self }

    var title: String {
        switch self {
        case .salary:         "الراتب"
        case .citizenAccount: "حساب المواطن"
        case .hafiz:          "حافز"
        case .retirement:     "التقاعد"
        }
    }

    var symbol: String {
        switch self {
        case .salary:         "banknote.fill"
        case .citizenAccount: "person.2.fill"
        case .hafiz:          "briefcase.fill"
        case .retirement:     "sun.horizon.fill"
        }
    }

    /// اليوم الرسمي في الشهر الميلادي
    var officialDay: Int {
        switch self {
        case .salary:         27
        case .citizenAccount: 10
        case .hafiz:          5
        case .retirement:     1
        }
    }

    var officialShift: WeekendShift {
        self == .retirement ? .before : .nearest
    }

    /// مصدر الموعد الرسمي، يظهر تحت الإعدادات
    var officialNote: String {
        switch self {
        case .salary:
            "الرواتب الحكومية يوم ٢٧ من كل شهر ميلادي. للقطاع الخاص اختر يوم راتبك."
        case .citizenAccount:
            "يُودَع الدعم يوم ١٠ من كل شهر ميلادي."
        case .hafiz:
            "يُصرف حافز يوم ٥ من كل شهر ميلادي."
        case .retirement:
            "معاشات التقاعد المدني والعسكري والتأمينات يوم ١ من كل شهر ميلادي، وتُقدَّم إذا صادف إجازة."
        }
    }

    var widgetKind: WidgetKind {
        switch self {
        case .salary:         .salary
        case .citizenAccount: .citizenAccount
        case .hafiz:          .hafiz
        case .retirement:     .retirement
        }
    }

    // MARK: الإعدادات
    enum Key {
        static func day(_ payday: Payday) -> String { "payday.\(payday.rawValue).day" }
        static func shift(_ payday: Payday) -> String { "payday.\(payday.rawValue).shift" }
        static func reminder(_ payday: Payday) -> String { "payday.\(payday.rawValue).reminder" }
        static func listed(_ payday: Payday) -> String { "payday.\(payday.rawValue).listed" }
        static func amount(_ payday: Payday) -> String { "payday.\(payday.rawValue).amount" }
        static func name(_ payday: Payday) -> String { "payday.\(payday.rawValue).name" }
        static func overrideDate(_ payday: Payday) -> String { "payday.\(payday.rawValue).override" }
        static func overrideMonth(_ payday: Payday) -> String { "payday.\(payday.rawValue).overrideMonth" }
        static let showsAmount = "payday.showsAmount"
    }

    private var defaults: UserDefaults { AppGroup.defaults }

    var day: Int { defaults.object(forKey: Key.day(self)) as? Int ?? officialDay }
    var shift: WeekendShift {
        defaults.string(forKey: Key.shift(self)).flatMap(WeekendShift.init) ?? officialShift
    }
    var reminder: PaydayReminder {
        defaults.string(forKey: Key.reminder(self)).flatMap(PaydayReminder.init) ?? .off
    }
    /// يظهر في ودجت «مواعيد الصرف»
    var isListed: Bool { defaults.object(forKey: Key.listed(self)) as? Bool ?? true }
    /// المبلغ الشهري إن أدخله المستخدم (صفر = لا يُعرض)
    var amount: Int { defaults.integer(forKey: Key.amount(self)) }
    /// اسم يختاره المستخدم بدل الاسم الافتراضي («راتب الشركة» مثلاً)
    var displayName: String {
        let name = defaults.string(forKey: Key.name(self))?.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? title : name
    }
    /// موعد استثنائي يحل محل دفعة شهر واحد (تقديم الصرف قبل العيد مثلاً)
    var overrideDate: Date? { defaults.object(forKey: Key.overrideDate(self)) as? Date }

    static var showsAmount: Bool { AppGroup.defaults.object(forKey: Key.showsAmount) as? Bool ?? true }

    var isOfficial: Bool { day == officialDay && shift == officialShift }

    /// يرجع الموعد والنقل للرسمي، ويحذف الموعد الاستثنائي
    func resetToOfficial() {
        defaults.removeObject(forKey: Key.day(self))
        defaults.removeObject(forKey: Key.shift(self))
        setOverride(nil)
    }

    // MARK: الحساب
    private static var calendar: Calendar { DateHelper.gregorian }

    /// موعد دفعة شهر معيّن بعد نقله من الإجازة، أو الموعد الاستثنائي إن حُدّد لهذا الشهر
    func payDate(year: Int, month: Int) -> Date {
        let calendar = Self.calendar
        if let override = overrideDate, overrideMonth == year * 100 + month {
            return calendar.startOfDay(for: override)
        }
        return regularDate(year: year, month: month)
    }

    /// الموعد المعتاد: يوم الصرف (٣١ في شهر من ٣٠ يوماً يصير آخر يوم) بعد نقله من الإجازة
    func regularDate(year: Int, month: Int) -> Date {
        let calendar = Self.calendar
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let days = calendar.range(of: .day, in: .month, for: first)?.count,
              let nominal = calendar.date(from: DateComponents(year: year, month: month, day: min(day, days)))
        else { return .distantFuture }
        let offset = shift.offset(weekday: calendar.component(.weekday, from: nominal))
        return calendar.date(byAdding: .day, value: offset, to: nominal) ?? nominal
    }

    /// شهر الدفعة التي يحل محلها الموعد الاستثنائي (السنة × ١٠٠ + الشهر)
    private var overrideMonth: Int { defaults.integer(forKey: Key.overrideMonth(self)) }

    /// يجعل الدفعة القادمة في يوم آخر (nil يلغي ذلك)؛ تنتهي تلقائياً بعد مرور شهرها
    func setOverride(_ date: Date?, now: Date = .now) {
        guard let date else {
            defaults.removeObject(forKey: Key.overrideDate(self))
            defaults.removeObject(forKey: Key.overrideMonth(self))
            return
        }
        let upcoming = months(around: now).first { regularDate(year: $0.year, month: $0.month) >= Self.calendar.startOfDay(for: now) }
        guard let upcoming else { return }
        defaults.set(Self.calendar.startOfDay(for: date), forKey: Key.overrideDate(self))
        defaults.set(upcoming.year * 100 + upcoming.month, forKey: Key.overrideMonth(self))
    }

    /// الموعد الاستثنائي إن كان لدفعة لم تمضِ بعد
    func activeOverride(now: Date = .now) -> Date? {
        guard let overrideDate, overrideDate >= Self.calendar.startOfDay(for: now) else { return nil }
        return overrideDate
    }

    private func months(around now: Date) -> [(year: Int, month: Int)] {
        let calendar = Self.calendar
        // الموعد قد يُقدَّم للشهر السابق (يوم ١ يوافق السبت)، فنبدأ من الشهر الماضي
        return (-2...3).compactMap { calendar.date(byAdding: .month, value: $0, to: now) }.map {
            (calendar.component(.year, from: $0), calendar.component(.month, from: $0))
        }
    }

    /// الدفعة القادمة والسابقة: يوم الصرف نفسه يبقى «اليوم» حتى نهايته
    func cycle(from now: Date = .now) -> PaydayCycle {
        let calendar = Self.calendar
        let today = calendar.startOfDay(for: now)
        let dates = months(around: today).map { payDate(year: $0.year, month: $0.month) }.sorted()
        let index = dates.firstIndex { $0 >= today } ?? dates.count - 1
        let next = dates[index]
        let previous = index > 0 ? dates[index - 1] : calendar.date(byAdding: .month, value: -1, to: next) ?? next
        return PaydayCycle(payday: self, next: next, previous: previous, today: today)
    }

    /// يحدّث ودجات المال وتنبيهاتها بعد أي تغيير في الإعدادات
    @MainActor
    static func settingsChanged() {
        for kind in WidgetKind.allCases where kind.category == .finance {
            WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        }
        Task { await PaydayNotifications.reschedule() }
    }
}

// MARK: - دورة الصرف
nonisolated struct PaydayCycle: Sendable {
    let payday: Payday
    let next: Date
    let previous: Date
    let today: Date

    var days: Int {
        DateHelper.gregorian.dateComponents([.day], from: today, to: next).day ?? 0
    }

    var isToday: Bool { days == 0 }

    /// كم مضى من الانتظار منذ الدفعة السابقة (٠ إلى ١)
    var progress: Double {
        let total = next.timeIntervalSince(previous)
        guard total > 0 else { return 1 }
        return min(max(today.timeIntervalSince(previous) / total, 0), 1)
    }

    /// تغيّر موعد هذه الدفعة عن يومها المعتاد (بسبب الإجازة أو موعد استثنائي)
    var isMoved: Bool {
        DateHelper.gregorian.component(.day, from: next) != payday.day
    }
}

// MARK: - النقل من الإجازة
nonisolated enum WeekendShift: String, CaseIterable, Identifiable, Sendable {
    /// الجمعة ← الخميس، والسبت ← الأحد
    case nearest
    /// يُقدَّم إلى الخميس
    case before
    /// يُؤجَّل إلى الأحد
    case after
    /// لا يتغيّر
    case none

    var id: Self { self }

    var title: String {
        switch self {
        case .nearest: "الأقرب"
        case .before:  "تقديم"
        case .after:   "تأخير"
        case .none:    "بدون"
        }
    }

    var detail: String {
        switch self {
        case .nearest: "الجمعة يُقدَّم للخميس، والسبت يُؤجَّل للأحد"
        case .before:  "الجمعة والسبت يُقدَّمان للخميس"
        case .after:   "الجمعة والسبت يُؤجَّلان للأحد"
        case .none:    "يبقى في يومه حتى لو كان إجازة"
        }
    }

    /// كم يوماً يُنقل الموعد حسب يوم الأسبوع (الأحد = ١ … الجمعة = ٦، السبت = ٧)
    func offset(weekday: Int) -> Int {
        switch (self, weekday) {
        case (.nearest, 6), (.before, 6): -1
        case (.nearest, 7), (.after, 7):  1
        case (.before, 7):                -2
        case (.after, 6):                 2
        default:                          0
        }
    }
}

// MARK: - التنبيه
nonisolated enum PaydayReminder: String, CaseIterable, Identifiable, Sendable {
    case off, dayBefore, onDay

    var id: Self { self }

    var title: String {
        switch self {
        case .off:       "بدون"
        case .dayBefore: "قبلها بيوم"
        case .onDay:     "يوم الصرف"
        }
    }
}

nonisolated enum PaydayNotifications {
    private static let prefix = "payday."

    /// تنبيه للدفعتين القادمتين من كل نوع فعّل تنبيهه، في ساعة التذكير من الإعدادات
    static func reschedule(now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        let enabled = Payday.allCases.filter { $0.reminder != .off }
        guard !enabled.isEmpty else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let calendar = DateHelper.gregorian
        for payday in enabled {
            let first = payday.cycle(from: now).next
            let second = payday.cycle(from: calendar.date(byAdding: .day, value: 1, to: first) ?? first).next
            for target in [first, second] {
                let day = payday.reminder == .dayBefore ? calendar.date(byAdding: .day, value: -1, to: target) : target
                guard let day, let fire = calendar.date(bySettingHour: AppSettings.reminderHour, minute: 0, second: 0, of: day),
                      fire > now else { continue }
                let content = UNMutableNotificationContent()
                let name = payday.displayName
                if payday.reminder == .dayBefore {
                    content.title = "غداً موعد \(name)"
                    content.body = DateHelper.weekdayDayMonth(target)
                } else {
                    content.title = "اليوم موعد \(name)"
                    content.body = payday.amount > 0 && Payday.showsAmount
                        ? "\(PaydayFormat.amount(payday.amount)) · \(DateHelper.weekdayDayMonth(target))"
                        : DateHelper.weekdayDayMonth(target)
                }
                content.sound = .default
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let id = "\(prefix)\(payday.rawValue).\(Int(fire.timeIntervalSince1970))"
                try? await center.add(UNNotificationRequest(identifier: id, content: content,
                                                            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
            }
        }
    }
}

// MARK: - تنسيق
nonisolated enum PaydayFormat {
    /// ٨٬٥٠٠ ر.س
    static func amount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar@numbers=arab")
        formatter.numberStyle = .decimal
        return "\(formatter.string(from: NSNumber(value: value)) ?? "\(value)") ر.س"
    }

    /// تمييز العدد: «يوم متبقٍ»، «أيام متبقية»، «يومًا متبقيًا»
    static func unit(_ days: Int, remaining: Bool = true) -> String {
        switch days {
        case 1:      remaining ? "يوم متبقٍ" : "يوم"
        case 2:      remaining ? "يومان متبقيان" : "يومان"
        case 3...10: remaining ? "أيام متبقية" : "أيام"
        default:     remaining ? "يومًا متبقيًا" : "يومًا"
        }
    }

    /// «اليوم»، «غداً»، «بعد ١٢ يومًا»
    static func remaining(_ days: Int) -> String {
        switch days {
        case 0:  "اليوم"
        case 1:  "غداً"
        case 2:  "بعد يومين"
        case 3...10: "بعد \(DateHelper.arabic(days)) أيام"
        default: "بعد \(DateHelper.arabic(days)) يومًا"
        }
    }
}
