//
//  FinanceWidgets.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - التزاماتي
struct ObligationsWidget: View {
    let date: Date
    var size: WidgetSize = .medium
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let items = ObligationStore.upcoming(from: date)
        if items.isEmpty {
            empty
        } else if size == .small, let first = items.first {
            small(first.obligation, first.date)
        } else {
            list(Array(items.prefix(size == .large ? 6 : 3)))
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "list.bullet.rectangle.portrait.fill")
                .font(.system(size: 12))
                .foregroundStyle(style.accent)
                .widgetAccentable()
            Text("التزاماتي")
            Spacer()
        }
        .font(style.font(.label, 11))
        .foregroundStyle(style.secondary)
    }

    private var empty: some View {
        VStack(alignment: .leading) {
            header
            Spacer()
            Text("أضف إيجارك وأقساطك من التطبيق")
                .font(style.font(.label, 13))
                .foregroundStyle(style.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .widgetContent()
    }

    private func days(to target: Date) -> Int {
        DateHelper.gregorian.dateComponents([.day], from: DateHelper.gregorian.startOfDay(for: date), to: target).day ?? 0
    }

    private func small(_ item: Obligation, _ due: Date) -> some View {
        let days = days(to: due)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: item.type.symbol)
                    .font(.system(size: 12))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
                Text(item.displayName).lineLimit(1)
                Spacer(minLength: 0)
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)
            Spacer(minLength: 0)
            Text(days == 0 ? "اليوم" : style.number(days))
                .font(days == 0 ? style.font(.textBold, 32) : style.font(.number, 46))
                .foregroundStyle(style.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .widgetAccentable()
            Text(days == 0 ? "موعد الدفع" : PaydayFormat.unit(days))
                .font(style.font(.label, 12))
                .foregroundStyle(style.secondary)
            Spacer(minLength: 0)
            if item.amount > 0, Payday.showsAmount {
                Text(style.text(PaydayFormat.amount(item.amount)))
                    .font(style.font(.labelBold, 12))
                    .foregroundStyle(style.accent)
                    .widgetAccentable()
            }
            Text(style.text(DateHelper.weekdayDayMonth(due)))
                .font(style.font(.label, 11))
                .foregroundStyle(style.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .widgetContent()
    }

    private func list(_ items: [(obligation: Obligation, date: Date)]) -> some View {
        let total = size == .large ? monthTotal : nil
        return VStack(alignment: .leading, spacing: size == .large ? 8 : 6) {
            HStack(spacing: 4) {
                header
                if let total, total > 0 {
                    Text(style.text("هذا الشهر \(PaydayFormat.amount(total))"))
                        .font(style.font(.labelBold, 11))
                        .foregroundStyle(style.accent)
                        .widgetAccentable()
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.obligation.id) { index, entry in
                row(entry.obligation, entry.date, isFirst: index == 0)
            }
            // الصفوف بارتفاعها، والمساحة الباقية أسفلها
            Spacer(minLength: 0)
        }
        .widgetContent(padding: size == .large ? 16 : 12)
    }

    /// مجموع ما بقي من التزامات حتى نهاية الشهر
    private var monthTotal: Int {
        let calendar = DateHelper.gregorian
        guard let end = calendar.dateInterval(of: .month, for: date)?.end else { return 0 }
        return ObligationStore.total(from: date, to: end)
    }

    private func row(_ item: Obligation, _ due: Date, isFirst: Bool) -> some View {
        let days = days(to: due)
        return HStack(spacing: 8) {
            Image(systemName: item.type.symbol)
                .font(.system(size: 13))
                .foregroundStyle(style.accent)
                .widgetAccentable()
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(style.font(.labelBold, 13))
                    .foregroundStyle(style.primary)
                Text(style.text(subtitle(item, due)))
                    .font(style.font(.label, 11))
                    .foregroundStyle(style.secondary)
            }
            Spacer(minLength: 4)
            Text(style.text(PaydayFormat.remaining(days)))
                .font(style.font(isFirst ? .labelBold : .label, 12))
                .foregroundStyle(isFirst ? style.accent : style.primary)
                .widgetAccentable(isFirst)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
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

    /// «الخميس ٢٦ نوفمبر · ١٬٢٠٠ ر.س · باقي ٨ أقساط»
    private func subtitle(_ item: Obligation, _ due: Date) -> String {
        var parts = [DateHelper.weekdayDayMonth(due)]
        if item.amount > 0, Payday.showsAmount { parts.append(PaydayFormat.amount(item.amount)) }
        if size == .large, let count = item.remainingCount(from: date) {
            parts.append(count == 1 ? "آخر دفعة" : "باقي \(DateHelper.arabic(count))")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - مصروف اليوم
struct BudgetWidget: View {
    let date: Date
    var size: WidgetSize = .small
    @Environment(\.widgetStyle) private var style

    var body: some View {
        if let status = Budget.status(at: date) {
            if size == .small { small(status) } else { medium(status) }
        } else {
            VStack(alignment: .leading) {
                header
                Spacer()
                Text("أدخل رصيدك من التطبيق، ونحسب لك مصروف كل يوم حتى الراتب")
                    .font(style.font(.label, 12))
                    .foregroundStyle(style.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Spacer()
            }
            .widgetContent()
        }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Image(systemName: "wallet.bifold.fill")
                .font(.system(size: 12))
                .foregroundStyle(style.accent)
                .widgetAccentable()
            Text("مصروف اليوم")
            Spacer()
        }
        .font(style.font(.label, 11))
        .foregroundStyle(style.secondary)
    }

    private func leftText(_ status: BudgetStatus, size: CGFloat) -> some View {
        Text(style.number(abs(status.leftToday)))
            .font(style.font(.number, size))
            .foregroundStyle(status.isOver ? Color.red : style.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .widgetAccentable()
    }

    private func leftLabel(_ status: BudgetStatus) -> String {
        if status.needsUpdate { return "نزل الراتب؟ حدّث رصيدك" }
        return status.isOver ? "ر.س تجاوزت حصة اليوم" : "ر.س باقي لليوم"
    }

    private func spendButton(_ amount: Int, compact: Bool = false) -> some View {
        Button(intent: SpendIntent(amount: amount)) {
            Text(style.text("−\(DateHelper.arabic(amount))"))
                .font(style.font(.labelBold, compact ? 12 : 13))
                .foregroundStyle(style.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 6 : 7)
                .background(style.primary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("صرفت \(amount) ريال")
    }

    private func small(_ status: BudgetStatus) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            header
            Spacer(minLength: 0)
            leftText(status, size: 38)
            Text(leftLabel(status))
                .font(style.font(.label, 11))
                .foregroundStyle(status.needsUpdate ? style.accent : style.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ProgressView(value: status.progress)
                .tint(status.isOver ? .red : style.accent)
                .widgetAccentable()
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                spendButton(Budget.smallStep, compact: true)
                spendButton(Budget.largeStep, compact: true)
            }
        }
        .widgetContent(padding: 12)
    }

    // الباقي لليوم في جهة، وتفاصيل الرصيد في الأخرى، وأزرار المصروف أسفل
    private func medium(_ status: BudgetStatus) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                header
                Text(style.text("\(status.payday.displayName) \(PaydayFormat.remaining(status.days))"))
                    .font(style.font(.label, 11))
                    .foregroundStyle(style.secondary)
            }
            Spacer(minLength: 0)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    leftText(status, size: 40)
                    Text(leftLabel(status))
                        .font(style.font(.label, 11))
                        .foregroundStyle(status.needsUpdate ? style.accent : style.secondary)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 3) {
                    detail("حصة اليوم", status.daily)
                    detail("الرصيد", status.balance)
                    if status.obligations > 0 {
                        detail("التزامات قبل الراتب", status.obligations)
                    }
                }
            }
            Spacer(minLength: 0)
            ProgressView(value: status.progress)
                .tint(status.isOver ? .red : style.accent)
                .widgetAccentable()
                .padding(.bottom, 8)
            HStack(spacing: 8) {
                spendButton(Budget.smallStep)
                spendButton(Budget.largeStep)
                spendButton(Budget.largeStep * 5)
            }
        }
        .widgetContent(padding: 12)
    }

    private func detail(_ title: String, _ value: Int) -> some View {
        HStack(spacing: 4) {
            Text(title).foregroundStyle(style.secondary)
            Text(style.text(PaydayFormat.amount(value))).foregroundStyle(style.primary)
        }
        .font(style.font(.label, 11))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

// MARK: - شاشة القفل
struct ObligationsLockView: View {
    let date: Date
    let family: WidgetFamily
    var style: WidgetStyle = .default

    var body: some View {
        let items = ObligationStore.upcoming(from: date)
        let today = DateHelper.gregorian.startOfDay(for: date)
        let days = { (due: Date) in DateHelper.gregorian.dateComponents([.day], from: today, to: due).day ?? 0 }
        if family == .accessoryInline {
            if let first = items.first {
                Label(LockText.inline(style.text("\(first.obligation.displayName) \(PaydayFormat.remaining(days(first.date)))")),
                      systemImage: first.obligation.type.symbol)
            } else {
                Label("لا التزامات", systemImage: "checkmark.circle")
            }
        } else {
            VStack(alignment: .leading, spacing: 1) {
                if items.isEmpty {
                    Label("التزاماتي", systemImage: "list.bullet").font(style.font(.labelBold, 13))
                    Text("لا التزامات قادمة").font(style.font(.label, 12)).foregroundStyle(.secondary)
                }
                ForEach(Array(items.prefix(3).enumerated()), id: \.element.obligation.id) { index, entry in
                    HStack(spacing: 4) {
                        Image(systemName: entry.obligation.type.symbol).font(.system(size: 10)).frame(width: 14)
                        Text(entry.obligation.displayName)
                        Spacer(minLength: 2)
                        Text(style.text(PaydayFormat.remaining(days(entry.date))))
                    }
                    .font(style.font(index == 0 ? .labelBold : .label, 12))
                    .foregroundStyle(index == 0 ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// شاشة القفل تعرض الباقي لليوم فقط، بلا رصيد ولا أزرار
struct BudgetLockView: View {
    let date: Date
    let family: WidgetFamily
    var style: WidgetStyle = .default

    var body: some View {
        if let status = Budget.status(at: date) {
            switch family {
            case .accessoryInline:
                Label(LockText.inline(style.text(status.isOver
                                                 ? "تجاوزت حصة اليوم بـ \(DateHelper.arabic(-status.leftToday))"
                                                 : "باقي لليوم \(DateHelper.arabic(status.leftToday)) ر.س")),
                      systemImage: "wallet.bifold")
            case .accessoryCircular:
                Gauge(value: 1 - status.progress) { EmptyView() } currentValueLabel: {
                    VStack(spacing: 0) {
                        Image(systemName: "wallet.bifold").font(.system(size: 9))
                        Text(style.number(abs(status.leftToday)))
                            .font(style.font(.number, 15))
                            .minimumScaleFactor(0.5)
                        Text(status.isOver ? "تجاوز" : "باقي").font(style.font(.label, 8))
                    }
                }
                .gaugeStyle(.accessoryCircularCapacity)
            default:
                VStack(alignment: .leading, spacing: 1) {
                    Label("مصروف اليوم", systemImage: "wallet.bifold")
                        .font(style.font(.labelBold, 13))
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(style.number(abs(status.leftToday))).font(style.font(.number, 22))
                        Text(status.isOver ? "تجاوزت" : "ر.س باقي")
                            .font(style.font(.label, 11))
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: status.progress)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Label("أدخل رصيدك", systemImage: "wallet.bifold")
        }
    }
}
