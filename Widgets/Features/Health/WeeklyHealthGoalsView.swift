import SwiftUI

struct WeeklyHealthGoalsView: View {
    @State private var metric: HealthMetric = .steps
    @State private var overrides = HealthGoals.overrides(.steps)
    private let names = ["الأحد", "الاثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]
    var body: some View {
        Form {
            Picker("المؤشر", selection: $metric) {
                ForEach(HealthMetric.allCases) { item in Text(item.title).tag(item) }
            }
            Section {
                ForEach(1...7, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L10n.text(names[day - 1]), isOn: Binding(get: { overrides[day] != nil }, set: { enabled in
                            set(enabled ? metric.baseGoal : nil, day: day)
                        }))
                        if let value = overrides[day] {
                            Stepper("\(metric.format(value)) \(metric.unit)", value: Binding(get: { value }, set: { set($0, day: day) }),
                                    in: metric.goalRange, step: metric.goalStep)
                        } else {
                            Text("الهدف الأساسي: \(metric.format(metric.baseGoal)) \(metric.unit)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: { Text("هدف مختلف لكل يوم") } footer: {
                Text("عند إيقاف تخصيص يوم يُستخدم الهدف الأساسي من إعدادات الصحة. تُحسب الاستمرارية وتقويم الإنجاز وفق جدول الأهداف الحالي، بما فيه الأيام السابقة المعروضة.")
            }
        }
        .navigationTitle("أهداف أيام الأسبوع")
        .onChange(of: metric) { overrides = HealthGoals.overrides(metric) }
    }
    private func set(_ value: Double?, day: Int) {
        HealthGoals.set(value, metric: metric, weekday: day)
        overrides = HealthGoals.overrides(metric)
        HealthWidgets.reload()
    }
}
