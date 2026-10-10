//
//  Health.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import Foundation
import HealthKit
import WidgetKit

// MARK: - المقاييس
nonisolated enum HealthMetric: String, CaseIterable, Identifiable, Codable, Sendable {
    case steps, distance, energy, exercise, flights, sleep

    var id: Self { self }

    var title: String {
        switch self {
        case .steps:    "الخطوات"
        case .distance: "المسافة"
        case .energy:   "السعرات"
        case .exercise: "التمرين"
        case .flights:  "الطوابق"
        case .sleep:    "النوم"
        }
    }

    var unit: String {
        switch self {
        case .steps:    "خطوة"
        case .distance: "كم"
        case .energy:   "سعرة"
        case .exercise: "دقيقة"
        case .flights:  "طابق"
        case .sleep:    "ساعة"
        }
    }

    var symbol: String {
        switch self {
        case .steps:    "figure.walk"
        case .distance: "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .energy:   "flame.fill"
        case .exercise: "figure.run"
        case .flights:  "figure.stairs"
        case .sleep:    "bed.double.fill"
        }
    }

    /// ألوان ثابتة على طريقة حلقات النشاط، تبقى مقروءة فوق أي خلفية
    var hex: UInt32 {
        switch self {
        case .steps:    0x34C759
        case .distance: 0x32ADE6
        case .energy:   0xFF375F
        case .exercise: 0xA4E52B
        case .flights:  0xFF9F0A
        case .sleep:    0x7D7AFF
        }
    }

    var defaultGoal: Double {
        switch self {
        case .steps:    10_000
        case .distance: 8
        case .energy:   500
        case .exercise: 30
        case .flights:  10
        case .sleep:    8
        }
    }

    /// خطوة تعديل الهدف في الإعدادات
    var goalStep: Double {
        switch self {
        case .steps:    500
        case .distance: 0.5
        case .energy:   50
        case .exercise: 5
        case .flights:  1
        case .sleep:    0.5
        }
    }

    var goalRange: ClosedRange<Double> {
        switch self {
        case .steps:    1_000...40_000
        case .distance: 1...42
        case .energy:   100...2_000
        case .exercise: 5...180
        case .flights:  1...100
        case .sleep:    4...12
        }
    }

    var goalKey: String { "health.goal.\(rawValue)" }

    var goal: Double {
        let value = AppGroup.defaults.double(forKey: goalKey)
        return value > 0 ? value : defaultGoal
    }

    /// القيمة كما تُعرض: ٦٬٢٣٤ أو ٤٫٨ أو ٧:٣٠
    func format(_ value: Double) -> String {
        switch self {
        case .distance:
            HealthFormat.decimal(value, digits: value < 10 ? 1 : 0)
        case .sleep:
            HealthFormat.duration(hours: value)
        default:
            HealthFormat.decimal(value, digits: 0)
        }
    }

    // MARK: HealthKit
    var quantityType: HKQuantityType? {
        switch self {
        case .steps:    HKQuantityType(.stepCount)
        case .distance: HKQuantityType(.distanceWalkingRunning)
        case .energy:   HKQuantityType(.activeEnergyBurned)
        case .exercise: HKQuantityType(.appleExerciseTime)
        case .flights:  HKQuantityType(.flightsClimbed)
        case .sleep:    nil
        }
    }

    var hkUnit: HKUnit {
        switch self {
        case .steps, .flights: .count()
        case .distance:        .meterUnit(with: .kilo)
        case .energy:          .kilocalorie()
        case .exercise:        .minute()
        case .sleep:           .hour()
        }
    }

    static var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = Set(allCases.compactMap(\.quantityType))
        types.insert(HKCategoryType(.sleepAnalysis))
        return types
    }
}

// MARK: - لقطة اليوم
/// آخر قيم قُرئت من تطبيق الصحة. تُحفظ في المساحة المشتركة لأن الصحة مقفلة والجهاز مقفل،
/// فيعرض الـ Widget آخر ما عرفه بدل أن يفرغ.
nonisolated struct HealthSnapshot: Codable, Sendable, Equatable {
    var date: Date
    var values: [HealthMetric: Double]
    /// خطوات آخر ٧ أيام، الأقدم أولاً، واليوم آخرها
    var weekSteps: [Double]

    func value(_ metric: HealthMetric) -> Double { values[metric] ?? 0 }

    func progress(_ metric: HealthMetric) -> Double {
        min(value(metric) / metric.goal, 1)
    }

    /// القيم تخص يوماً مضى: نصفّر مقاييس اليوم ونُبقي النوم وأسبوع الخطوات مُزاحاً
    func rolled(to now: Date, calendar: Calendar = .current) -> HealthSnapshot {
        guard !calendar.isDate(date, inSameDayAs: now) else { return self }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 7
        var week = weekSteps
        week.append(contentsOf: Array(repeating: 0, count: min(max(days, 0), 7)))
        return HealthSnapshot(date: now, values: [:], weekSteps: Array(week.suffix(7)))
    }

    /// مثال للمعرض قبل ربط الصحة
    static let sample = HealthSnapshot(
        date: .now,
        values: [.steps: 7_482, .distance: 5.6, .energy: 386, .exercise: 24, .flights: 7, .sleep: 7.25],
        weekSteps: [8_210, 11_430, 6_020, 9_870, 12_340, 5_410, 7_482])
}

