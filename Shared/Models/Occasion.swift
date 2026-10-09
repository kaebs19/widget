//
//  Occasion.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import Foundation
import UserNotifications
import WidgetKit

// MARK: - نوع المناسبة
nonisolated enum OccasionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case birthday, wedding, graduation, newborn, travel, custom

    var id: Self { self }

    var title: String {
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

    /// الموعد القادم
    func nextDate(from now: Date = .now) -> Date {
        DateHelper.nextOccurrence(of: date, repeatsYearly: repeatsYearly, from: now)
    }

    /// كم سنة تكمل في الموعد القادم (العمر أو سنوات الزواج)؛ nil إذا لا معنى لها
    func yearsAtNext(from now: Date = .now) -> Int? {
        guard type.countsYears, repeatsYearly else { return nil }
        let calendar = DateHelper.gregorian
        let years = calendar.component(.year, from: nextDate(from: now)) - calendar.component(.year, from: date)
        return years > 0 ? years : nil
    }
}

// MARK: - الحفظ
nonisolated enum OccasionStore {
    private static let key = "occasions"
    private static let reminderPrefix = "myoccasion."

    static func all(in defaults: UserDefaults = AppGroup.defaults) -> [Occasion] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Occasion].self, from: data)) ?? []
    }

    static func occasion(id: UUID, in defaults: UserDefaults = AppGroup.defaults) -> Occasion? {
        all(in: defaults).first { $0.id == id }
    }

    /// يحفظ، ويحدّث ودجات المناسبات وتذكيراتها
    @MainActor
    static func save(_ occasions: [Occasion], in defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(try? JSONEncoder().encode(occasions), forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.specialOccasion.rawValue)
        Task { await scheduleReminders(for: occasions) }
    }

    /// تنبيه في اليوم السابق لكل مناسبة فعّل تذكيرها، في الساعة المختارة من الإعدادات
    @MainActor
    static func scheduleReminders(for occasions: [Occasion], now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(reminderPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let calendar = DateHelper.gregorian
        for occasion in occasions where occasion.remindsDayBefore {
            let target = occasion.nextDate(from: now)
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: target)),
                  let fireDate = calendar.date(bySettingHour: AppSettings.reminderHour, minute: 0, second: 0, of: dayBefore),
                  fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "غداً \(occasion.name)"
            if let years = occasion.yearsAtNext(from: now), occasion.type == .birthday {
                content.body = "يكمل \(DateHelper.arabic(years)) سنة · \(DateHelper.weekdayDayMonth(target))"
            } else {
                content.body = "باقي يوم على \(occasion.name) · \(DateHelper.weekdayDayMonth(target))"
            }
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let request = UNNotificationRequest(identifier: reminderPrefix + occasion.id.uuidString, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }
    }
}

// MARK: - الربط مع «تعديل الودجت»
nonisolated struct OccasionEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "مناسبة"
    static let defaultQuery = OccasionQuery()

    let id: UUID
    let name: String
    let symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: symbol))
    }

    init(_ occasion: Occasion) {
        id = occasion.id
        name = occasion.name
        symbol = occasion.type.symbol
    }
}

nonisolated struct OccasionQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [OccasionEntity] {
        OccasionStore.all().filter { identifiers.contains($0.id) }.map(OccasionEntity.init)
    }

    func suggestedEntities() async throws -> [OccasionEntity] {
        OccasionStore.all().map(OccasionEntity.init)
    }
}
