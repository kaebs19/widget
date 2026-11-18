import Foundation
import HealthKit

nonisolated struct HealthWorkout: Identifiable, Codable, Sendable {
    var id: UUID
    var date: Date
    var minutes: Double
    var activity: UInt
    var energy: Double?
    var title: String { L10n.text(titleKey) }

    private var titleKey: String {
        switch HKWorkoutActivityType(rawValue: activity) {
        case .walking: "مشي"
        case .running: "جري"
        case .cycling: "دراجة"
        case .swimming: "سباحة"
        case .traditionalStrengthTraining, .functionalStrengthTraining: "تمارين قوة"
        case .highIntensityIntervalTraining: "تمارين متقطعة"
        case .yoga: "يوغا"
        case .pilates: "بيلاتس"
        case .hiking: "مشي جبلي"
        case .elliptical: "جهاز بيضاوي"
        default: "تمرين"
        }
    }
}
nonisolated struct HealthInsights: Codable, Sendable {
    var date: Date
    var histories: [HealthMetric: [HealthHistoryDay]]
    var workouts: [HealthWorkout]?
    func days(_ metric: HealthMetric, count: Int = 7, endingAt now: Date = .now, calendar: Calendar = .current) -> [HealthHistoryDay] {
        let lookup = Dictionary((histories[metric] ?? []).map { (calendar.startOfDay(for: $0.date), $0.value) }, uniquingKeysWith: { _, new in new })
        let today = calendar.startOfDay(for: now)
        return (0..<max(1, min(count, 31))).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return HealthHistoryDay(date: day, value: lookup[day] ?? nil)
        }
    }
    func weekWorkouts(endingAt now: Date = .now, calendar: Calendar = .current) -> [HealthWorkout] {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        return (workouts ?? []).filter { $0.date >= start && $0.date <= now }.sorted { $0.date > $1.date }
    }
    static func average(_ days: [HealthHistoryDay]) -> Double? {
        let values = days.compactMap(\.value)
        return values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
    }
    static func total(_ days: [HealthHistoryDay]) -> Double? {
        let values = days.compactMap(\.value)
        return values.isEmpty ? nil : values.reduce(0, +)
    }
    static func achieved(_ days: [HealthHistoryDay], metric: HealthMetric, defaults: UserDefaults = AppGroup.defaults) -> Int {
        days.filter { day in
            day.value.map { $0 >= HealthGoals.goal(metric, on: day.date, in: defaults) } ?? false
        }.count
    }
}
nonisolated enum HealthInsightsCache {
    static func load(in defaults: UserDefaults = AppGroup.defaults) -> HealthInsights? {
        defaults.data(forKey: "health.insights").flatMap { try? JSONDecoder().decode(HealthInsights.self, from: $0) }
    }
    static func save(_ insights: HealthInsights, in defaults: UserDefaults = AppGroup.defaults) {
        guard let data = try? JSONEncoder().encode(insights) else { return }
        defaults.set(data, forKey: "health.insights")
    }
}

/// يجمع القراءات الإضافية مرة واحدة حتى لو طلبتها عدة ودجات معاً.
actor HealthInsightsReader {
    static let shared = HealthInsightsReader()
    private var pending: Task<HealthInsights?, Never>?
    func refresh(now: Date = .now, force: Bool = false) async -> HealthInsights? {
        guard HealthReader.isAvailable, HealthCache.isConnected else { return HealthInsightsCache.load() }
        if let pending { return await pending.value }
        if !force, let cached = HealthInsightsCache.load(), now.timeIntervalSince(cached.date) >= 0,
           now.timeIntervalSince(cached.date) < 600, Calendar.current.isDate(now, inSameDayAs: cached.date) { return cached }
        let task = Task { await Self.read(now: now) }
        pending = task
        let result = await task.value
        pending = nil
        return result
    }
    private static func read(now: Date) async -> HealthInsights? {
        async let steps = try? HealthReader.history(for: .steps, days: 31, endingAt: now)
        async let exercise = try? HealthReader.history(for: .exercise, days: 31, endingAt: now)
        async let sleep = try? HealthReader.history(for: .sleep, days: 31, endingAt: now)
        async let workouts = try? readWorkouts(now: now)
        let result = await (steps, exercise, sleep, workouts)
        var histories: [HealthMetric: [HealthHistoryDay]] = [:]
        histories[.steps] = result.0
        histories[.exercise] = result.1
        histories[.sleep] = result.2
        guard !histories.isEmpty || result.3 != nil else { return HealthInsightsCache.load() }
        let insights = HealthInsights(date: now, histories: histories, workouts: result.3)
        HealthInsightsCache.save(insights)
        return insights
    }
    private static func readWorkouts(now: Date) async throws -> [HealthWorkout] {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: now)) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        let descriptor = HKSampleQueryDescriptor(predicates: [.workout(predicate)], sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)])
        return try await descriptor.result(for: HealthReader.store).filter { $0.endDate <= now }.map { workout in
            HealthWorkout(id: workout.uuid, date: workout.startDate, minutes: workout.duration / 60,
                          activity: workout.workoutActivityType.rawValue,
                          energy: workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()))
        }
    }
}

extension HealthInsights {
    nonisolated static func sample(at date: Date) -> HealthInsights {
        let calendar = Calendar.current
        var histories: [HealthMetric: [HealthHistoryDay]] = [:]
        for metric in [HealthMetric.steps, .exercise, .sleep] {
            histories[metric] = (0..<31).compactMap { index in
                guard let day = calendar.date(byAdding: .day, value: index - 30, to: calendar.startOfDay(for: date)) else { return nil }
                let value: Double = metric == .steps ? Double(6500 + index % 5 * 1200)
                    : metric == .exercise ? Double(20 + index % 3 * 10) : 6.5 + Double(index % 4) * 0.5
                return HealthHistoryDay(date: day, value: value)
            }
        }
        return HealthInsights(date: date, histories: histories, workouts: [
            HealthWorkout(id: UUID(), date: date.addingTimeInterval(-86400), minutes: 32, activity: HKWorkoutActivityType.running.rawValue, energy: 210)
        ])
    }
}
