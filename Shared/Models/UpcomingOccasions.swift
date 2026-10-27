//
//  UpcomingOccasions.swift
//  Widgets
//
//  Created by Mohammed Saleh on 28/10/2026.
//

import Foundation

// MARK: - المناسبات القادمة
/// المناسبات العامة ومناسبات المستخدم في قائمة واحدة مرتبة بالأقرب، للساعة ووجهها
nonisolated struct UpcomingOccasion: Identifiable, Sendable {
    let id: String
    let title: String
    let symbol: String
    let date: Date
    let days: Int

    /// «اليوم»، «غداً»، «بعد ١٢ يوم»
    var remaining: String {
        switch days {
        case 0: L10n.text("اليوم")
        case 1: L10n.text("غداً")
        default: String(format: L10n.text("بعد %@ يوم"), DateHelper.arabic(days))
        }
    }
}

nonisolated enum UpcomingOccasions {
    static func list(from now: Date = .now) -> [UpcomingOccasion] {
        let eid = DateHelper.nextEid(from: now)
        var items = [
            UpcomingOccasion(id: "ramadan", title: L10n.text("رمضان"), symbol: "moon.stars.fill",
                             date: DateHelper.nextHijri(month: 9, day: 1, from: now),
                             days: DateHelper.daysUntilHijri(month: 9, day: 1, from: now)),
            UpcomingOccasion(id: "eid", title: L10n.text(eid.name), symbol: "sparkles", date: eid.date, days: eid.days),
            UpcomingOccasion(id: "nationalDay", title: L10n.text("اليوم الوطني"), symbol: "flag.fill",
                             date: DateHelper.nextGregorian(month: 9, day: 23, from: now),
                             days: DateHelper.daysUntilGregorian(month: 9, day: 23, from: now)),
            UpcomingOccasion(id: "foundingDay", title: L10n.text("يوم التأسيس"), symbol: "flag.fill",
                             date: DateHelper.nextGregorian(month: 2, day: 22, from: now),
                             days: DateHelper.daysUntilGregorian(month: 2, day: 22, from: now)),
        ]
        let today = DateHelper.gregorian.startOfDay(for: now)
        for occasion in OccasionStore.upcoming(from: now) {
            let next = occasion.nextDate(from: now)
            let days = DateHelper.gregorian.dateComponents([.day], from: today, to: DateHelper.gregorian.startOfDay(for: next)).day ?? 0
            items.append(UpcomingOccasion(id: occasion.id.uuidString, title: occasion.name, symbol: occasion.type.symbol,
                                          date: next, days: max(days, 0)))
        }
        return items.sorted { $0.days < $1.days }
    }
}
