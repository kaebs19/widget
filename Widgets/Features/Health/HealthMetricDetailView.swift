import Charts
import SwiftUI

struct HealthMetricDetailView: View {
    let metric: HealthMetric
    @State private var period = Period.week
    @State private var days: [HealthHistoryDay] = []
    @State private var loading = false
    @State private var failed = false

    private enum Period: Int, CaseIterable, Identifiable {
        case day = 1, week = 7, month = 30
        var id: Self { self }
        var title: String {
            switch self { case .day: "اليوم"; case .week: "٧ أيام"; case .month: "٣٠ يومًا" }
        }
    }
    private var values: [Double] { days.compactMap(\.value) }
    private var today: Double? { days.last?.value }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("الفترة", selection: $period) {
                    ForEach(Period.allCases) { item in Text(item.title).tag(item) }
                }
                .pickerStyle(.segmented)
                if !HealthCache.isConnected {
                    ContentUnavailableView("اربط تطبيق الصحة", systemImage: "heart", description: Text("اربط الصحة من الإعدادات لعرض قراءات هذا المؤشر."))
                    NavigationLink("إعدادات الصحة") { HealthSettingsPage() }
                } else if loading {
                    ProgressView("جارٍ قراءة البيانات…").frame(maxWidth: .infinity, minHeight: 180)
                } else if failed {
                    ContentUnavailableView("تعذر قراءة البيانات", systemImage: "arrow.clockwise", description: Text("افتح قفل الجهاز وتحقق من ربط الصحة، ثم أعد المحاولة."))
                    Button("إعادة المحاولة") { Task { await load() } }
                } else if values.isEmpty {
                    ContentUnavailableView("لا توجد قراءات لهذه الفترة", systemImage: metric.symbol,
                                           description: Text("قد لا توجد بيانات مسجّلة، أو لم تسمح بقراءتها. راجع الأذونات من تطبيق الصحة."))
                } else {
                    SettingsSection(period == .day ? "اليوم" : "ملخص الفترة") {
                        if period == .day, let today {
                            summary("المجموع", value: today)
                        } else {
                            summary("متوسط الأيام المتاحة", value: values.reduce(0, +) / Double(values.count))
                            if metric != .sleep { summary("الإجمالي", value: values.reduce(0, +)) }
                            Text("تتوفر قراءة لـ \(DateHelper.arabic(values.count)) من \(DateHelper.arabic(period.rawValue)) يومًا")
                                .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if period != .day {
                        SettingsSection("القراءات اليومية") {
                            Chart(days) { day in
                                if let value = day.value {
                                    BarMark(x: .value("اليوم", day.date, unit: .day), y: .value(metric.unit, value))
                                        .foregroundStyle(metric.color)
                                        .accessibilityLabel(DateHelper.weekdayDayMonth(day.date))
                                        .accessibilityValue(metric.format(value) + " " + metric.unit)
                                }
                            }
                            .chartXScale(domain: chartRange)
                            .chartXAxis { AxisMarks(values: .stride(by: .day, count: period == .month ? 7 : 1)) { _ in AxisValueLabel(format: .dateTime.day()) } }
                            .frame(height: 190)
                            Text("الفجوات أيام بلا قراءة، ولا تُحسب صفرًا في المتوسط. يشمل الرسم اليوم الجاري.")
                                .font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if let today {
                        SettingsSection("هدف اليوم") {
                            summary("قراءة اليوم", value: today)
                            ProgressView(value: min(today / metric.goal, 1)).tint(metric.color)
                            summary("الهدف", value: metric.goal)
                            if today >= metric.goal {
                                Text("حققت هدفك اليوم").foregroundStyle(metric.color)
                            } else { summary("المتبقي", value: max(metric.goal - today, 0)) }
                        }
                    }
                }
            }
            .padding(16).readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(metric.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: period) { await load() }
    }

    private var chartRange: ClosedRange<Date> {
        let start = days.first?.date ?? .now
        let last = days.last?.date ?? start
        let end = Calendar.current.date(byAdding: .day, value: 1, to: last) ?? last.addingTimeInterval(86_400)
        return start...end
    }
    private func summary(_ title: String, value: Double) -> some View {
        HStack {
            Text(title).font(AppFont.ui(14))
            Spacer()
            Text(metric.format(value) + " " + metric.unit)
                .font(AppFont.uiBold(17)).foregroundStyle(metric.color)
        }
    }
    @MainActor
    private func load() async {
        loading = true
        failed = false
        let selected = period
        do {
            let result = try await HealthReader.history(for: metric, days: selected.rawValue)
            guard !Task.isCancelled, selected == period else { return }
            days = result
            loading = false
        } catch {
            guard !Task.isCancelled, selected == period else { return }
            failed = true
            loading = false
        }
    }
}
