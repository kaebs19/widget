//
//  AppGroup.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

/// مساحة مشتركة بين التطبيق والـ Widget. نفس المعرّف لازم يكون في ملفّي الـ entitlements.
nonisolated enum AppGroup {
    static let id = "group.com.app.Widgets"

    /// نسخة واحدة للتطبيق كله: @AppStorage يراقب التغييرات على نفس النسخة اللي يكتب فيها الزر
    static let defaults = UserDefaults(suiteName: id) ?? .standard
}

/// عدّاد الذكر اليومي، يبدأ من صفر كل يوم. محفوظ في المساحة المشتركة
/// فيتحدّث من زر الـ Widget في الشاشة الرئيسية ومن داخل التطبيق. لكل ذكر عدده المستقل.
nonisolated enum TasbeehCounter {
    /// معرّف اليوم المحلي؛ إذا اختلف عن المحفوظ فالعدد صفر
    static func dayID(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    static func count(of dhikr: TasbeehDhikr, on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) -> Int {
        defaults.string(forKey: dhikr.dayKey) == dayID(for: date) ? defaults.integer(forKey: dhikr.countKey) : 0
    }

    /// يصفّر عدد اليوم لكل الأذكار
    static func resetToday(in defaults: UserDefaults = AppGroup.defaults) {
        for dhikr in TasbeehDhikr.allCases {
            defaults.removeObject(forKey: dhikr.countKey)
            defaults.removeObject(forKey: dhikr.dayKey)
        }
    }

    static func increment(_ dhikr: TasbeehDhikr, on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) {
        let next = count(of: dhikr, on: date, in: defaults) + 1
        defaults.set(dayID(for: date), forKey: dhikr.dayKey)
        defaults.set(next, forKey: dhikr.countKey)
    }
}
