import AppIntents
import Foundation
import WidgetKit

nonisolated struct WaterEntry: Identifiable, Codable, Sendable {
    var id = UUID()
    var date: Date
    var milliliters: Int
}
nonisolated enum WaterTracker {
    static let entriesKey = "health.water.entries"
    static let goalKey = "health.water.goal"
    static let cupKey = "health.water.cup"
    static let revisionKey = "health.water.revision"
    static func goal(in defaults: UserDefaults = AppGroup.defaults) -> Int {
        let value = defaults.integer(forKey: goalKey)
        return (100...6000).contains(value) ? value : 2000
    }
    static func cup(in defaults: UserDefaults = AppGroup.defaults) -> Int {
        let value = defaults.integer(forKey: cupKey)
        return (50...1000).contains(value) ? value : 250
    }
    static func entries(in defaults: UserDefaults = AppGroup.defaults) -> [WaterEntry] {
        guard let data = defaults.data(forKey: entriesKey) else { return [] }
        return (try? JSONDecoder().decode([WaterEntry].self, from: data)) ?? []
    }
    static func today(on now: Date = .now, calendar: Calendar = .current, in defaults: UserDefaults = AppGroup.defaults) -> [WaterEntry] {
        entries(in: defaults).enumerated()
            .filter { calendar.isDate($0.element.date, inSameDayAs: now) }
            .sorted { $0.element.date == $1.element.date ? $0.offset > $1.offset : $0.element.date > $1.element.date }
            .map(\.element)
    }
    static func total(on now: Date = .now, calendar: Calendar = .current, in defaults: UserDefaults = AppGroup.defaults) -> Int {
        today(on: now, calendar: calendar, in: defaults).reduce(0) { $0 + $1.milliliters }
    }
    static func add(_ amount: Int? = nil, now: Date = .now, calendar: Calendar = .current,
                    in defaults: UserDefaults = AppGroup.defaults) {
        let value = amount ?? cup(in: defaults)
        guard (1...2000).contains(value) else { return }
        let cutoff = calendar.date(byAdding: .day, value: -90, to: now) ?? .distantPast
        var items = entries(in: defaults).filter { $0.date >= cutoff }
        items.append(WaterEntry(date: now, milliliters: value))
        save(items, in: defaults)
    }
    static func undo(now: Date = .now, calendar: Calendar = .current, in defaults: UserDefaults = AppGroup.defaults) {
        guard let last = today(on: now, calendar: calendar, in: defaults).first else { return }
        save(entries(in: defaults).filter { $0.id != last.id }, in: defaults)
    }
    static func remove(_ id: UUID, in defaults: UserDefaults = AppGroup.defaults) {
        save(entries(in: defaults).filter { $0.id != id }, in: defaults)
    }
    private static func save(_ items: [WaterEntry], in defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: entriesKey)
        defaults.set(defaults.integer(forKey: revisionKey) &+ 1, forKey: revisionKey)
    }
}

nonisolated struct AddWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "تسجيل كوب ماء"
    static let isDiscoverable = false
    @MainActor func perform() async throws -> some IntentResult {
        WaterTracker.add()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.healthWater.rawValue)
        return .result()
    }
}
nonisolated struct UndoWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "التراجع عن آخر كوب"
    static let isDiscoverable = false
    @MainActor func perform() async throws -> some IntentResult {
        WaterTracker.undo()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.healthWater.rawValue)
        return .result()
    }
}
