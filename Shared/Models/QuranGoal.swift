import AppIntents
import Foundation
import WidgetKit

nonisolated enum QuranGoal {
    static var target: Int { max(1, AppGroup.defaults.object(forKey: "quranGoal.target") as? Int ?? 5) }

    static func pages(on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) -> Int {
        defaults.integer(forKey: "quranGoal.pages." + TasbeehCounter.dayID(for: date))
    }

    static func setTarget(_ value: Int) {
        AppGroup.defaults.set(min(max(value, 1), 100), forKey: "quranGoal.target")
    }

    static func setPages(_ value: Int, on date: Date = .now, in defaults: UserDefaults = AppGroup.defaults) {
        defaults.set(min(max(value, 0), 604), forKey: "quranGoal.pages." + TasbeehCounter.dayID(for: date))
    }
}

nonisolated struct AddQuranPageIntent: AppIntent {
    static let title: LocalizedStringResource = "قرأت صفحة"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        QuranGoal.setPages(QuranGoal.pages() + 1)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.quranGoal.rawValue)
        return .result()
    }
}
