//
//  PrayerNotifications.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation
import UserNotifications

// MARK: - تنبيه الأذان
// iOS يسمح بـ ٦٤ تنبيهاً معلّقاً، فنجدول ٦ أيام قادمة فقط (٣٠ تنبيهاً كحد أقصى)
// ونعيد الجدولة عند فتح التطبيق وتغيير الإعدادات وتحديث ودجات الصلاة، فتستمر بدون انقطاع.
nonisolated enum PrayerNotifications {
    enum Key {
        static let enabled = "prayer.notify.enabled"
        static let prayers = "prayer.notify.prayers"
        static let minutesBefore = "prayer.notify.before"
    }

    private static let prefix = "prayer."
    private static let days = 6

    static var isEnabled: Bool { AppGroup.defaults.bool(forKey: Key.enabled) }

    /// الصلوات المفعّل تنبيهها، محفوظة كنص "0,2,3,4,5" (الكل افتراضياً)
    static var prayers: Set<PrayerName> {
        guard let raw = AppGroup.defaults.string(forKey: Key.prayers) else { return Set(PrayerName.fard) }
        return Set(raw.split(separator: ",").compactMap { Int($0).flatMap(PrayerName.init) })
    }

    static func setPrayers(_ prayers: Set<PrayerName>) {
        AppGroup.defaults.set(prayers.map { String($0.rawValue) }.sorted().joined(separator: ","), forKey: Key.prayers)
    }

    /// دقائق قبل الأذان؛ صفر يعني عند دخول الوقت
    static var minutesBefore: Int { AppGroup.defaults.integer(forKey: Key.minutesBefore) }

    static func reschedule(now: Date = .now, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        guard isEnabled else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let selected = prayers
        let before = minutesBefore
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: offset, to: now),
                  let day = PrayerSchedule.day(for: date, calendar: calendar) else { continue }
            for prayer in PrayerName.fard where selected.contains(prayer) {
                let time = day.time(prayer)
                let fire = time.addingTimeInterval(Double(-before * 60))
                guard fire > now else { continue }
                let content = UNMutableNotificationContent()
                if before == 0 {
                    content.title = "حان الآن وقت صلاة \(prayer.title)"
                } else {
                    content.title = "بقي \(DateHelper.arabic(before)) دقيقة على صلاة \(prayer.title)"
                }
                content.body = "\(day.location.city) · \(PrayerSchedule.format(time))"
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let id = "\(prefix)\(prayer.rawValue).\(Int(fire.timeIntervalSince1970))"
                try? await center.add(UNNotificationRequest(identifier: id, content: content,
                                                            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
            }
        }
    }
}
