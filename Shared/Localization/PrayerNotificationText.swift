import Foundation

/// Copy is separate from scheduling so names, missing cities, and languages can be verified.
nonisolated enum PrayerNotificationText {
    struct Message {
        let title: String
        let body: String
    }

    static func adhan(prayer: String, city: String, minutesBefore: Int,
                      language: AppLanguage = .current, bundle: Bundle = .main) -> Message {
        func localized(_ key: String) -> String { L10n.text(key, language: language, bundle: bundle) }
        let name = localized(prayer)
        let place = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let before = max(0, minutesBefore)
        let title = String(format: localized(before == 0 ? "أذان %@" : "اقترب أذان %@"), name)
        let body: String
        if before == 0 {
            body = place.isEmpty
                ? String(format: localized("حان وقت أذان %@ حسب الموقع المحدد."), name)
                : String(format: localized("حان وقت أذان %@ في مدينة %@."), name, place)
        } else {
            let minutes = before.formatted(.number.locale(language.locale))
            body = place.isEmpty
                ? String(format: localized("متبقي على أذان %@: %@ دقيقة، حسب الموقع المحدد."), name, minutes)
                : String(format: localized("متبقي على أذان %@ في مدينة %@: %@ دقيقة."), name, place, minutes)
        }
        return Message(title: title, body: body)
    }

    static func adhkarTitle(prayer: String, language: AppLanguage = .current, bundle: Bundle = .main) -> String {
        String(format: L10n.text("تذكير بأذكار صلاة %@", language: language, bundle: bundle),
               L10n.text(prayer, language: language, bundle: bundle))
    }
}
