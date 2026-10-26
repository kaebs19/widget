import SwiftUI
import WidgetKit

struct QuranGoalSettings: View {
    let onChange: () -> Void
    @AppStorage("quranGoal.target", store: AppGroup.defaults) private var target = 5
    @State private var pages = QuranGoal.pages()
    @State private var recordedDay = TasbeehCounter.dayID(for: .now)
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        SettingsSection("ورد القرآن") {
            Stepper("الهدف اليومي: \(DateHelper.arabic(target)) صفحة", value: $target, in: 1...100)
            HStack {
                Text("قرأت اليوم: \(DateHelper.arabic(pages)) صفحة")
                Spacer()
                Button { changePages(by: -1) } label: { Image(systemName: "minus.circle") }
                    .accessibilityLabel("إنقاص صفحة")
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(pages == 0)
                Button { changePages(by: 1) } label: { Image(systemName: "plus.circle") }
                    .accessibilityLabel("تسجيل صفحة")
                    .frame(minWidth: 44, minHeight: 44)
                    .disabled(pages >= 604)
            }
            Text(pages >= target ? "أتممت ورد اليوم، تقبّل الله منك." : "سجّل الصفحات التي قرأتها هنا أو من زر الودجت. يبدأ عدّ جديد كل يوم.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .onChange(of: target) { reload() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in refresh() }
        .onAppear { refresh() }
    }

    private func refresh() {
        let current = QuranGoal.pages()
        if pages != current { pages = current; onChange() }
        recordedDay = TasbeehCounter.dayID(for: .now)
    }

    private func changePages(by delta: Int) {
        let now = Date.now
        if recordedDay != TasbeehCounter.dayID(for: now) { refresh() }
        pages = min(max(QuranGoal.pages(on: now) + delta, 0), 604)
        QuranGoal.setPages(pages, on: now)
        reload()
    }

    private func reload() {
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.quranGoal.rawValue)
        onChange()
    }
}
