//
//  Obligation.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import Foundation
import UserNotifications
import WidgetKit

// MARK: - نوع الالتزام
nonisolated enum ObligationType: String, Codable, CaseIterable, Identifiable, Sendable {
    case rent, loan, card, bill, subscription, school, custom

    var id: Self { self }

    var title: String {
        switch self {
        case .rent:         "إيجار"
        case .loan:         "قسط"
        case .card:         "بطاقة ائتمان"
        case .bill:         "فاتورة"
        case .subscription: "اشتراك"
        case .school:       "رسوم دراسية"
        case .custom:       "التزام"
        }
    }

    var symbol: String {
        switch self {
        case .rent:         "house.fill"
        case .loan:         "building.columns.fill"
        case .card:         "creditcard.fill"
        case .bill:         "bolt.fill"
        case .subscription: "play.rectangle.fill"
        case .school:       "book.closed.fill"
        case .custom:       "pin.fill"
        }
    }

    /// الإيجار غالباً كل ستة أشهر أو سنة، والبقية شهرية
    var defaultFrequency: ObligationFrequency { self == .rent ? .semiannual : .monthly }
}

// MARK: - التكرار
nonisolated enum ObligationFrequency: Int, Codable, CaseIterable, Identifiable, Sendable {
    case monthly = 1, quarterly = 3, semiannual = 6, yearly = 12

    var id: Self { self }

    var title: String {
        switch self {
        case .monthly:    "شهري"
        case .quarterly:  "كل ٣ أشهر"
        case .semiannual: "كل ٦ أشهر"
        case .yearly:     "سنوي"
        }
    }
}

// MARK: - التزام
/// دفعة تتكرر يدفعها المستخدم: إيجار، قسط، فاتورة، اشتراك.
nonisolated struct Obligation: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    var type: ObligationType = .loan
    /// أول موعد، ومنه يُحسب يوم الشهر والتكرار
    var firstDate: Date
    var frequency: ObligationFrequency = .monthly
    /// صفر = بدون مبلغ
    var amount = 0
    /// آخر دفعة (للأقساط)؛ nil = مستمر
    var endDate: Date? = nil
    var remindsDayBefore = false

    var displayName: String { name.trimmingCharacters(in: .whitespaces).isEmpty ? type.title : name }

    private static var calendar: Calendar { DateHelper.gregorian }

    /// الدفعة رقم n (من صفر). نحسب كل واحدة من الموعد الأول، فيوم ٣١ يبقى آخر الشهر دون انزياح.
    private func occurrence(_ index: Int) -> Date? {
        Self.calendar.date(byAdding: .month, value: index * frequency.rawValue,
                           to: Self.calendar.startOfDay(for: firstDate))
    }

    private func hasEnded(at date: Date) -> Bool {
        guard let endDate else { return false }
        return date > Self.calendar.startOfDay(for: endDate)
    }

    /// المواعيد في فترة [من، إلى)
    func dates(from start: Date, to end: Date) -> [Date] {
        let calendar = Self.calendar
        let start = calendar.startOfDay(for: start)
        let months = calendar.dateComponents([.month], from: calendar.startOfDay(for: firstDate), to: start).month ?? 0
        var index = max(months / frequency.rawValue - 1, 0)
        var result: [Date] = []
        while let date = occurrence(index), date < end, !hasEnded(at: date) {
            if date >= start { result.append(date) }
            index += 1
        }
        return result
    }

    /// الموعد القادم (اليوم يبقى «اليوم» حتى نهايته)؛ nil إذا انتهى الالتزام
    func nextDate(from now: Date = .now) -> Date? {
        let calendar = Self.calendar
        let start = calendar.startOfDay(for: now)
        let horizon = calendar.date(byAdding: .month, value: frequency.rawValue + 1, to: start) ?? start
        return dates(from: start, to: horizon).first
    }

    /// كم دفعة باقية إذا حُدّدت آخر دفعة
    func remainingCount(from now: Date = .now) -> Int? {
        guard let endDate else { return nil }
        let end = Self.calendar.date(byAdding: .day, value: 1, to: Self.calendar.startOfDay(for: endDate)) ?? endDate
        return dates(from: now, to: end).count
    }
}

// MARK: - الحفظ
nonisolated enum ObligationStore {
    private static let key = "obligations"
    private static let reminderPrefix = "obligation."

    static func all(in defaults: UserDefaults = AppGroup.defaults) -> [Obligation] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Obligation].self, from: data)) ?? []
    }

    /// الالتزامات القائمة مرتبة بالأقرب
    static func upcoming(from now: Date = .now) -> [(obligation: Obligation, date: Date)] {
        all().compactMap { item in item.nextDate(from: now).map { (item, $0) } }.sorted { $0.date < $1.date }
    }

    /// مجموع ما يُستحق في فترة [من، إلى)
    static func total(from start: Date, to end: Date) -> Int {
        all().reduce(0) { $0 + $1.amount * $1.dates(from: start, to: end).count }
    }

    /// يحفظ، ويحدّث ودجات المال وتذكيرات الالتزامات
    @MainActor
    static func save(_ obligations: [Obligation], in defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(try? JSONEncoder().encode(obligations), forKey: key)
        Payday.settingsChanged()
    }

    /// تنبيه في اليوم السابق للموعد القادم لكل التزام فعّل تذكيره، في ساعة التذكير من الإعدادات
    static func scheduleReminders(now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(reminderPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        let items = all().filter(\.remindsDayBefore)
        guard !items.isEmpty else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let calendar = DateHelper.gregorian
        for item in items {
            // الموعد القادم والذي بعده، فيبقى التنبيه مستمراً حتى لو لم يُفتح التطبيق شهراً
            let horizon = calendar.date(byAdding: .month, value: item.frequency.rawValue * 2 + 1, to: now) ?? now
            for (index, target) in item.dates(from: now, to: horizon).prefix(2).enumerated() {
                guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: target),
                      let fire = calendar.date(bySettingHour: AppSettings.reminderHour, minute: 0, second: 0, of: dayBefore),
                      fire > now else { continue }
                let content = UNMutableNotificationContent()
                content.title = "غداً موعد \(item.displayName)"
                content.body = item.amount > 0
                    ? "\(PaydayFormat.amount(item.amount)) · \(DateHelper.weekdayDayMonth(target))"
                    : DateHelper.weekdayDayMonth(target)
                content.sound = .default
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let id = "\(reminderPrefix)\(item.id.uuidString).\(index)"
                try? await center.add(UNNotificationRequest(identifier: id, content: content,
                                                            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
            }
        }
    }
}
