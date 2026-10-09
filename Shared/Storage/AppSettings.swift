//
//  AppSettings.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - إعدادات التطبيق
// كلها في المساحة المشتركة: بعضها يقرأه الـ Widget (التقويم، وقت التذكير)، وبعضها للتطبيق فقط (المظهر).
nonisolated enum AppSettings {
    enum Key {
        static let colorScheme = "settings.colorScheme"
        static let accent = "settings.accent"
        static let haptics = "settings.haptics"
        static let reminderHour = "settings.reminderHour"
        static let hijriOffset = "settings.hijriOffset"
        static let weekStart = "settings.weekStart"
    }

    /// تصحيح التاريخ الهجري بالأيام (−٢ إلى +٢) إذا اختلفت رؤية الهلال عن تقويم أم القرى
    static var hijriOffset: Int {
        AppGroup.defaults.integer(forKey: Key.hijriOffset)
    }

    /// أول يوم في شريط الأسبوع بترتيب Calendar (الأحد = ١، السبت = ٧)
    static var weekStart: Int {
        AppGroup.defaults.object(forKey: Key.weekStart) as? Int ?? 1
    }

    /// ساعة تنبيه «ذكّرني قبل يوم» في اليوم السابق للمناسبة (٠–٢٣)
    static var reminderHour: Int {
        AppGroup.defaults.object(forKey: Key.reminderHour) as? Int ?? 9
    }

    /// «الساعة ٩ صباحاً»، «الساعة ٨ مساءً»
    @MainActor
    static func reminderTimeLabel(_ hour: Int = reminderHour) -> String {
        let display = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "صباحاً" : (hour < 18 ? "ظهراً" : "مساءً")
        return "الساعة \(DateHelper.arabic(display)) \(period)"
    }
}

// MARK: - المظهر
nonisolated enum ColorSchemeChoice: String, CaseIterable, Identifiable, Sendable {
    case system, dark, light

    var id: Self { self }

    var title: String {
        switch self {
        case .system: "حسب الجهاز"
        case .dark:   "داكن"
        case .light:  "فاتح"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dark:   .dark
        case .light:  .light
        }
    }
}

/// لون التمييز في واجهة التطبيق (الأزرار والاختيارات)، لا يغيّر ألوان الودجات
nonisolated enum AppAccent: String, CaseIterable, Identifiable, Sendable {
    case gold, emerald, sky, rose, violet

    var id: Self { self }

    var title: String {
        switch self {
        case .gold:    "ذهبي"
        case .emerald: "زمردي"
        case .sky:     "سماوي"
        case .rose:    "وردي"
        case .violet:  "بنفسجي"
        }
    }

    /// لون للخلفية الداكنة وآخر أغمق للفاتحة حتى يبقى مقروءاً
    var hex: (dark: UInt32, light: UInt32) {
        switch self {
        case .gold:    (0xEBCB8B, 0x9C7430)
        case .emerald: (0x7FD6A8, 0x1E7A4C)
        case .sky:     (0x8EC5FF, 0x1F6FBF)
        case .rose:    (0xF4A6BC, 0xB23A63)
        case .violet:  (0xC4B0FF, 0x6A4CC2)
        }
    }

    static var current: AppAccent {
        AppGroup.defaults.string(forKey: AppSettings.Key.accent).flatMap(AppAccent.init) ?? .gold
    }
}

// MARK: - تطبيق المظهر
/// الأوراق (sheets) لا ترث preferredColorScheme من الجذر دائماً، فنطبّقه على كل واحدة أيضاً
struct AppAppearance: ViewModifier {
    @AppStorage(AppSettings.Key.colorScheme, store: AppGroup.defaults) private var colorScheme = ColorSchemeChoice.dark

    func body(content: Content) -> some View {
        content.preferredColorScheme(colorScheme.colorScheme)
    }
}

extension View {
    func appAppearance() -> some View { modifier(AppAppearance()) }
}