// MARK: - الحفظ المشترك
nonisolated enum HealthCache {
    private static let key = "health.snapshot"
    static let connectedKey = "health.connected"

    static func load(now: Date = .now) -> HealthSnapshot? {
        guard let data = AppGroup.defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(HealthSnapshot.self, from: data) else { return nil }
        return snapshot.rolled(to: now)
    }

    static func save(_ snapshot: HealthSnapshot) {
        AppGroup.defaults.set(try? JSONEncoder().encode(snapshot), forKey: key)
    }

    /// طلب المستخدم ربط الصحة من التطبيق (الصحة لا تخبرنا هل وافق على القراءة، لخصوصيته)
    static var isConnected: Bool { AppGroup.defaults.bool(forKey: connectedKey) }
}

// MARK: - القراءة من تطبيق الصحة
nonisolated enum HealthReader {
    static let store = HKHealthStore()

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// من التطبيق فقط؛ الـ Widget لا يستطيع إظهار نافذة الإذن
    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: HealthMetric.readTypes)
            AppGroup.defaults.set(true, forKey: HealthCache.connectedKey)
            return true
        } catch {
            return false
        }
    }

    /// يقرأ اليوم والأسبوع ويحفظهما. إذا كانت الصحة مقفلة (الجهاز مقفل) نرجع المحفوظ.
    @discardableResult
    static func refresh(now: Date = .now) async -> HealthSnapshot? {
        guard isAvailable, HealthCache.isConnected else { return HealthCache.load(now: now) }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        do {
            var values: [HealthMetric: Double] = [:]
            for metric in HealthMetric.allCases {
                if let type = metric.quantityType {
                    values[metric] = try await sum(type, unit: metric.hkUnit, from: start, to: now)
                }
            }
            values[.sleep] = try await sleepHours(endingAt: now, calendar: calendar)
            let week = try await weekSteps(endingAt: now, calendar: calendar)
            let snapshot = HealthSnapshot(date: now, values: values, weekSteps: week)
            HealthCache.save(snapshot)
            return snapshot
        } catch {
            return HealthCache.load(now: now)
        }
    }

    private static func sum(_ type: HKQuantityType, unit: HKUnit, from start: Date, to end: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsQueryDescriptor(predicate: .quantitySample(type: type, predicate: predicate),
                                                     options: .cumulativeSum)
        return try await descriptor.result(for: store)?.sumQuantity()?.doubleValue(for: unit) ?? 0
    }

    private static func weekSteps(endingAt now: Date, calendar: Calendar) async throws -> [Double] {
        let end = calendar.startOfDay(for: now).addingTimeInterval(86_400)
        guard let start = calendar.date(byAdding: .day, value: -7, to: end) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: HKQuantityType(.stepCount), predicate: predicate),
            options: .cumulativeSum, anchorDate: start, intervalComponents: DateComponents(day: 1))
        let collection = try await descriptor.result(for: store)
        var days: [Double] = []
        collection.enumerateStatistics(from: start, to: end.addingTimeInterval(-1)) { statistics, _ in
            days.append(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        }
        return Array(days.suffix(7))
    }

    /// نوم الليلة الماضية: من السادسة مساء أمس حتى الآن، مراحل النوم فقط (بدون «في السرير»)
    private static func sleepHours(endingAt now: Date, calendar: Calendar) async throws -> Double {
        let today = calendar.startOfDay(for: now)
        guard let start = calendar.date(byAdding: .hour, value: -6, to: today) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        let descriptor = HKSampleQueryDescriptor(predicates: [.categorySample(type: HKCategoryType(.sleepAnalysis),
                                                                                predicate: predicate)],
                                                 sortDescriptors: [SortDescriptor(\.startDate)])
        let asleep = HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue)
        let intervals = try await descriptor.result(for: store)
            .filter { asleep.contains($0.value) }
            .map { DateInterval(start: max($0.startDate, start), end: min($0.endDate, now)) }
        // الساعة والجوال قد يسجّلان نفس الفترة، فندمج المتداخل قبل الجمع
        var merged: [DateInterval] = []
        for interval in intervals.sorted(by: { $0.start < $1.start }) {
            if let last = merged.last, interval.start <= last.end {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        return merged.reduce(0) { $0 + $1.duration } / 3_600
    }
}

// MARK: - تحديث الودجات
nonisolated enum HealthWidgets {
    @MainActor
    static func reload() {
        for kind in WidgetKind.allCases where kind.category == .health {
            WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        }
    }

    /// يطلب من الصحة إيقاظ التطبيق عند خطوات جديدة (ساعة على الأكثر)، فتتحدث الودجات بدون فتحه
    static func startBackgroundUpdates() {
        guard HealthReader.isAvailable, HealthCache.isConnected else { return }
        for metric in [HealthMetric.steps, .energy] {
            guard let type = metric.quantityType else { continue }
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
                guard error == nil else { completion(); return }
                Task {
                    await HealthReader.refresh()
                    await MainActor.run { reload() }
                    completion()
                }
            }
            HealthReader.store.execute(query)
            HealthReader.store.enableBackgroundDelivery(for: type, frequency: .hourly) { _, _ in }
        }
    }
}

// MARK: - تنسيق
nonisolated enum HealthFormat {
    static func decimal(_ value: Double, digits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar@numbers=arab")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = digits
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// ٧:٣٠
    static func duration(hours: Double) -> String {
        let minutes = Int((hours * 60).rounded())
        return "\(DateHelper.arabic(minutes / 60)):\(DateHelper.arabicTwoDigits(minutes % 60))"
    }

    /// أسماء الأيام المختصرة للرسم الأسبوعي: آخر ٧ أيام تنتهي باليوم
    static func weekdayInitials(endingAt now: Date, calendar: Calendar = .current) -> [String] {
        let names = ["ح", "ن", "ث", "ر", "خ", "ج", "س"]
        return (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: now).map { names[calendar.component(.weekday, from: $0) - 1] }
        }
    }
}
