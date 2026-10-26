// Minimal app dependencies for running the shared feature models as a macOS executable.
import Foundation

nonisolated enum AppGroup {
    static let defaults = UserDefaults(suiteName: "com.widgetar.feature-checks")!
}
nonisolated enum DateHelper {
    static let gregorian = Calendar(identifier: .gregorian)
    static let hijri = Calendar(identifier: .islamicUmmAlQura)
    static func arabic(_ value: Int) -> String { String(value) }
    static func weekdayDayMonth(_ date: Date) -> String { date.description }
}
nonisolated enum AppSettings { static let reminderHour = 9 }
nonisolated enum WidgetKind: String { case subscriptions, quranGoal, specialOccasion, dailyOverview }
nonisolated enum TasbeehCounter {
    static func dayID(for date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}
