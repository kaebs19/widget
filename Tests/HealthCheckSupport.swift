import Foundation

nonisolated enum AppGroup {
    static let defaults = UserDefaults(suiteName: "com.widgetar.health-checks")!
}
nonisolated enum DateHelper {
    static func arabic(_ value: Int) -> String { String(value) }
    static func arabicTwoDigits(_ value: Int) -> String { String(format: "%02d", value) }
}
nonisolated enum WidgetCategory { case health }
nonisolated enum WidgetKind: String, CaseIterable {
    case healthSteps, healthActivity, healthDashboard, healthSleep, healthWater
    var category: WidgetCategory { .health }
}
