//
//  IstighfarWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import AppIntents
import SwiftUI

// MARK: - الاستغفار
struct IstighfarWidget: View {
    var date: Date = .now

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
            .font(AppFont.ui(11))
            .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 0)
            Text("أستغفر الله")
                .font(AppFont.zikrBold(24))
                .foregroundStyle(Theme.textPrimary)
            ProgressView(value: Double(min(count, goal)), total: Double(goal))
                .tint(Theme.gold)

            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(DateHelper.arabic(count))
                        .font(AppFont.number(24))
                        .foregroundStyle(Theme.textPrimary)
                        .contentTransition(.numericText(value: Double(count)))
                    Text("/ \(DateHelper.arabic(goal))")
                        .font(AppFont.ui(11))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                // Button(intent:) يشتغل من الشاشة الرئيسية بدون فتح التطبيق
                Button(intent: IncrementIstighfarIntent()) {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 40, height: 40)
                        .background(Theme.cream, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("استغفار")
            }
        }
        .widgetContent()
    }
}
