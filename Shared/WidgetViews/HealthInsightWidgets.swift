import AppIntents
import SwiftUI
import WidgetKit

struct HealthWaterWidget: View {
    let date: Date
    @AppStorage(WaterTracker.revisionKey, store: AppGroup.defaults) private var revision = 0
    @AppStorage(WaterTracker.goalKey, store: AppGroup.defaults) private var savedGoal = 2000
    @AppStorage(WaterTracker.cupKey, store: AppGroup.defaults) private var savedCup = 250
    @Environment(\.widgetStyle) private var style
    var body: some View {
        let _ = (revision, savedGoal, savedCup)
        let total = WaterTracker.total(on: date)
        let goal = WaterTracker.goal()
        VStack(alignment: .leading, spacing: 6) {
            WidgetHeader(icon: .system("drop.fill"), title: "ماء اليوم")
            Spacer(minLength: 0)
            Text(style.text("\(HealthFormat.decimal(Double(total), digits: 0)) / \(HealthFormat.decimal(Double(goal), digits: 0)) مل"))
                .font(style.font(.labelBold, 17)).foregroundStyle(style.primary)
                .lineLimit(1).minimumScaleFactor(0.65)
            ProgressView(value: min(Double(total) / Double(goal), 1)).tint(style.accent)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Button(intent: AddWaterIntent()) {
                    Label(style.text("\(DateHelper.arabic(WaterTracker.cup())) مل"), systemImage: "plus")
                        .font(style.font(.labelBold, 12)).frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(style.accent)
                .background(style.accent.opacity(0.14), in: Capsule())
                Button(intent: UndoWaterIntent()) {
                    Image(systemName: "arrow.uturn.backward")
                        .frame(minWidth: 32, minHeight: 36)
                }
                .buttonStyle(.plain).foregroundStyle(style.secondary)
                .disabled(total == 0).accessibilityLabel("تراجع عن آخر كوب")
            }
        }
        .widgetContent()
    }
}

