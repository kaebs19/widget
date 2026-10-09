//
//  OccasionReminders.swift
//  WidgetsExtension
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation
import UserNotifications
import WidgetKit

// MARK: - تذكير المناسبة الخاصة
// كل ودجت مناسبة فعّل «ذكّرني قبل يوم» له تنبيه الساعة ٩ صباح اليوم السابق.
// نقرأ إعدادات كل الودجات المضافة، فالتنبيهات تبقى مطابقة لها حتى لو حُذف ودجت أو تغيّر تاريخه.
// إذن التنبيهات يُطلب من التطبيق، فبدونه لا نجدول شيئاً.
enum OccasionReminders {
    private static let prefix = "occasion."
    private static let hour = 9

    static func sync(now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let configurations = (try? await WidgetCenter.shared.currentConfigurations()) ?? []
        var wanted: [String: UNNotificationRequest] = [:]
        for info in configurations where info.kind == WidgetKind.specialOccasion.rawValue {
            guard let intent = info.widgetConfigurationIntent(of: SpecialOccasionIntent.self),
                  intent.remindsDayBefore, let date = intent.date,
                  let request = request(name: intent.name, date: date, repeatsYearly: intent.repeatsYearly, now: now)
            else { continue }
            wanted[request.identifier] = request
        }

        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { wanted[$0] == nil })
        for (id, request) in wanted where !pending.contains(id) {
            try? await center.add(request)
        }
    }

    private static func request(name: String, date: Date, repeatsYearly: Bool, now: Date) -> UNNotificationRequest? {
        let calendar = DateHelper.gregorian
        let target = DateHelper.nextOccurrence(of: date, repeatsYearly: repeatsYearly, from: now)
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: target)),
              let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayBefore),
              fireDate > now else { return nil }

        let content = UNMutableNotificationContent()
        content.title = "غداً \(name)"
        content.body = "باقي يوم على \(name) · \(DateHelper.weekdayDayMonth(target))"
        content.sound = .default

        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        // المعرّف من الاسم والموعد: نفس المناسبة في ودجتين تنبّه مرة واحدة
        let id = "\(prefix)\(name).\(Int(fireDate.timeIntervalSince1970))"
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }
}
