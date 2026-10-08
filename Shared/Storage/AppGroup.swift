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

/// عدّاد الاستغفار اليومي، يبدأ من صفر كل يوم. محفوظ في المساحة المشتركة
/// فيتحدّث من زر الـ Widget في الشاشة الرئيسية ومن داخل التطبيق.
nonisolated enum IstighfarCounter {
    static let goal = 100
    static let countKey = "istighfar.count"
    static let dayKey = "istighfar.day"

    /// معرّف اليوم المحلي؛ إذا اختلف عن المحفوظ فالعدد صفر
    static func dayID(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    static func count(on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) -> Int {
        defaults.string(forKey: dayKey) == dayID(for: date) ? defaults.integer(forKey: countKey) : 0
    }

    static func increment(on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) {
        let next = count(on: date, in: defaults) + 1
        defaults.set(dayID(for: date), forKey: dayKey)
        defaults.set(next, forKey: countKey)
    }
}
