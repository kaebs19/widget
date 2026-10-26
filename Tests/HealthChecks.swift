import Foundation

@main
struct HealthChecks {
    static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh")!
        func date(_ day: Int, _ hour: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
        }
        let snapshot = HealthSnapshot(date: date(17, 20), values: [.steps: 0, .distance: 2.5],
                                      weekSteps: [10, 20, 30, 40, 50, 60, 0],
                                      weekStepReadings: [10, 20, nil, 40, 50, 60, 0])
        precondition(snapshot.hasData(.steps) && snapshot.displayValue(.steps) != "—", "Recorded zero stays zero")
        precondition(!snapshot.hasData(.sleep) && snapshot.displayValue(.sleep) == "—", "Missing data must not become zero")
        let rolled = snapshot.rolled(to: date(18, 2), calendar: calendar)
        precondition(rolled.date == snapshot.date, "Rollover preserves actual fetch time")
        precondition(rolled.values.isEmpty && rolled.stepReadings.last! == nil)
        precondition(rolled.stepReadings.count == 7 && rolled.stepReadings[0] == 20)
        let sameDay = rolled.rolled(to: date(18, 18), calendar: calendar)
        precondition(sameDay.stepReadings == rolled.stepReadings, "Do not roll twice in one day")
        let later = sameDay.rolled(to: date(25), calendar: calendar)
        precondition(later.stepReadings.count == 7 && later.stepReadings.allSatisfy { $0 == nil })
        precondition(later.date == snapshot.date)
        let encoded = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(HealthSnapshot.self, from: encoded)
        precondition(decoded == snapshot)
        var legacy = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        for key in ["dayDate", "weekStepReadings", "failedMetrics", "schemaVersion"] { legacy.removeValue(forKey: key) }
        let old = try JSONDecoder().decode(HealthSnapshot.self, from: JSONSerialization.data(withJSONObject: legacy))
        precondition(old.stepReadings == snapshot.weekSteps.map { $0 == 0 ? nil : $0 }, "Legacy cache remains readable")
        precondition(!old.hasData(.steps) && old.hasData(.distance), "Legacy synthetic zeros are unknown")
        var failed = snapshot
        failed.failedMetrics = [.sleep]
        precondition(failed.missingLabel(.sleep) == "تعذر التحديث")

