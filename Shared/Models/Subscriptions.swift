import Foundation
import WidgetKit

nonisolated enum SubscriptionCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case monthly, yearly
    var id: Self { self }
    var title: String { self == .monthly ? "شهري" : "سنوي" }
}

nonisolated struct Subscription: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var name: String
    /// المبلغ لكل دورة بالريال السعودي.
    var amount: Double
    var cycle: SubscriptionCycle = .monthly
    var renewalDate: Date = .now
    var isActive = true

    var monthlyAmount: Double { cycle == .monthly ? amount : amount / 12 }

    /// كل دورة تبدأ من التاريخ الأصلي، حتى لا يتحول يوم ٣١ إلى ٢٨ بشكل دائم.
    func nextRenewal(from now: Date = .now, calendar: Calendar = Calendar(identifier: .gregorian)) -> Date {
        let anchor = calendar.startOfDay(for: renewalDate)
        let today = calendar.startOfDay(for: now)
        guard anchor < today else { return anchor }
        let component: Calendar.Component = cycle == .monthly ? .month : .year
        let elapsed = calendar.dateComponents([component], from: anchor, to: today).value(for: component) ?? 0
        for offset in max(0, elapsed)...max(0, elapsed) + 2 {
            if let candidate = calendar.date(byAdding: component, value: offset, to: anchor), candidate >= today {
                return candidate
            }
        }
        return today
    }
}

nonisolated enum SubscriptionStore {
    static func all(in defaults: UserDefaults = AppGroup.defaults) -> [Subscription] {
        guard let data = defaults.data(forKey: "subscriptions") else { return [] }
        return (try? JSONDecoder().decode([Subscription].self, from: data)) ?? []
    }

    @MainActor
    static func save(_ items: [Subscription], in defaults: UserDefaults = AppGroup.defaults) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: "subscriptions")
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.subscriptions.rawValue)
    }

    static func upcoming(from date: Date) -> [Subscription] {
        all().filter(\.isActive).sorted { $0.nextRenewal(from: date) < $1.nextRenewal(from: date) }
    }

    static func amountLabel(_ amount: Double) -> String {
        amount.formatted(.number.locale(Locale(identifier: "ar_SA")).precision(.fractionLength(0...2))) + " ر.س"
    }
}
