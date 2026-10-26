//
//  TasbeehCounter.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import Foundation

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

    // MARK: مزامنة الساعة
    /// مفتاح رسالة «صفّر اليوم» بين الآيفون والساعة
    static let resetKey = "tasbeeh.reset"

    /// عدد اليوم لكل ذكر بمفاتيحه، لإرساله للجهاز الآخر
    static func snapshot(on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) -> [String: Any] {
        var values: [String: Any] = [:]
        for dhikr in TasbeehDhikr.allCases where defaults.string(forKey: dhikr.dayKey) == dayID(for: date) {
            values[dhikr.dayKey] = dayID(for: date)
            values[dhikr.countKey] = defaults.integer(forKey: dhikr.countKey)
        }
        return values
    }

    /// يدمج أعداداً وصلت من الجهاز الآخر: لليوم نفسه يبقى الأكبر حتى لا تضيع ضغطات أي جهاز،
    /// وأعداد الأيام الماضية تُهمل. يرجع true إذا تغيّر شيء.
    @discardableResult
    static func merge(_ values: [String: Any], on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) -> Bool {
        let today = dayID(for: date)
        var changed = false
        if values[resetKey] as? String == today {
            resetToday(in: defaults)
            changed = true
        }
        for dhikr in TasbeehDhikr.allCases {
            guard values[dhikr.dayKey] as? String == today, let incoming = values[dhikr.countKey] as? Int,
                  incoming > count(of: dhikr, on: date, in: defaults) else { continue }
            defaults.set(today, forKey: dhikr.dayKey)
            defaults.set(incoming, forKey: dhikr.countKey)
            changed = true
        }
        return changed
    }

    /// مفاتيح الأعداد كلها، حتى لا تُكتب كما هي فوق عدد أكبر
    static var syncKeys: Set<String> {
        Set(TasbeehDhikr.allCases.flatMap { [$0.countKey, $0.dayKey] } + [resetKey])
    }
}
