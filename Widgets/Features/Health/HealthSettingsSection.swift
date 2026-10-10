//
//  HealthSettingsSection.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import SwiftUI

// MARK: - إعدادات الصحة
// في الإعدادات وفي صفحات ودجات الصحة: الربط، وملخص اليوم، والأهداف
struct HealthSettingsSection: View {
    var onChange: () -> Void = {}
    @AppStorage(HealthCache.connectedKey, store: AppGroup.defaults) private var connected = false
    @State private var snapshot = HealthCache.load()
    @State private var isLoading = false
    @State private var goals: [HealthMetric: Double] = Dictionary(
        uniqueKeysWithValues: HealthMetric.allCases.map { ($0, $0.goal) })
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 20) {
            connection
            if connected { today }
            goalsSection
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
        .task { if connected { await refresh() } }
    }

    private func refresh() async {
        isLoading = true
        snapshot = await HealthReader.refresh()
        isLoading = false
        HealthWidgets.reload()
        onChange()
    }

    // MARK: الربط
    private var connection: some View {
        SettingsSection("تطبيق الصحة") {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(HealthMetric.energy.color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(connected ? "مربوط بتطبيق الصحة" : "اربط تطبيق الصحة")
                        .font(AppFont.uiBold(15))
                    Text(HealthReader.isAvailable ? "نقرأ فقط، ولا نكتب شيئاً في الصحة"
                                                  : "الصحة غير متاحة على هذا الجهاز")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if isLoading { ProgressView() }
            }
            Button {
                Task {
                    if await HealthReader.requestAuthorization() {
                        connected = true
                        HealthWidgets.startBackgroundUpdates()
                        await refresh()
                    }
                }
            } label: {
                Label(connected ? "مراجعة الأذونات" : "ربط الصحة", systemImage: connected ? "checkmark.shield" : "link")
                    .font(AppFont.uiBold(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(connected ? Theme.gold : Theme.onAccent)
                    .background(connected ? AnyShapeStyle(Theme.gold.opacity(0.12)) : AnyShapeStyle(Theme.gold),
                                in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!HealthReader.isAvailable)
            Text(connected
                 ? "إذا ظهرت الأرقام أصفاراً: افتح تطبيق الصحة ← ملفك ← التطبيقات ← ويدجت، وفعّل القراءة. والجهاز مقفل تعرض الودجات آخر قراءة."
                 : "تظهر نافذة الصحة لتختار ما نقرأه: الخطوات والمسافة والسعرات والتمرين والطوابق والنوم. بياناتك تبقى على جهازك.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: اليوم
    private var today: some View {
        SettingsSection("اليوم") {
            if let snapshot {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                    ForEach(HealthMetric.allCases) { metric in
                        tile(metric, snapshot)
                    }
                }
                HStack {
                    Text("آخر تحديث \(snapshot.date.formatted(date: .omitted, time: .shortened))")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Button {
                        Task { await refresh() }
                    } label: {
                        Label("تحديث", systemImage: "arrow.clockwise").font(AppFont.uiBold(13))
                    }
                }
            } else {
                Text("لا بيانات بعد. امشِ قليلاً أو تأكد من أذونات القراءة.")
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func tile(_ metric: HealthMetric, _ snapshot: HealthSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(metric.title, systemImage: metric.symbol)
                .font(AppFont.ui(11))
                .foregroundStyle(Theme.textSecondary)
                .labelStyle(TintedIconLabel(color: metric.color))
            Text("\(metric.format(snapshot.value(metric))) \(metric.unit)")
                .font(AppFont.uiBold(15))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            ProgressView(value: snapshot.progress(metric)).tint(metric.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: الأهداف
    private var goalsSection: some View {
        SettingsSection("الأهداف اليومية") {
            ForEach(HealthMetric.allCases) { metric in
                let value = goals[metric] ?? metric.defaultGoal
                HStack(spacing: 10) {
                    Image(systemName: metric.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(metric.color)
                        .frame(width: 24)
                    Text(metric.title)
                    Spacer()
                    Text("\(metric.format(value)) \(metric.unit)")
                        .font(AppFont.uiBold(14))
                        .foregroundStyle(Theme.gold)
                    Stepper(metric.title, value: Binding(get: { value }, set: { setGoal(metric, $0) }),
                            in: metric.goalRange, step: metric.goalStep)
                        .labelsHidden()
                }
            }
            Text("الحلقات والأشرطة في الودجات تمتلئ عند بلوغ الهدف.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func setGoal(_ metric: HealthMetric, _ value: Double) {
        goals[metric] = value
        AppGroup.defaults.set(value, forKey: metric.goalKey)
        HealthWidgets.reload()
        onChange()
    }
}

/// صفحة الصحة من الإعدادات
struct HealthSettingsPage: View {
    var body: some View {
        ScrollView {
            HealthSettingsSection().padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("الصحة")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// أيقونة ملوّنة بجانب نص رمادي
private struct TintedIconLabel: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(color)
            configuration.title
        }
    }
}
