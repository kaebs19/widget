//
//  PaydayWidgets.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - موعد دفعة واحدة (الراتب، حساب المواطن، حافز، التقاعد)
struct PaydayWidget: View {
    let payday: Payday
    let date: Date
    var size: WidgetSize = .small
    @Environment(\.widgetStyle) private var style

    private var cycle: PaydayCycle { payday.cycle(from: date) }

    var body: some View {
        if size == .small { small } else { medium }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: payday.symbol)
                .font(.system(size: 12))
                .foregroundStyle(style.accent)
                .widgetAccentable()
            Text(payday.displayName)
                .lineLimit(1)
            Spacer(minLength: 4)
        }
        .font(style.font(.label, 11))
        .foregroundStyle(style.secondary)
    }

    private var small: some View {
        let cycle = cycle
        return VStack(alignment: .leading, spacing: 4) {
            header
            Spacer(minLength: 0)
            PaydayDays(days: cycle.days, size: 46)
            Text(cycle.isToday ? "موعد الصرف" : PaydayFormat.unit(cycle.days))
                .font(style.font(.label, 12))
                .foregroundStyle(style.secondary)
            ProgressView(value: cycle.progress)
                .tint(style.accent)
                .widgetAccentable()
                .padding(.top, 4)
            Spacer(minLength: 0)
            Text(style.text(DateHelper.weekdayDayMonth(cycle.next)))
                .font(style.font(.labelBold, 11))
                .foregroundStyle(style.accent)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .widgetContent()
    }

    // العدد كبير في جهة، والتاريخ والمبلغ في الأخرى، وشريط الشهر أسفل
    private var medium: some View {
        let cycle = cycle
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                header
                if let note = cycle.note {
                    Text(note)
                        .font(style.font(.label, 10))
                        .foregroundStyle(style.secondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(style.primary.opacity(0.1), in: Capsule())
                }
            }

            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(style.text(DateHelper.weekdayDayMonth(cycle.next)))
                        .font(style.font(.textBold, 20))
                        .foregroundStyle(style.primary)
                    if payday.amount > 0, Payday.showsAmount {
                        Text(style.text(PaydayFormat.amount(payday.amount)))
                            .font(style.font(.labelBold, 13))
                            .foregroundStyle(style.accent)
                            .widgetAccentable()
                    } else {
                        Text(cycle.isToday ? "موعد الصرف اليوم" : "موعد \(payday.displayName) القادم")
                            .font(style.font(.label, 12))
                            .foregroundStyle(style.secondary)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                Spacer(minLength: 8)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    PaydayDays(days: cycle.days, size: 46, isAccent: true)
                    if !cycle.isToday {
                        Text(PaydayFormat.unit(cycle.days, remaining: false)).font(style.font(.label, 12)).foregroundStyle(style.secondary)
                    }
                }
            }
            Spacer(minLength: 0)

            ProgressView(value: cycle.progress)
                .tint(style.accent)
                .widgetAccentable()
            HStack {
                Text(style.text("السابق \(DateHelper.gregorianDayMonth(cycle.previous))"))
                Spacer()
                Text(style.text("مضى \(DateHelper.arabic(Int((cycle.progress * 100).rounded())))٪"))
            }
            .font(style.font(.label, 10))
            .foregroundStyle(style.secondary)
            .padding(.top, 4)
        }
        .widgetContent()
    }
}

/// عدد الأيام بخط كبير، أو «اليوم» في يوم الصرف
private struct PaydayDays: View {
    let days: Int
    let size: CGFloat
    var isAccent = false
    @Environment(\.widgetStyle) private var style

    var body: some View {
        Text(days == 0 ? "اليوم" : style.number(days))
            .font(days == 0 ? style.font(.textBold, size * 0.7) : style.font(.number, size))
            .foregroundStyle(isAccent ? style.accent : style.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetAccentable()
    }
}

// MARK: - مواعيد الصرف (كل الدفعات)
struct PaydaysWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    /// الدفعات المختارة في الإعدادات، الأقرب أولاً
    private var cycles: [PaydayCycle] {
        Payday.allCases.filter(\.isListed).map { $0.cycle(from: date) }.sorted { $0.next < $1.next }
    }

    var body: some View {
        // المتوسط يتسع لأربع دفعات والكبير لست
        let cycles = Array(cycles.prefix(size == .large ? 6 : 4))
        VStack(alignment: .leading, spacing: size == .large ? 10 : 6) {
            HStack(spacing: 4) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 12))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text("مواعيد الصرف")
                Spacer()
                Text(style.text(DateHelper.gregorianMonthName(date)))
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)

            if cycles.isEmpty {
                Spacer()
                Text("اختر الدفعات من الإعدادات")
                    .font(style.font(.label, 13))
                    .foregroundStyle(style.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(cycles, id: \.payday) { cycle in
                    row(cycle, isFirst: cycle.payday == cycles.first?.payday)
                }
                // الصفوف بارتفاعها، والمساحة الباقية أسفلها
            Spacer(minLength: 0)
            }
        }
        .widgetContent(padding: size == .large ? 16 : 12)
    }

    private func row(_ cycle: PaydayCycle, isFirst: Bool) -> some View {
        let payday = cycle.payday
        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: payday.symbol)
                    .font(.system(size: 13))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(payday.displayName)
                        .font(style.font(.labelBold, 13))
                        .foregroundStyle(style.primary)
                    if size == .large {
                        Text(style.text(subtitle(cycle)))
                            .font(style.font(.label, 11))
                            .foregroundStyle(style.secondary)
                    }
                }
                Spacer(minLength: 4)
                if size != .large {
                    Text(style.text(DateHelper.weekdayDayMonth(cycle.next)))
                        .font(style.font(.label, 11))
                        .foregroundStyle(style.secondary)
                }
                Text(style.text(PaydayFormat.remaining(cycle.days)))
                    .font(style.font(isFirst ? .labelBold : .label, 12))
                    .foregroundStyle(isFirst ? style.accent : style.primary)
                    .widgetAccentable(isFirst)
                    .frame(minWidth: 62, alignment: .trailing)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            if size == .large {
                ProgressView(value: cycle.progress)
                    .tint(style.accent)
                    .widgetAccentable()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, size == .large ? 8 : 6)
        .background {
            if isFirst {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(style.primary.opacity(0.12))
                    .widgetAccentable()
            }
        }
    }

    /// «الخميس ٢٦ نوفمبر · ٨٬٥٠٠ ر.س»
    private func subtitle(_ cycle: PaydayCycle) -> String {
        var parts = [DateHelper.weekdayDayMonth(cycle.next)]
        if cycle.payday.amount > 0, Payday.showsAmount { parts.append(PaydayFormat.amount(cycle.payday.amount)) }
        if let eid = cycle.eid { parts.append("قد يُقدَّم قبل \(eid)") }
        return parts.joined(separator: " · ")
    }
}
