//
//  Budget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import AppIntents
import Foundation
import WidgetKit

// MARK: - ميزانية حتى الراتب
// المستخدم يُدخل رصيده، فنقسم المتاح على الأيام الباقية حتى موعد الصرف.
// المصروف اليومي يُحسب من رصيد بداية اليوم، فما يصرفه خلال اليوم ينقص «باقي اليوم» دون أن يغيّر حصة اليوم.
nonisolated enum Budget {
    enum Key {
        static let balance = "budget.balance"
        static let updated = "budget.updated"
        static let day = "budget.day"
        static let dayStart = "budget.dayStart"
        static let spentToday = "budget.spentToday"
        static let payday = "budget.payday"
        static let subtractsObligations = "budget.subtractsObligations"
        static let smallStep = "budget.step.small"
        static let largeStep = "budget.step.large"
        static let lastSpend = "budget.lastSpend"
    }

    private static var defaults: UserDefaults { AppGroup.defaults }
    private static var calendar: Calendar { DateHelper.gregorian }

    static var isSet: Bool { defaults.object(forKey: Key.balance) != nil }
    static var balance: Int { defaults.integer(forKey: Key.balance) }
    static var updated: Date? { defaults.object(forKey: Key.updated) as? Date }
    /// الدفعة التي ننتظرها (الراتب افتراضياً)
    static var payday: Payday { defaults.string(forKey: Key.payday).flatMap(Payday.init) ?? .salary }
    static var subtractsObligations: Bool { defaults.object(forKey: Key.subtractsObligations) as? Bool ?? true }
    /// مبلغا زرّي «صرفت» في الودجت
    static var smallStep: Int { defaults.object(forKey: Key.smallStep) as? Int ?? 20 }
    static var largeStep: Int { defaults.object(forKey: Key.largeStep) as? Int ?? 100 }

    private static func dayKey(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    /// رصيد بداية اليوم ومصروفه؛ في يوم جديد يبدأ من الرصيد الحالي بلا مصروف
    private static func today(_ now: Date) -> (start: Int, spent: Int) {
        guard defaults.string(forKey: Key.day) == dayKey(now) else { return (balance, 0) }
        return (defaults.integer(forKey: Key.dayStart), defaults.integer(forKey: Key.spentToday))
    }

    static func setBalance(_ value: Int, now: Date = .now) {
        defaults.set(value, forKey: Key.balance)
        defaults.set(now, forKey: Key.updated)
        defaults.set(dayKey(now), forKey: Key.day)
        defaults.set(value, forKey: Key.dayStart)
        defaults.set(0, forKey: Key.spentToday)
    }

    /// يخصم مصروفاً من الرصيد (سالب = تراجع)
    static func spend(_ amount: Int, now: Date = .now) {
        guard isSet else { return }
        let current = today(now)
        defaults.set(dayKey(now), forKey: Key.day)
        defaults.set(current.start, forKey: Key.dayStart)
        defaults.set(max(current.spent + amount, 0), forKey: Key.spentToday)
        defaults.set(balance - amount, forKey: Key.balance)
        defaults.set(amount, forKey: Key.lastSpend)
    }

    /// آخر مصروف سُجّل (للتراجع عنه من التطبيق)
    static var lastSpend: Int { defaults.integer(forKey: Key.lastSpend) }

    static func undoLastSpend(now: Date = .now) {
        let amount = lastSpend
        guard amount > 0 else { return }
        spend(-amount, now: now)
        defaults.removeObject(forKey: Key.lastSpend)
    }

    static func clear() {
        for key in [Key.balance, Key.updated, Key.day, Key.dayStart, Key.spentToday, Key.lastSpend] {
            defaults.removeObject(forKey: key)
        }
    }

    static func status(at date: Date = .now) -> BudgetStatus? {
        guard isSet else { return nil }
        let cycle = payday.cycle(from: date)
        let current = today(date)
        let todayStart = calendar.startOfDay(for: date)
        let obligations = subtractsObligations ? ObligationStore.total(from: todayStart, to: cycle.next) : 0
        // يوم الصرف نفسه يُحسب يوماً واحداً
        let days = max(cycle.days, 1)
        let daily = max(current.start - obligations, 0) / days
        // نزل الراتب بعد آخر تحديث للرصيد: نطلب تحديثه
        let lastPay = cycle.isToday ? cycle.next : cycle.previous
        let needsUpdate = (updated ?? .distantPast) < lastPay && lastPay <= todayStart
        return BudgetStatus(balance: balance, payday: payday, days: cycle.days, payDate: cycle.next,
                            obligations: obligations, daily: daily, spentToday: current.spent, needsUpdate: needsUpdate)
    }

    @MainActor
    static func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.budget.rawValue)
    }
}

nonisolated struct BudgetStatus: Sendable {
    let balance: Int
    let payday: Payday
    /// الأيام حتى موعد الصرف (صفر = اليوم)
    let days: Int
    let payDate: Date
    /// التزامات تُستحق قبل الصرف
    let obligations: Int
    /// المتاح لكل يوم
    let daily: Int
    let spentToday: Int
    let needsUpdate: Bool

    var leftToday: Int { daily - spentToday }
    var isOver: Bool { leftToday < 0 }
    /// كم صُرف من حصة اليوم (٠–١)
    var progress: Double { daily > 0 ? min(Double(spentToday) / Double(daily), 1) : 1 }
}

// MARK: - زر «صرفت» في الودجت
nonisolated struct SpendIntent: AppIntent {
    static let title: LocalizedStringResource = "تسجيل مصروف"
    static let isDiscoverable = false

    @Parameter(title: "المبلغ", default: 20)
    var amount: Int

    init() {}

    init(amount: Int) {
        self.amount = amount
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        Budget.spend(amount)
        Budget.reload()
        return .result()
    }
}