struct HealthInsightWidget: View {
    let kind: WidgetKind
    let insights: HealthInsights
    let date: Date
    var isSample = false
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            WidgetHeader(icon: .system(icon), title: kind.title, trailing: "آخر ٧ أيام")
            Group {
                switch kind {
                case .healthWeekly: weekly
                case .healthSleepWeek: sleep
                case .healthStreak: streak
                case .healthWorkouts: workouts
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            Text(isSample ? "بيانات تجريبية للمعاينة" : HealthFormat.updateLabel(insights.date, now: date))
                .font(style.font(.label, 8)).foregroundStyle(style.secondary)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .widgetContent()
    }
    private var icon: String {
        switch kind {
        case .healthSleepWeek: "bed.double.fill"
        case .healthStreak: "flame"
        case .healthWorkouts: "figure.run"
        default: "chart.bar"
        }
    }
    private var weekly: some View {
        let steps = insights.days(.steps, endingAt: date)
        let exercise = insights.days(.exercise, endingAt: date)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                stat("متوسط الخطوات", value: HealthInsights.average(steps).map { HealthMetric.steps.format($0) }, color: HealthMetric.steps.color)
                Spacer()
                stat("دقائق التمرين", value: HealthInsights.total(exercise).map { HealthMetric.exercise.format($0) }, color: HealthMetric.exercise.color)
                Spacer()
                stat("أيام الهدف", value: steps.compactMap(\.value).isEmpty ? nil : "\(DateHelper.arabic(HealthInsights.achieved(steps, metric: .steps))) / \(DateHelper.arabic(steps.compactMap(\.value).count))", color: style.accent)
            }
            HealthHistoryBars(days: steps, metric: .steps).frame(height: 36)
            Text("المتوسط والأهداف حسب الأيام المتاحة")
                .font(style.font(.label, 8)).foregroundStyle(style.secondary)
        }
    }
    private var sleep: some View {
        let days = insights.days(.sleep, endingAt: date)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                stat("متوسط النوم", value: HealthInsights.average(days).map { HealthMetric.sleep.format($0) + " ساعة" }, color: HealthMetric.sleep.color)
                Spacer()
                stat("هدف اليوم", value: HealthMetric.sleep.format(HealthMetric.sleep.goal) + " ساعة", color: style.accent)
                Spacer()
                stat("ليالٍ مسجّلة", value: days.compactMap(\.value).isEmpty ? nil : DateHelper.arabic(days.compactMap(\.value).count), color: style.accent)
            }
            HealthHistoryBars(days: days, metric: .sleep).frame(height: 42)
        }
    }
    private var streak: some View {
        let days = insights.days(.steps, count: 31, endingAt: date)
        let result = HealthStreak.calculate(days, metric: .steps, now: date)
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 1) {
                Text(days.compactMap(\.value).isEmpty ? "—" : style.number(result.count) + (result.isLimited ? "+" : ""))
                    .font(style.font(.number, 36)).foregroundStyle(style.accent)
                Text("يوم متتالٍ مؤكّد").font(style.font(.label, 10)).foregroundStyle(style.secondary)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text("هدف الخطوات").font(style.font(.labelBold, 12)).foregroundStyle(style.primary)
                HealthHistoryBars(days: Array(days.suffix(7)), metric: .steps).frame(height: 36)
                Text("افتح تقويم الإنجاز للتفاصيل")
                    .font(style.font(.label, 9)).foregroundStyle(style.secondary)
            }
        }
    }
    private var workouts: some View {
        let items = insights.weekWorkouts(endingAt: date)
        return VStack(alignment: .leading, spacing: 4) {
            if let last = insights.workouts?.filter({ $0.date <= date }).max(by: { $0.date < $1.date }) {
                HStack {
                    Text(last.title).font(style.font(.textBold, 20)).foregroundStyle(style.primary)
                    Spacer()
                    Text(style.text(HealthFormat.decimal(last.minutes, digits: 0) + " دقيقة"))
                        .font(style.font(.labelBold, 13)).foregroundStyle(style.accent)
                }
                Text(style.text(DateHelper.weekdayDayMonth(last.date)))
                    .font(style.font(.label, 10)).foregroundStyle(style.secondary)
                Spacer(minLength: 0)
                Text(items.isEmpty ? "لا تمارين متاحة لهذا الأسبوع" : style.text("هذا الأسبوع: \(DateHelper.arabic(items.count)) تمرين · \(HealthFormat.decimal(items.reduce(0) { $0 + $1.minutes }, digits: 0)) دقيقة"))
                    .font(style.font(.label, 11)).foregroundStyle(style.secondary)
            } else {
                Text("لا توجد تمارين متاحة")
                    .font(style.font(.labelBold, 15)).foregroundStyle(style.primary)
                Text("سجّل تمرينًا في الصحة أو راجع أذونات التمارين")
                    .font(style.font(.label, 11)).foregroundStyle(style.secondary)
            }
        }
    }
    private func stat(_ title: String, value: String?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(style.font(.label, 9)).foregroundStyle(style.secondary)
            Text(style.text(value ?? "—")).font(style.font(.number, 19)).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.65)
        }
    }
}

struct HealthHistoryBars: View {
    let days: [HealthHistoryDay]
    let metric: HealthMetric
    @Environment(\.widgetStyle) private var style
    var body: some View {
        let top = max(days.compactMap(\.value).max() ?? 0, metric.goal, 1)
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(days) { day in
                VStack(spacing: 2) {
                    GeometryReader { proxy in
                        VStack {
                            Spacer(minLength: 0)
                            if let value = day.value {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(metric.color.opacity(value >= HealthGoals.goal(metric, on: day.date) ? 1 : 0.45))
                                    .frame(height: max(0, proxy.size.height * value / top))
                            } else {
                                Text("—").font(style.font(.label, 8)).foregroundStyle(style.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    Text(day.date.formatted(.dateTime.locale(DateHelper.locale).weekday(.narrow)))
                        .font(style.font(.label, 8)).foregroundStyle(style.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(DateHelper.weekdayDayMonth(day.date))
                .accessibilityValue(day.value.map { metric.format($0) + " " + metric.unit } ?? "لا توجد قراءة")
            }
        }
    }
}
