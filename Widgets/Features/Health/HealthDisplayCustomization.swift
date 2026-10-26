import SwiftUI

struct HealthDisplayCustomization: View {
    var onChange: () -> Void = {}
    @State private var metrics = HealthDisplaySettings.metrics()
    @State private var colors = Dictionary(uniqueKeysWithValues: HealthMetric.allCases.map { ($0, $0.color) })
    @AppStorage(HealthDisplaySettings.goalsKey, store: AppGroup.defaults) private var showsGoals = true
    @AppStorage(HealthDisplaySettings.percentageKey, store: AppGroup.defaults) private var showsPercentage = false
    @Environment(\.self) private var environment

    var body: some View {
        VStack(spacing: 20) {
            SettingsSection("مؤشرات صحتي اليوم") {
                Text("اختر مؤشرًا واحدًا على الأقل، ورتّب المؤشرات بالأسهم. الترتيب نفسه يظهر في الودجت.")
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                ForEach(metrics + HealthMetric.allCases.filter { !metrics.contains($0) }) { metric in
                    HStack(spacing: 4) {
                        Toggle(isOn: Binding(get: { metrics.contains(metric) }, set: { enabled in
                            if enabled { metrics.append(metric) }
                            else if metrics.count > 1 { metrics.removeAll { $0 == metric } }
                            HealthDisplaySettings.saveMetrics(metrics)
                            changed()
                        })) {
                            Label(metric.title, systemImage: metric.symbol)
                                .font(AppFont.ui(14))
                        }
                        .disabled(metrics.count == 1 && metrics.contains(metric))
                        if let index = metrics.firstIndex(of: metric) {
                            Button { move(index, by: -1) } label: { Image(systemName: "arrow.up") }
                                .disabled(index == 0)
                                .frame(minWidth: 36, minHeight: 44)
                                .accessibilityLabel("تقديم \(metric.title)")
                            Button { move(index, by: 1) } label: { Image(systemName: "arrow.down") }
                                .disabled(index == metrics.count - 1)
                                .frame(minWidth: 36, minHeight: 44)
                                .accessibilityLabel("تأخير \(metric.title)")
                        }
                    }
                }
            }
            SettingsSection("ألوان وعرض الصحة") {
                ForEach(HealthMetric.allCases) { metric in
                    ColorPicker(selection: Binding(get: { colors[metric] ?? metric.color }, set: { color in
                        colors[metric] = color
                        let resolved = color.resolve(in: environment)
                        let red = UInt32((min(max(resolved.red, 0), 1) * 255).rounded())
                        let green = UInt32((min(max(resolved.green, 0), 1) * 255).rounded())
                        let blue = UInt32((min(max(resolved.blue, 0), 1) * 255).rounded())
                        AppGroup.defaults.set(Int((red << 16) | (green << 8) | blue), forKey: HealthDisplaySettings.colorKey(metric))
                        changed()
                    }), supportsOpacity: false) {
                        Label(metric.title, systemImage: metric.symbol)
                    }
                }
                Toggle("إظهار الأهداف في الودجات", isOn: $showsGoals)
                Toggle("إظهار نسبة الإنجاز", isOn: $showsPercentage)
                Text("الألوان تطبق على الحلقات والأشرطة والرسوم في كل ودجات الصحة. قد يعرض النظام شاشة القفل والودجات الملوّنة بدرجة واحدة.")
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                Button("استعادة ألوان الصحة الأصلية") {
                    for metric in HealthMetric.allCases {
                        AppGroup.defaults.removeObject(forKey: HealthDisplaySettings.colorKey(metric))
                        colors[metric] = metric.color
                    }
                    changed()
                }
            }
            .font(AppFont.ui(14))
        }
        .onChange(of: showsGoals) { changed() }
        .onChange(of: showsPercentage) { changed() }
    }

    private func move(_ index: Int, by offset: Int) {
        let destination = index + offset
        guard metrics.indices.contains(destination) else { return }
        metrics.swapAt(index, destination)
        HealthDisplaySettings.saveMetrics(metrics)
        changed()
    }
    private func changed() {
        HealthWidgets.reload()
        onChange()
    }
}
