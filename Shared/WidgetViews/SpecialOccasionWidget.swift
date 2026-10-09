//
//  SpecialOccasionWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - مناسبة خاصة
// الاسم والتاريخ يختارهما المستخدم من «تعديل الودجت» (التصميم ١٦)
struct SpecialOccasionWidget: View {
    let name: String
    /// التاريخ كما اختاره المستخدم؛ nil إذا لم يحدده بعد
    let occasionDate: Date?
    var repeatsYearly = true
    var date: Date = .now
    /// نوع المناسبة المحفوظة في التطبيق: يحدد الأيقونة والعنوان، ويُحسب العمر للميلاد
    var type: OccasionType? = nil
    @Environment(\.widgetStyle) private var style

    /// موعد المناسبة القادم (لو تتكرر سنوياً ومضت، ننتقل للسنة القادمة)
    private var target: Date? {
        occasionDate.map { DateHelper.nextOccurrence(of: $0, repeatsYearly: repeatsYearly, from: date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(icon: type.map { .system($0.symbol) } ?? .asset(.iconCategoryOccasions),
                         title: type?.title ?? "مناسبة خاصة",
                         trailing: target.map { DateHelper.weekdayDayMonth($0) })
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(style.font(.title, 30))
                        .foregroundStyle(style.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                    if let yearsLabel {
                        Text(style.text(yearsLabel))
                            .font(style.font(.labelBold, 12))
                            .foregroundStyle(style.accent)
                            .widgetAccentable()
                    }
                }
                Spacer(minLength: 8)
                countdown
            }
            Spacer(minLength: 0)
        }
        .widgetContent()
    }

    /// «يكمل ٣٠ سنة» للميلاد، «الذكرى ١٠» للزواج
    private var yearsLabel: String? {
        guard let type, type.countsYears, repeatsYearly, let occasionDate, let target else { return nil }
        let calendar = DateHelper.gregorian
        let years = calendar.component(.year, from: target) - calendar.component(.year, from: occasionDate)
        guard years > 0 else { return nil }
        return type == .birthday ? "يكمل \(DateHelper.arabic(years)) سنة" : "الذكرى \(DateHelper.arabic(years))"
    }

    @ViewBuilder
    private var countdown: some View {
        if let target {
            if target <= date {
                Text("اليوم")
                    .font(style.font(.textBold, 24))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
            } else {
                let remaining = DateHelper.countdown(to: target, from: date)
                tile(style.number(remaining.days), unit: "يوم", accent: false)
                tile(style.text(DateHelper.arabicTwoDigits(remaining.hours)), unit: "ساعة", accent: true)
            }
        } else {
            Text("اضغط مطولاً ثم «تعديل الودجت» لاختيار التاريخ")
                .font(style.font(.label, 11))
                .foregroundStyle(style.secondary)
                .frame(maxWidth: 130)
        }
    }

    private func tile(_ value: String, unit: String, accent: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return VStack(spacing: 2) {
            Text(value)
                .font(style.font(.number, 22))
                .foregroundStyle(accent ? style.accent : style.primary)
            Text(unit)
                .font(style.font(.label, 11))
                .foregroundStyle(style.secondary)
        }
        .frame(width: 58, height: 58)
        .background(accent ? style.accent.opacity(0.12) : style.primary.opacity(0.06), in: shape)
        .overlay(shape.strokeBorder(accent ? style.accent.opacity(0.4) : style.primary.opacity(0.1)))
        .widgetAccentable(accent)
    }
}
