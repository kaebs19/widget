//
//  OccasionModel.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

// MARK: - نوع المناسبة
nonisolated enum OccasionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case birthday, wedding, graduation, newborn, travel, custom

    var id: Self { self }

    var title: String { L10n.text(titleKey) }


    private var titleKey: String {
        switch self {
        case .birthday:   "عيد ميلاد"
        case .wedding:    "ذكرى زواج"
        case .graduation: "تخرّج"
        case .newborn:    "مولود"
        case .travel:     "سفر"
        case .custom:     "مناسبة"
        }
    }

    var symbol: String {
        switch self {
        case .birthday:   "birthday.cake"
        case .wedding:    "heart"
        case .graduation: "graduationcap"
        case .newborn:    "figure.and.child.holdinghands"
        case .travel:     "airplane"
        case .custom:     "star"
        }
    }

    /// المناسبات التي تُحسب سنواتها (عمر، سنوات زواج)
    var countsYears: Bool { self == .birthday || self == .wedding }

    /// افتراضياً تتكرر كل سنة، إلا السفر والتخرّج
    var repeatsByDefault: Bool { self != .travel && self != .graduation }
}

nonisolated enum OccasionCalendar: String, Codable, CaseIterable, Identifiable, Sendable {
    case gregorian, hijri
    var id: Self { self }
    var title: String { L10n.text(self == .hijri ? "هجري" : "ميلادي") }
    var calendar: Calendar { self == .hijri ? DateHelper.hijri : DateHelper.gregorian }

    /// نحافظ على الشهر واليوم الأصليين، ونقصر اليوم عند غيابه في السنة الجديدة.
    func nextDate(for date: Date, repeats: Bool, from now: Date) -> Date {
        let cal = calendar
        let original = cal.startOfDay(for: date)
        let today = cal.startOfDay(for: now)
        guard repeats, original < today else { return original }
        let parts = cal.dateComponents([.month, .day], from: original)
        let year = cal.component(.year, from: today)
        for nextYear in year...(year + 2) {
            guard let first = cal.date(from: DateComponents(year: nextYear, month: parts.month, day: 1)),
                  let range = cal.range(of: .day, in: .month, for: first),
                  let candidate = cal.date(byAdding: .day, value: min(parts.day ?? 1, range.count) - 1, to: first)
            else { continue }
            if candidate >= today { return candidate }
        }
        return original
    }
}

// MARK: - مناسبة
/// مناسبة يحفظها المستخدم من التطبيق، ويختارها لأي ودجت «مناسبة خاصة» من «تعديل الودجت».
nonisolated struct Occasion: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    var type: OccasionType = .birthday
    /// التاريخ الأصلي (للميلاد: يوم الولادة بسنته، فنحسب العمر)
    var date: Date
    var repeatsYearly = true
    var remindsDayBefore = false
    /// اختياري حتى تُقرأ المناسبات القديمة دون ترحيل بيانات.
    var calendarType: OccasionCalendar? = nil
    var recurrenceCalendar: OccasionCalendar { calendarType ?? .gregorian }

    /// الموعد القادم
    func nextDate(from now: Date = .now) -> Date {
        recurrenceCalendar.nextDate(for: date, repeats: repeatsYearly, from: now)
    }

    /// كم سنة تكمل في الموعد القادم (العمر أو سنوات الزواج)؛ nil إذا لا معنى لها
    func yearsAtNext(from now: Date = .now) -> Int? {
        guard type.countsYears, repeatsYearly else { return nil }
        let calendar = recurrenceCalendar.calendar
        let years = calendar.component(.year, from: nextDate(from: now)) - calendar.component(.year, from: date)
        return years > 0 ? years : nil
    }
}

// MARK: - القراءة
nonisolated enum OccasionStore {
    static let key = "occasions"

    static func all(in defaults: UserDefaults = AppGroup.defaults) -> [Occasion] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Occasion].self, from: data)) ?? []
    }

    static func occasion(id: UUID, in defaults: UserDefaults = AppGroup.defaults) -> Occasion? {
        all(in: defaults).first { $0.id == id }
    }

    static func upcoming(from date: Date = .now) -> [Occasion] {
        all().filter { $0.repeatsYearly || $0.nextDate(from: date) >= DateHelper.gregorian.startOfDay(for: date) }
            .sorted { $0.nextDate(from: date) < $1.nextDate(from: date) }
    }
}
