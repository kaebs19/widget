//
//  HealthWidgets.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - مكوّنات مشتركة
extension HealthMetric {
    var color: Color { Color(Color.Resolved(hex: hex)) }
}

/// حلقة تقدّم على طريقة حلقات النشاط: مسار باهت، وتقدّم بطرف مدوّر
struct HealthRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 10
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(renderingMode == .fullColor ? 0.22 : 0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(progress, 0.001))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .widgetAccentable()
        }
        .padding(lineWidth / 2)
    }
}

/// ثلاث حلقات متداخلة: السعرات خارجاً، ثم التمرين، ثم الخطوات
struct HealthRings: View {
    let snapshot: HealthSnapshot
    var lineWidth: CGFloat = 11
    static let metrics: [HealthMetric] = [.energy, .exercise, .steps]

    var body: some View {
        ZStack {
            ForEach(Array(Self.metrics.enumerated()), id: \.element) { index, metric in
                HealthRing(progress: snapshot.progress(metric), color: metric.color, lineWidth: lineWidth)
                    .padding(CGFloat(index) * (lineWidth + 2))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

/// أعمدة خطوات آخر ٧ أيام، مع خط الهدف واليوم مميّز
struct HealthWeekChart: View {
    let snapshot: HealthSnapshot
    let date: Date
    var showsLabels = true
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let goal = HealthMetric.steps.goal
        let top = max(snapshot.weekSteps.max() ?? 0, goal) * 1.08
        let labels = HealthFormat.weekdayInitials(endingAt: date)
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(Array(snapshot.weekSteps.enumerated()), id: \.offset) { index, steps in
                let isToday = index == snapshot.weekSteps.count - 1
                VStack(spacing: 3) {
                    GeometryReader { proxy in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(steps >= goal || isToday ? HealthMetric.steps.color
                                                                : HealthMetric.steps.color.opacity(0.4))
                                .frame(height: max(proxy.size.height * steps / top, 3))
                                .widgetAccentable(isToday)
                        }
                    }
                    if showsLabels, index < labels.count {
                        Text(labels[index])
                            .font(style.font(isToday ? .labelBold : .label, 9))
                            .foregroundStyle(isToday ? style.primary : style.secondary)
                    }
                }
            }
        }
        .overlay(alignment: .top) {
            // خط الهدف
            GeometryReader { proxy in
                let chartHeight = proxy.size.height - (showsLabels ? 14 : 0)
                Path { path in
                    let y = chartHeight * (1 - goal / top)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                }
                .stroke(style.secondary.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
    }
}

/// قيمة مقياس صغيرة: أيقونة ملوّنة، والرقم، والوحدة
struct HealthStat: View {
    let metric: HealthMetric
    let snapshot: HealthSnapshot
    var valueSize: CGFloat = 15
    var showsBar = false
    /// في المتوسط نكتفي بالأيقونة، والوحدة تدل على المقياس
    var showsTitle = true
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: metric.symbol)
                    .font(.system(size: valueSize * 0.65, weight: .semibold))
                    .foregroundStyle(metric.color)
                    .widgetAccentable()
                if showsTitle {
                    Text(metric.title)
                        .font(style.font(.label, 10))
                        .foregroundStyle(style.secondary)
                        .lineLimit(1)
                }
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(style.text(metric.format(snapshot.value(metric))))
                    .font(style.font(.number, valueSize))
                    .foregroundStyle(style.primary)
                Text(metric.unit)
                    .font(style.font(.label, 9))
                    .foregroundStyle(style.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            if showsBar {
                Capsule()
                    .fill(metric.color.opacity(0.22))
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule().fill(metric.color)
                                .frame(width: max(proxy.size.width * snapshot.progress(metric), 4))
                                .widgetAccentable()
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// قبل ربط الصحة من التطبيق
struct HealthConnectPrompt: View {
    var compact = false
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: compact ? 26 : 32))
                .foregroundStyle(HealthMetric.energy.color)
                .widgetAccentable()
            Text("افتح التطبيق لربط الصحة")
                .font(style.font(.labelBold, compact ? 12 : 13))
                .foregroundStyle(style.primary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - الخطوات
struct HealthStepsWidget: View {
    let snapshot: HealthSnapshot
    let date: Date
    var size: WidgetSize = .small
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if size == .small { small } else { medium }
    }

    private var ring: some View {
        ZStack {
            HealthRing(progress: snapshot.progress(.steps), color: HealthMetric.steps.color, lineWidth: 9)
            VStack(spacing: 0) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(HealthMetric.steps.color)
                    .widgetAccentable()
                Text(style.text(HealthMetric.steps.format(snapshot.value(.steps))))
                    .font(style.font(.number, 22))
                    .foregroundStyle(style.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(style.text("من \(HealthMetric.steps.format(HealthMetric.steps.goal))"))
                    .font(style.font(.label, 9))
                    .foregroundStyle(style.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 16)
        }
    }

    private var small: some View {
        VStack(spacing: 6) {
            ring
            HStack {
                miniValue(.distance)
                Spacer(minLength: 4)
                miniValue(.energy)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func miniValue(_ metric: HealthMetric) -> some View {
        HStack(spacing: 2) {
            Image(systemName: metric.symbol)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(metric.color)
                .widgetAccentable()
            Text(style.text("\(metric.format(snapshot.value(metric))) \(metric.unit)"))
                .font(style.font(.labelBold, 10))
                .foregroundStyle(style.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    // الحلقة في جهة، وأسبوع الخطوات في الأخرى
    private var medium: some View {
        HStack(spacing: 14) {
            ring.frame(width: 128)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("آخر ٧ أيام")
                        .font(style.font(.labelBold, 11))
                        .foregroundStyle(style.primary)
                    Spacer()
                    Text(style.text("المعدل \(HealthMetric.steps.format(average))"))
                        .font(style.font(.label, 10))
                        .foregroundStyle(style.secondary)
                }
                HealthWeekChart(snapshot: snapshot, date: date)
                HStack {
                    miniValue(.distance)
                    Spacer(minLength: 4)
                    miniValue(.energy)
                    Spacer(minLength: 4)
                    miniValue(.flights)
                }
            }
        }
        .padding(14)
    }

    private var average: Double {
        let days = snapshot.weekSteps
        return days.isEmpty ? 0 : days.reduce(0, +) / Double(days.count)
    }
}

// MARK: - حلقات النشاط
struct HealthActivityWidget: View {
    let snapshot: HealthSnapshot
    var size: WidgetSize = .small
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if size == .small {
            VStack(spacing: 8) {
                HealthRings(snapshot: snapshot, lineWidth: 10)
                HStack(spacing: 8) {
                    ForEach(HealthRings.metrics) { metric in
                        Text(style.text(metric.format(snapshot.value(metric))))
                            .font(style.font(.number, 12))
                            .foregroundStyle(metric.color)
                            .widgetAccentable()
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            HStack(spacing: 16) {
                HealthRings(snapshot: snapshot, lineWidth: 12)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(HealthRings.metrics) { metric in
                        row(metric)
                    }
                }
            }
            .padding(14)
        }
    }

    private func row(_ metric: HealthMetric) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(metric.title)
                .font(style.font(.label, 11))
                .foregroundStyle(style.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(style.text(metric.format(snapshot.value(metric))))
                    .font(style.font(.number, 19))
                    .foregroundStyle(metric.color)
                    .widgetAccentable()
                Text(style.text("/ \(metric.format(metric.goal)) \(metric.unit)"))
                    .font(style.font(.label, 10))
                    .foregroundStyle(style.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - لوحة الصحة
struct HealthDashboardWidget: View {
    let snapshot: HealthSnapshot
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    private let grid: [HealthMetric] = [.steps, .distance, .energy, .exercise, .flights, .sleep]

    var body: some View {
        if size == .large { large } else { medium }
    }

    private var tiles: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(grid) { metric in
                HealthStat(metric: metric, snapshot: snapshot, valueSize: size == .large ? 18 : 16,
                           showsBar: true, showsTitle: size == .large)
            }
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer(minLength: 0)
            tiles
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.system(size: 11))
                .foregroundStyle(HealthMetric.energy.color)
                .widgetAccentable()
            Text("صحتي اليوم")
            Spacer()
            Text(style.text(DateHelper.weekdayDayMonth(date)))
        }
        .font(style.font(.label, 11))
        .foregroundStyle(style.secondary)
    }

    // الكبير: الحلقات والأسبوع في الأعلى، ثم كل المقاييس
    private var large: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            HStack(spacing: 16) {
                HealthRings(snapshot: snapshot, lineWidth: 11).frame(width: 118)
                VStack(alignment: .leading, spacing: 6) {
                    Text("الخطوات · آخر ٧ أيام")
                        .font(style.font(.labelBold, 11))
                        .foregroundStyle(style.primary)
                    HealthWeekChart(snapshot: snapshot, date: date)
                }
            }
            .frame(height: 128)
            Divider().overlay(style.secondary.opacity(0.3))
            tiles
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - النوم
struct HealthSleepWidget: View {
    let snapshot: HealthSnapshot
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let hours = snapshot.value(.sleep)
        let goal = HealthMetric.sleep.goal
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(HealthMetric.sleep.color)
                    .widgetAccentable()
                Text("نوم الليلة")
                Spacer()
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)

            Spacer(minLength: 0)
            if hours == 0 {
                Text("لا بيانات نوم")
                    .font(style.font(.textBold, 16))
                    .foregroundStyle(style.primary)
                Text("تُسجَّل من الساعة أو وضع النوم")
                    .font(style.font(.label, 10))
                    .foregroundStyle(style.secondary)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(style.text(HealthMetric.sleep.format(hours)))
                        .font(style.font(.number, 40))
                        .foregroundStyle(style.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("ساعة").font(style.font(.label, 11)).foregroundStyle(style.secondary)
                }
                Text(style.text(note(hours: hours, goal: goal)))
                    .font(style.font(.label, 11))
                    .foregroundStyle(hours >= goal ? HealthMetric.steps.color : style.secondary)
            }
            Spacer(minLength: 0)
            Capsule()
                .fill(HealthMetric.sleep.color.opacity(0.22))
                .frame(height: 6)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule().fill(HealthMetric.sleep.color)
                            .frame(width: max(proxy.size.width * snapshot.progress(.sleep), 6))
                            .widgetAccentable()
                    }
                }
            Text(style.text("الهدف \(HealthMetric.sleep.format(goal)) ساعات"))
                .font(style.font(.label, 10))
                .foregroundStyle(style.secondary)
        }
        .widgetContent()
    }

    private func note(hours: Double, goal: Double) -> String {
        guard hours < goal else { return "حققت هدف النوم" }
        let minutes = Int(((goal - hours) * 60).rounded())
        return minutes >= 60 ? "أقل من هدفك بـ \(HealthFormat.duration(hours: goal - hours))"
                             : "أقل من هدفك بـ \(DateHelper.arabic(minutes)) دقيقة"
    }
}

// MARK: - شاشة القفل
struct HealthLockView: View {
    let kind: WidgetKind
    let date: Date
    let family: WidgetFamily
    var style: WidgetStyle = .default

    var body: some View {
        if let snapshot = HealthCache.load(now: date) {
            content(snapshot)
        } else {
            Label("اربط الصحة", systemImage: "heart")
        }
    }

    @ViewBuilder
    private func content(_ snapshot: HealthSnapshot) -> some View {
        switch (kind, family) {
        case (.healthSleep, .accessoryInline):
            Label(LockText.inline(style.text("نوم \(HealthMetric.sleep.format(snapshot.value(.sleep))) ساعة")),
                  systemImage: "bed.double.fill")
        case (.healthSleep, .accessoryCircular):
            gauge(.sleep, snapshot)
        case (.healthSleep, _):
            rectangular([.sleep], snapshot)
        case (.healthActivity, .accessoryCircular):
            HealthRings(snapshot: snapshot, lineWidth: 5).padding(2)
        case (.healthActivity, _), (.healthDashboard, _):
            if family == .accessoryInline {
                inline(snapshot)
            } else {
                rectangular(HealthRings.metrics, snapshot)
            }
        case (_, .accessoryInline):
            inline(snapshot)
        case (_, .accessoryCircular):
            gauge(.steps, snapshot)
        default:
            rectangular([.steps, .distance], snapshot)
        }
    }

    private func inline(_ snapshot: HealthSnapshot) -> some View {
        Label(LockText.inline(style.text("\(HealthMetric.steps.format(snapshot.value(.steps))) خطوة · \(HealthMetric.distance.format(snapshot.value(.distance))) كم")),
              systemImage: "figure.walk")
    }

    private func gauge(_ metric: HealthMetric, _ snapshot: HealthSnapshot) -> some View {
        Gauge(value: snapshot.progress(metric)) { EmptyView() } currentValueLabel: {
            VStack(spacing: 0) {
                Image(systemName: metric.symbol).font(.system(size: 10))
                Text(style.text(compact(metric, snapshot.value(metric))))
                    .font(style.font(.number, 14))
                    .minimumScaleFactor(0.5)
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    /// ٧٫٥ ألف للخطوات في الدائرة الصغيرة
    private func compact(_ metric: HealthMetric, _ value: Double) -> String {
        guard metric == .steps, value >= 1_000 else { return metric.format(value) }
        return "\(HealthFormat.decimal(value / 1_000, digits: 1))أ"
    }

    private func rectangular(_ metrics: [HealthMetric], _ snapshot: HealthSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: metric.symbol).font(.system(size: 10)).frame(width: 14)
                        Text(style.text("\(metric.format(snapshot.value(metric))) \(metric.unit)"))
                            .font(style.font(.labelBold, metrics.count > 2 ? 11 : 13))
                        Spacer(minLength: 0)
                    }
                    if metrics.count <= 2 {
                        ProgressView(value: snapshot.progress(metric))
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
