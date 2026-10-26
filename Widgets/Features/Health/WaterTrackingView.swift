import SwiftUI
import WidgetKit

struct WaterTrackingView: View {
    @AppStorage(WaterTracker.revisionKey, store: AppGroup.defaults) private var revision = 0
    @AppStorage(WaterTracker.goalKey, store: AppGroup.defaults) private var goal = 2000
    @AppStorage(WaterTracker.cupKey, store: AppGroup.defaults) private var cup = 250
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now

    var body: some View {
        let _ = revision
        let total = WaterTracker.total(on: now)
        let entries = WaterTracker.today(on: now)
        Form {
            Section("ماء اليوم") {
                Text("\(DateHelper.arabic(total)) / \(DateHelper.arabic(WaterTracker.goal())) مل")
                    .font(AppFont.uiBold(25)).foregroundStyle(Theme.gold)
                ProgressView(value: min(Double(total) / Double(WaterTracker.goal()), 1)).tint(.cyan)
                Button {
                    WaterTracker.add()
                    now = .now
                    reload()
                } label: {
                    Label("تسجيل كوب · \(DateHelper.arabic(WaterTracker.cup())) مل", systemImage: "plus.circle.fill")
                }
                Button("التراجع عن آخر كوب", systemImage: "arrow.uturn.backward") {
                    WaterTracker.undo()
                    now = .now
                    reload()
                }
                .disabled(entries.isEmpty)
            }
            Section {
                Stepper("هدف اليوم: \(DateHelper.arabic(goal)) مل", value: $goal, in: 100...6000, step: 100)
                Stepper("حجم الكوب: \(DateHelper.arabic(cup)) مل", value: $cup, in: 50...1000, step: 50)
            } header: { Text("إعدادات الماء") } footer: {
                Text("اختر هدفك وحجم كوبك. التسجيل محفوظ محليًا داخل التطبيق، ويبدأ مجموع جديد كل يوم. لا نكتب هذه السجلات في تطبيق الصحة.")
            }
            Section("سجل اليوم") {
                if entries.isEmpty { Text("لم تسجل أي كوب اليوم").foregroundStyle(.secondary) }
                ForEach(entries) { entry in
                    HStack {
                        Text("\(DateHelper.arabic(entry.milliliters)) مل")
                        Spacer()
                        Text(entry.date.formatted(date: .omitted, time: .shortened)).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { WaterTracker.remove(entries[index].id) }
                    now = .now
                    reload()
                }
            }
        }
        .navigationTitle("ماء اليوم")
        .onAppear { now = .now; goal = WaterTracker.goal(); cup = WaterTracker.cup() }
        .onChange(of: goal) { reload() }
        .onChange(of: cup) { reload() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
    }
    private func reload() { WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.healthWater.rawValue) }
}
