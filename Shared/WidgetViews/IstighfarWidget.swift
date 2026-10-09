//
//  IstighfarWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - الاستغفار
struct IstighfarWidget: View {
    var date: Date = .now
    @Environment(\.widgetStyle) private var style
    @Environment(\.widgetRenderingMode) private var renderingMode

    // يقرأ من المساحة المشتركة، وداخل التطبيق يعيد الرسم فور الضغط على الزر
    @AppStorage(IstighfarCounter.countKey, store: AppGroup.defaults) private var storedCount = 0
    @AppStorage(IstighfarCounter.dayKey, store: AppGroup.defaults) private var storedDay = ""

    private let goal = IstighfarCounter.goal

    /// عدد اليوم فقط؛ إذا المحفوظ من يوم سابق نبدأ من صفر
    private var count: Int {
        storedDay == IstighfarCounter.dayID(for: date) ? storedCount : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("الاستغفار")
                Spacer()
                Text("اليوم")
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)

            Spacer(minLength: 0)
            Text("أستغفر الله")
                .font(style.font(.textBold, 24))
                .foregroundStyle(style.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .widgetAccentable()
            ProgressView(value: Double(min(count, goal)), total: Double(goal))
                .tint(style.accent)
                .widgetAccentable()

            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(style.number(count))
                        .font(style.font(.number, 24))
                        .foregroundStyle(style.primary)
                        .contentTransition(.numericText(value: Double(count)))
                        .widgetAccentable()
                    Text("/ \(style.number(goal))")
                        .font(style.font(.label, 11))
                        .foregroundStyle(style.secondary)
                }
                Spacer()
                // Button(intent:) يشتغل من الشاشة الرئيسية بدون فتح التطبيق
                Button(intent: IncrementIstighfarIntent()) {
                    plusButton
                }
                .buttonStyle(.plain)
                .accessibilityLabel("استغفار")
            }
        }
        .widgetContent()
    }

    /// في الوضع الملوّن يُرسم كل شيء بلون واحد، فعلامة + الداكنة فوق الدائرة تختفي؛
    /// نخفف الدائرة ونترك العلامة بلون النص
    @ViewBuilder
    private var plusButton: some View {
        let isFullColor = renderingMode == .fullColor
        Image(systemName: "plus")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(isFullColor ? style.onPrimary : style.primary)
            .frame(width: 40, height: 40)
            .background {
                Circle()
                    .fill(style.primary.opacity(isFullColor ? 0.92 : 0.25))
                    .widgetAccentable()
            }
    }
}
