import Foundation

nonisolated enum HealthGoals {
    static func key(_ metric: HealthMetric, weekday: Int) -> String { "health.goal.\(metric.rawValue).weekday.\(weekday)" }
    static func base(_ metric: HealthMetric, in defaults: UserDefaults = AppGroup.defaults) -> Double {
        let value = defaults.double(forKey: metric.goalKey)
        return value.isFinite && value > 0 ? value : metric.defaultGoal
    }
    static func goal(_ metric: HealthMetric, on date: Date, calendar: Calendar = .current,
                     in defaults: UserDefaults = AppGroup.defaults) -> Double {
        let value = defaults.double(forKey: key(metric, weekday: calendar.component(.weekday, from: date)))
        return value.isFinite && value > 0 ? value : base(metric, in: defaults)
    }
    static func set(_ value: Double?, metric: HealthMetric, weekday: Int, in defaults: UserDefaults = AppGroup.defaults) {
        guard (1...7).contains(weekday) else { return }
        if let value, value.isFinite {
            defaults.set(min(max(value, metric.goalRange.lowerBound), metric.goalRange.upperBound), forKey: key(metric, weekday: weekday))
        } else { defaults.removeObject(forKey: key(metric, weekday: weekday)) }
    }
    static func overrides(_ metric: HealthMetric, in defaults: UserDefaults = AppGroup.defaults) -> [Int: Double] {
        Dictionary(uniqueKeysWithValues: (1...7).compactMap { day in
            let value = defaults.double(forKey: key(metric, weekday: day))
            return value.isFinite && value > 0 ? (day, value) : nil
        })
    }
}

nonisolated struct HealthStreak: Sendable {
    var count: Int
    var isLimited: Bool
    static func calculate(_ days: [HealthHistoryDay], metric: HealthMetric, now: Date = .now,
                          calendar: Calendar = .current, defaults: UserDefaults = AppGroup.defaults) -> HealthStreak {
        let values = Dictionary(days.map { (calendar.startOfDay(for: $0.date), $0.value) }, uniquingKeysWith: { _, new in new })
        let today = calendar.startOfDay(for: now)
        func achieved(_ date: Date) -> Bool {
            guard let entry = values[date], let value = entry else { return false }
            return value >= HealthGoals.goal(metric, on: date, calendar: calendar, in: defaults)
        }
        var cursor = achieved(today) ? today : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var count = 0
        while achieved(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        let earliest = days.map { calendar.startOfDay(for: $0.date) }.min() ?? today
        return HealthStreak(count: count, isLimited: count > 0 && cursor < earliest)
    }
}