        let window = HealthSleepWindow.interval(for: date(18), endingAt: date(18, 12), calendar: calendar)
        precondition(window.start == date(17, 18) && window.end == date(18, 12))
        let intervals = [DateInterval(start: date(17, 22), end: date(18, 4)),
                         DateInterval(start: date(18, 2), end: date(18, 6)),
                         DateInterval(start: date(18, 7), end: date(18, 8))]
        precondition(HealthSleepWindow.hours(in: intervals, window: window) == 9, "Merge overlapping sleep sources")
        precondition(HealthSleepWindow.hours(in: [], window: window) == nil)
        let clipped = [DateInterval(start: date(17, 16), end: date(17, 20)), DateInterval(start: date(18, 11), end: date(18, 14))]
        precondition(HealthSleepWindow.hours(in: clipped, window: window) == 3, "Clip samples at both window boundaries")
        let evening = HealthSleepWindow.interval(for: date(18), endingAt: date(18, 23), calendar: calendar)
        precondition(evening.end == date(18, 18), "No overlap between adjacent night windows")
        var dst = Calendar(identifier: .gregorian)
        dst.timeZone = TimeZone(identifier: "America/New_York")!
        let dstDay = dst.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 20))!
        let dstWindow = HealthSleepWindow.interval(for: dstDay, endingAt: dstDay, calendar: dst)
        precondition(dst.component(.hour, from: dstWindow.start) == 18 && dst.component(.hour, from: dstWindow.end) == 18)
        precondition(dstWindow.duration == 23 * 3600, "Use calendar days across DST")

        let suite = "com.widgetar.health-checks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        precondition(HealthDisplaySettings.metrics(in: defaults) == HealthMetric.allCases)
        HealthDisplaySettings.saveMetrics([.sleep, .steps], in: defaults)
        precondition(HealthDisplaySettings.metrics(in: defaults) == [.sleep, .steps])
        HealthDisplaySettings.saveMetrics([], in: defaults)
        precondition(HealthDisplaySettings.metrics(in: defaults) == [.sleep, .steps], "Keep at least one metric")
        defaults.set(["bad", "steps", "steps", "sleep"], forKey: HealthDisplaySettings.metricsKey)
        precondition(HealthDisplaySettings.metrics(in: defaults) == [.steps, .sleep])
        defaults.set(["bad"], forKey: HealthDisplaySettings.metricsKey)
        precondition(HealthDisplaySettings.metrics(in: defaults) == HealthMetric.allCases)
        defaults.set(0, forKey: HealthDisplaySettings.colorKey(.steps))
        precondition(HealthDisplaySettings.colorHex(for: .steps, in: defaults) == 0, "Black is a valid custom color")
        defaults.removeObject(forKey: HealthDisplaySettings.colorKey(.steps))
        precondition(HealthDisplaySettings.colorHex(for: .steps, in: defaults) == HealthMetric.steps.hex)
        precondition(HealthRoute(url: URL(string: "widgetar://health/sleep")!)?.metric == .sleep)
        precondition(HealthRoute(url: URL(string: "https://health/sleep")!) == nil)
        HealthGoals.set(20000, metric: .steps, weekday: calendar.component(.weekday, from: date(17)), in: defaults)
        precondition(HealthGoals.goal(.steps, on: date(17), calendar: calendar, in: defaults) == 20000)
        precondition(HealthGoals.goal(.steps, on: date(18), calendar: calendar, in: defaults) == 10000)
        HealthGoals.set(nil, metric: .steps, weekday: calendar.component(.weekday, from: date(17)), in: defaults)
        precondition(HealthGoals.goal(.steps, on: date(17), calendar: calendar, in: defaults) == 10000)
        let streakDays = (14...17).map { HealthHistoryDay(date: date($0), value: $0 == 17 ? 2000 : 12000) }
        precondition(HealthStreak.calculate(streakDays, metric: .steps, now: date(17, 12), calendar: calendar, defaults: defaults).count == 3, "Today in progress keeps yesterday's streak")
        var withGap = streakDays
        withGap[1] = HealthHistoryDay(date: date(15), value: nil)
        precondition(HealthStreak.calculate(withGap, metric: .steps, now: date(17, 12), calendar: calendar, defaults: defaults).count == 1, "Missing days stop confirmed streak")
        let achievedDays = streakDays.map { HealthHistoryDay(date: $0.date, value: 12000) }
        let bounded = HealthStreak.calculate(achievedDays, metric: .steps, now: date(17, 12), calendar: calendar, defaults: defaults)
        precondition(bounded.count == 4 && bounded.isLimited)
        precondition(HealthInsights.average(withGap) == (12000 + 12000 + 2000) / 3.0)
        precondition(HealthInsights.total([HealthHistoryDay(date: date(17), value: nil)]) == nil)
        let insights = HealthInsights(date: date(17), histories: [.steps: achievedDays], workouts: nil)
        let shifted = insights.days(.steps, count: 7, endingAt: date(18), calendar: calendar)
        precondition(shifted.count == 7 && shifted.last?.value == nil && shifted[5].value == 12000)
        let insightsRoundTrip = try JSONDecoder().decode(HealthInsights.self, from: JSONEncoder().encode(insights))
        precondition(insightsRoundTrip.histories[.steps] == achievedDays)
        WaterTracker.add(250, now: date(17, 10), calendar: calendar, in: defaults)
        WaterTracker.add(500, now: date(17, 11), calendar: calendar, in: defaults)
        precondition(WaterTracker.total(on: date(17), calendar: calendar, in: defaults) == 750, "Day totals include all recorded cups")
        WaterTracker.undo(now: date(17, 12), calendar: calendar, in: defaults)
        precondition(WaterTracker.total(on: date(17), calendar: calendar, in: defaults) == 250)
        WaterTracker.add(-200, now: date(17), calendar: calendar, in: defaults)
        precondition(WaterTracker.total(on: date(17), calendar: calendar, in: defaults) == 250)
        precondition(WaterTracker.total(on: date(18), calendar: calendar, in: defaults) == 0)
        WaterTracker.undo(now: date(18), calendar: calendar, in: defaults)
        precondition(WaterTracker.total(on: date(17), calendar: calendar, in: defaults) == 250, "Undo cannot remove yesterday's cup")
        WaterTracker.add(300, now: date(17, 10), calendar: calendar, in: defaults)
        WaterTracker.undo(now: date(17), calendar: calendar, in: defaults)
        precondition(WaterTracker.total(on: date(17), calendar: calendar, in: defaults) == 250, "Undo tied timestamps removes newest entry")
        precondition(HealthRoute(url: URL(string: "widgetar://health/water")!)?.page == "water")
        print("Passed: weekly goals, confirmed streaks, insights windows, water add/undo/rollover; missing vs zero, stale timestamps, rollover, cache migration, sleep merging/DST, display settings, routes.")
    }
}
