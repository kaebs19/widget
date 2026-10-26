import Foundation

nonisolated enum AppGroup {
    static let defaults = UserDefaults(suiteName: "widgets.localization.tests.\(UUID().uuidString)")!
}

@main
struct LocalizationChecks {
    static func main() {
        precondition(AppLanguage.system.resolvedCode(preferredLanguages: ["en-US", "ar-SA"]) == "en")
        precondition(AppLanguage.system.resolvedCode(preferredLanguages: ["ar-SA", "en-US"]) == "ar")
        precondition(AppLanguage.arabic.resolvedCode(preferredLanguages: ["en"]) == "ar")
        precondition(AppLanguage.english.resolvedCode(preferredLanguages: ["ar"]) == "en")
        precondition(AppLanguage.arabic.isRightToLeft && !AppLanguage.english.isRightToLeft)
        AppGroup.defaults.set("invalid", forKey: AppLanguage.preferenceKey)
        precondition(AppLanguage.current == .system)
        AppGroup.defaults.set("en", forKey: AppLanguage.preferenceKey)
        precondition(AppLanguage.current == .english)
        precondition(L10n.widgetCount(1) == "1 widget")
        precondition(L10n.widgetCount(2) == "2 widgets")
        if CommandLine.arguments.count > 1, let bundle = Bundle(path: CommandLine.arguments[1]) {
            precondition(L10n.text("الإعدادات", language: .english, bundle: bundle) == "Settings")
            precondition(L10n.text("الإعدادات", language: .arabic, bundle: bundle) == "الإعدادات")
            let adhan = PrayerNotificationText.adhan(prayer: "الظهر", city: " الرياض ", minutesBefore: 0, language: .arabic, bundle: bundle)
            precondition(adhan.title == "أذان الظهر")
            precondition(adhan.body == "حان وقت أذان الظهر في مدينة الرياض.")
            let early = PrayerNotificationText.adhan(prayer: "الظهر", city: "Riyadh", minutesBefore: 10, language: .english, bundle: bundle)
            precondition(early.body == "Time until Dhuhr prayer in Riyadh: 10 minutes.")
            let missingCity = PrayerNotificationText.adhan(prayer: "الفجر", city: "  ", minutesBefore: -5, language: .english, bundle: bundle)
            precondition(missingCity.body == "It is time for Fajr prayer at your selected location.")
            precondition(PrayerNotificationText.adhkarTitle(prayer: "العصر", language: .english, bundle: bundle) == "Remembrance after Asr prayer")
            precondition(L10n.text("missing-key", language: .english, bundle: bundle) == "missing-key")
        } else {
            fatalError("Pass a built app or extension bundle to verify compiled translations")
        }
        AppGroup.defaults.removeObject(forKey: AppLanguage.preferenceKey)
        print("Localization checks passed")
    }
}
