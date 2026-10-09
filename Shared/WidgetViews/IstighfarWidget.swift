//
//  IstighfarWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - عدّاد الذكر (الاستغفار والتسبيح والتهليل والصلاة على النبي ﷺ)
struct IstighfarWidget: View {
    var dhikr: TasbeehDhikr = .istighfar
    var date: Date = .now
    @Environment(\.widgetStyle) private var style
    @Environment(\.widgetRenderingMode) private var renderingMode

    // يقرأ من المساحة المشتركة، وداخل التطبيق يعيد الرسم فور الضغط على الزر
    @AppStorage private var storedCount: Int
    @AppStorage private var storedDay: String

    init(dhikr: TasbeehDhikr = .istighfar, date: Date = .now) {
        self.dhikr = dhikr
        self.date = date
        _storedCount = AppStorage(wrappedValue: 0, dhikr.countKey, store: AppGroup.defaults)
        _storedDay = AppStorage(wrappedValue: "", dhikr.dayKey, store: AppGroup.defaults)
    }

    /// عدد اليوم فقط؛ إذا المحفوظ من يوم سابق نبدأ من صفر
    private var count: Int {
        storedDay == TasbeehCounter.dayID(for: date) ? storedCount : 0
    }

    private var isComplete: Bool {
        dhikr.goal.map { count >= $0 } ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dhikr.title)
                Spacer()
                Text(goalLabel)
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)
            .lineLimit(1)

            Spacer(minLength: 0)
            Text(dhikr.text)
                .font(style.font(.textBold, dhikr.isLong ? 14 : 24))
                .foregroundStyle(style.primary)
                .lineLimit(dhikr.isLong ? 4 : 1)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: dhikr.isLong)
                .widgetAccentable()
            if let goal = dhikr.goal {
                ProgressView(value: Double(min(count, goal)), total: Double(goal))
                    .tint(style.accent)
                    .widgetAccentable()
            }

            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(style.number(count))
                        .font(style.font(.number, 24))
                        .foregroundStyle(style.primary)
                        .contentTransition(.numericText(value: Double(count)))
                        .widgetAccentable()
                    if isComplete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(style.accent)
                            .widgetAccentable()
                    } else if let goal = dhikr.goal {
                        Text("/ \(style.number(goal))")
                            .font(style.font(.label, 11))
                            .foregroundStyle(style.secondary)
                    }
                }
                Spacer()
                // Button(intent:) يشتغل من الشاشة الرئيسية بدون فتح التطبيق
                Button(intent: IncrementIstighfarIntent(dhikr: dhikr)) {
                    plusButton
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dhikr.title)
            }
        }
        .widgetContent()
    }

    private var goalLabel: String {
        switch dhikr.goal {
        case nil:  "عدد مفتوح"
        case 1:    "مرة واحدة"
        case let goal?: "\(style.number(goal)) مرة"
        }
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
