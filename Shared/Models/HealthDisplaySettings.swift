import Foundation

nonisolated enum HealthDisplaySettings {
    static let metricsKey = "health.dashboard.metrics"
    static let goalsKey = "health.display.goals"
    static let percentageKey = "health.display.percentage"

    static func metrics(in defaults: UserDefaults = AppGroup.defaults) -> [HealthMetric] {
        let saved = defaults.stringArray(forKey: metricsKey)?.compactMap(HealthMetric.init(rawValue:)) ?? HealthMetric.allCases
        var unique: [HealthMetric] = []
        for metric in saved where !unique.contains(metric) { unique.append(metric) }
        return unique.isEmpty ? HealthMetric.allCases : unique
    }
    static func saveMetrics(_ metrics: [HealthMetric], in defaults: UserDefaults = AppGroup.defaults) {
        guard !metrics.isEmpty else { return }
        defaults.set(metrics.map(\.rawValue), forKey: metricsKey)
    }
    static func colorKey(_ metric: HealthMetric) -> String { "health.color." + metric.rawValue }
    static func colorHex(for metric: HealthMetric, in defaults: UserDefaults = AppGroup.defaults) -> UInt32 {
        guard defaults.object(forKey: colorKey(metric)) != nil else { return metric.hex }
        return UInt32(clamping: defaults.integer(forKey: colorKey(metric))) & 0xFFFFFF
    }
    static var showsGoals: Bool { AppGroup.defaults.object(forKey: goalsKey) as? Bool ?? true }
    static var showsPercentage: Bool { AppGroup.defaults.bool(forKey: percentageKey) }
}

nonisolated struct HealthHistoryDay: Identifiable, Codable, Equatable, Sendable {
    let date: Date
    let value: Double?
    var id: Date { date }
}
nonisolated enum HealthReadError: Error { case unavailable }

/// نافذة نوم كل يوم: من السادسة مساء اليوم السابق إلى السادسة مساء اليوم المحدد، أو الآن.
nonisolated enum HealthSleepWindow {
    static func interval(for day: Date, endingAt now: Date, calendar: Calendar = .current) -> DateInterval {
        let midnight = calendar.startOfDay(for: day)
        let previous = calendar.date(byAdding: .day, value: -1, to: midnight) ?? midnight
        let start = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: previous) ?? previous
        let end = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: midnight) ?? midnight
        return DateInterval(start: start, end: max(start, min(end, now)))
    }
    static func hours(in intervals: [DateInterval], window: DateInterval) -> Double? {
        let clipped = intervals.compactMap { interval -> DateInterval? in
            let start = max(interval.start, window.start)
            let end = min(interval.end, window.end)
            return end > start ? DateInterval(start: start, end: end) : nil
        }.sorted { $0.start < $1.start }
        guard !clipped.isEmpty else { return nil }
        var merged: [DateInterval] = []
        for interval in clipped {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else { merged.append(interval) }
        }
        return merged.reduce(0) { $0 + $1.duration } / 3600
    }
}

nonisolated struct HealthRoute: Identifiable {
    let metric: HealthMetric?
    var page: String? = nil
    var id: String { metric?.rawValue ?? page ?? "overview" }
    init?(url: URL) {
        guard url.scheme == "widgetar", url.host == "health" else { return nil }
        let name = url.lastPathComponent
        if ["water", "weekly", "streak", "workouts"].contains(name) { metric = nil; page = name }
        else if name == "overview" { metric = nil }
        else if let value = HealthMetric(rawValue: name) { metric = value }
        else { return nil }
    }
}
