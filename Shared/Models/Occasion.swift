//
//  Occasion.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import UserNotifications
import WidgetKit

// MARK: - الحفظ والتذكير
// النموذج والقراءة في OccasionModel.swift حتى تقرأه الساعة دون الودجات والتنبيهات
extension OccasionStore {
    private static let reminderPrefix = "myoccasion."

    /// يحفظ، ويحدّث ودجات المناسبات وتذكيراتها
    @MainActor
    static func save(_ occasions: [Occasion], in defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(try? JSONEncoder().encode(occasions), forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.specialOccasion.rawValue)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.dailyOverview.rawValue)
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
        var requests: [(Date, UNNotificationRequest)] = []
        for occasion in occasions where occasion.remindsDayBefore {
            var reference = now
            // نجدد عدة مواعيد مسبقاً حتى يستمر التذكير السنوي دون فتح التطبيق كل سنة.
            for _ in 0..<(occasion.repeatsYearly ? 3 : 1) {
                let target = occasion.nextDate(from: reference)
                let years = occasion.yearsAtNext(from: reference)
                reference = calendar.date(byAdding: .day, value: 1, to: target) ?? target.addingTimeInterval(86_400)
                guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: target)),
                      let fireDate = calendar.date(bySettingHour: AppSettings.reminderHour, minute: 0, second: 0, of: dayBefore),
                      fireDate > now else { continue }
                let content = UNMutableNotificationContent()
                content.title = String(format: L10n.text("غداً %@"), occasion.name)
                if let years, occasion.type == .birthday {
                    content.body = String(format: L10n.text("يكمل %@ سنة · %@"), DateHelper.arabic(years), DateHelper.weekdayDayMonth(target))
                } else {
                    content.body = String(format: L10n.text("باقي يوم على %@ · %@"), occasion.name, DateHelper.weekdayDayMonth(target))
                }
                content.sound = .default
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let request = UNNotificationRequest(
                    identifier: reminderPrefix + occasion.id.uuidString + "." + String(Int(fireDate.timeIntervalSince1970)),
                    content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
                requests.append((fireDate, request))
            }
        }
        // نترك مساحة للتنبيهات الأخرى، ونقدّم المناسبات الأقرب عند بلوغ حد النظام.
        let otherCount = await center.pendingNotificationRequests().count
        for (_, request) in requests.sorted(by: { $0.0 < $1.0 }).prefix(max(0, 64 - otherCount)) {
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
