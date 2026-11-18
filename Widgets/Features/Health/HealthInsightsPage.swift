import SwiftUI

struct HealthInsightsPage: View {
    enum Mode { case weekly, streak, workouts }
    var mode: Mode
    @State private var insights = HealthInsightsCache.load()
    @State private var loading = false
    @State private var metric: HealthMetric = .steps
    private var title: String { L10n.text(mode == .weekly ? "أسبوعي الصحي" : mode == .streak ? "استمراريتي" : "تماريني") }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !HealthCache.isConnected {
                    ContentUnavailableView("اربط تطبيق الصحة", systemImage: "heart", description: Text("الملخصات تعتمد على قراءات تطبيق الصحة."))
                    NavigationLink("إعدادات الصحة") { HealthSettingsPage() }
                } else if let insights {
                    switch mode {
                    case .weekly: weekly(insights)
                    case .streak: streak(insights)
                    case .workouts: workouts(insights)
                    }
                    Text(HealthFormat.updateLabel(insights.date))
                        .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                } else if loading { ProgressView("جارٍ قراءة البيانات…") }
                else {
                    ContentUnavailableView("لا توجد قراءات متاحة", systemImage: "chart.bar", description: Text("افتح قفل الجهاز وراجع أذونات الصحة ثم حدّث البيانات."))
                }
                if HealthCache.isConnected {
                    Button { Task { await refresh(force: true) } } label: {
                        Label(loading ? "جارٍ التحديث…" : "تحديث البيانات", systemImage: "arrow.clockwise")
                    }.disabled(loading)
                }
            }.padding(16).readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh(force: false) }
    }
    private func weekly(_ data: HealthInsights) -> some View {
        VStack(spacing: 20) {
            SettingsSection("آخر ٧ أيام") {
                let steps = data.days(.steps)
                let exercise = data.days(.exercise)
                let sleep = data.days(.sleep)
                summary("متوسط الخطوات", HealthInsights.average(steps).map { HealthMetric.steps.format($0) + " " + HealthMetric.steps.unit })
                summary("دقائق التمرين", HealthInsights.total(exercise).map { HealthMetric.exercise.format($0) + " " + HealthMetric.exercise.unit })
                summary("متوسط النوم", HealthInsights.average(sleep).map { HealthMetric.sleep.format($0) + " " + HealthMetric.sleep.unit })
                summary("أيام تحقيق هدف الخطوات", steps.compactMap(\.value).isEmpty ? nil : String(format: L10n.text("%@ من %@ يوم مسجّل"), DateHelper.arabic(HealthInsights.achieved(steps, metric: .steps)), DateHelper.arabic(steps.compactMap(\.value).count)))
                Text("المتوسطات تستبعد الأيام بلا قراءة وتشمل اليوم الجاري.")
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            }
            ForEach([HealthMetric.steps, .exercise, .sleep]) { item in
                NavigationLink(String(format: L10n.text("%@ · التفاصيل"), item.title)) { HealthMetricDetailView(metric: item) }
                    .font(AppFont.uiBold(15))
            }
        }
    }
    private func streak(_ data: HealthInsights) -> some View {
        let days = data.days(metric, count: 30)
        let result = HealthStreak.calculate(data.days(metric, count: 31), metric: metric)
        let count = days.compactMap(\.value).count
        return VStack(spacing: 20) {
            Picker("المؤشر", selection: $metric) {
                ForEach([HealthMetric.steps, .exercise, .sleep]) { item in Text(item.title).tag(item) }
            }.pickerStyle(.segmented)
            SettingsSection("سلسلة الإنجاز") {
                Text(count == 0 ? L10n.text("لا توجد قراءات") : String(format: L10n.text("%@%@ يوم متتالٍ مؤكّد"), DateHelper.arabic(result.count), result.isLimited ? "+" : ""))
                    .font(AppFont.uiBold(25)).foregroundStyle(metric.color)
                Text("إذا لم يتحقق هدف اليوم بعد، تُحسب السلسلة المنتهية بالأمس. غياب القراءة يوقف السلسلة المؤكدة، ولا يعني إخفاقًا مسجّلًا.")
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            }
            SettingsSection("تقويم آخر ٣٠ يومًا") {
                calendar(days)
                Text("● حققت الهدف   ◌ قراءة دون الهدف   — لا توجد قراءة")
                    .font(AppFont.ui(11)).foregroundStyle(Theme.textSecondary)
                Text("تُستخدم أهداف أيام الأسبوع الحالية. علامة + تعني أن السلسلة قد تمتد قبل نافذة القراءات المتاحة.")
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            }
            NavigationLink("تخصيص أهداف أيام الأسبوع") { WeeklyHealthGoalsView() }
        }
    }
    private func calendar(_ days: [HealthHistoryDay]) -> some View {
        let calendar = Calendar.current
        let leading = days.first.map { (calendar.component(.weekday, from: $0.date) - calendar.firstWeekday + 7) % 7 } ?? 0
        let names = ["ح", "ن", "ث", "ر", "خ", "ج", "س"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(0..<7, id: \.self) { index in
                Text(names[(calendar.firstWeekday - 1 + index) % 7]).font(AppFont.ui(11)).foregroundStyle(Theme.textSecondary)
            }
            ForEach(0..<leading, id: \.self) { _ in Color.clear.frame(height: 36) }
            ForEach(days) { day in
                let achieved = day.value.map { $0 >= HealthGoals.goal(metric, on: day.date) } ?? false
                VStack(spacing: 1) {
                    Text(DateHelper.arabic(calendar.component(.day, from: day.date)))
                    if day.value == nil { Text("—").font(.system(size: 8)) }
                }
                .font(AppFont.ui(12))
                .frame(maxWidth: .infinity, minHeight: 36)
                .foregroundStyle(achieved ? Theme.onAccent : Theme.textPrimary)
                .background(achieved ? metric.color : Theme.cardTop, in: Circle())
                .overlay(Circle().strokeBorder(calendar.isDateInToday(day.date) ? Theme.gold : .clear))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(DateHelper.weekdayDayMonth(day.date) + ": " + L10n.text(day.value == nil ? "لا توجد قراءة" : achieved ? "تحقق الهدف" : "قراءة دون الهدف"))
            }
        }
    }
    private func workouts(_ data: HealthInsights) -> some View {
        let week = data.weekWorkouts()
        let all = (data.workouts ?? []).sorted { $0.date > $1.date }
        return VStack(spacing: 20) {
            SettingsSection("تمارين آخر ٧ أيام") {
                summary("عدد التمارين المتاحة", week.isEmpty ? nil : DateHelper.arabic(week.count))
                summary("المدة الإجمالية", week.isEmpty ? nil : HealthFormat.decimal(week.reduce(0) { $0 + $1.minutes }, digits: 0) + " " + HealthMetric.exercise.unit)
                Text("نقرأ التمارين المسجّلة فقط. إن لم تظهر، راجع إذن قراءة التمارين من إعدادات الصحة.")
                    .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            }
            if all.isEmpty {
                ContentUnavailableView("لا توجد تمارين متاحة", systemImage: "figure.run")
            } else {
                SettingsSection("التمارين المسجّلة · آخر ٣١ يومًا") {
                    ForEach(all) { workout in
                        VStack(alignment: .leading, spacing: 5) {
                            summary(workout.title, HealthFormat.decimal(workout.minutes, digits: 0) + " " + HealthMetric.exercise.unit)
                            Text(DateHelper.weekdayDayMonth(workout.date))
                                .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                            if let energy = workout.energy {
                                Text(HealthFormat.decimal(energy, digits: 0) + " " + HealthMetric.energy.unit)
                                    .font(AppFont.ui(12)).foregroundStyle(HealthMetric.energy.color)
                            }
                        }
                    }
                }
            }
            NavigationLink("مراجعة إعدادات الصحة والأذونات") { HealthSettingsPage() }
        }
    }
    private func summary(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(L10n.text(title)).font(AppFont.ui(14))
            Spacer()
            Text(value ?? "—").font(AppFont.uiBold(16)).foregroundStyle(Theme.gold)
        }
    }
    @MainActor private func refresh(force: Bool) async {
        guard !loading, HealthCache.isConnected else { return }
        loading = true
        insights = await HealthInsightsReader.shared.refresh(force: force)
        loading = false
        HealthWidgets.reload()
    }
}
