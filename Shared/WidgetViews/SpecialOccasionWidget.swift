//
//  SpecialOccasionWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - مناسبة خاصة
// الاسم والتاريخ يختارهما المستخدم من «تعديل الودجت» (التصميم ١٦)
struct SpecialOccasionWidget: View {
    let name: String
    /// التاريخ كما اختاره المستخدم؛ nil إذا لم يحدده بعد
    let occasionDate: Date?
    var repeatsYearly = true
    var date: Date = .now

    /// موعد المناسبة القادم (لو تتكرر سنوياً ومضت، ننتقل للسنة القادمة)
    private var target: Date? {
        occasionDate.map { DateHelper.nextOccurrence(of: $0, repeatsYearly: repeatsYearly, from: date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(icon: .asset(.iconCategoryOccasions), title: "مناسبة خاصة",
                         trailing: target.map { DateHelper.weekdayDayMonth($0) })
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                Text(name)
                    .font(AppFont.zikrBold(30))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                countdown
            }
            Spacer(minLength: 0)
        }
        .widgetContent()
    }

    @ViewBuilder
    private var countdown: some View {
        if let target {
            if target <= date {
                Text("اليوم")
                    .font(AppFont.zikrBold(24))
                    .foregroundStyle(Theme.gold)
            } else {
                let remaining = DateHelper.countdown(to: target, from: date)
                tile(DateHelper.arabic(remaining.days), unit: "يوم", accent: false)
                tile(DateHelper.arabicTwoDigits(remaining.hours), unit: "ساعة", accent: true)
            }
        } else {
            Text("اضغط مطولاً ثم «تعديل الودجت» لاختيار التاريخ")
                .font(AppFont.ui(11))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: 130)
        }
    }

    private func tile(_ value: String, unit: String, accent: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return VStack(spacing: 2) {
            Text(value)
                .font(AppFont.number(22))
                .foregroundStyle(accent ? Theme.gold : Theme.textPrimary)
            Text(unit)
                .font(AppFont.ui(11))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(width: 58, height: 58)
        .background(accent ? Theme.gold.opacity(0.12) : Color.white.opacity(0.06), in: shape)
        .overlay(shape.strokeBorder(accent ? Theme.gold.opacity(0.4) : Theme.border))
    }
}
