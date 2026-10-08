//
//  HijriDateWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - التاريخ الهجري
struct HijriDateWidget: View {
    let date: Date
    var size: WidgetSize = .medium

    var body: some View {
        if size == .small { small } else { medium }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(icon: .system("moon"), title: "التاريخ الهجري")
            Spacer()
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    monthCalligraphy(height: 52)
                    Text("\(DateHelper.hijriYear(date)) هـ · \(DateHelper.weekday(date))")
                        .font(AppFont.ui(11))
                        .foregroundStyle(Theme.gold)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(DateHelper.hijriDay(date))
                        .font(AppFont.number(52))
                        .foregroundStyle(Theme.textPrimary)
                    Text(DateHelper.gregorianFull(date))
                        .font(AppFont.ui(11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
        .widgetContent()
    }

    // التصميم ٠٨: السنة أعلى، اليوم كبير، والشهر بالخط تحته
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "moon")
                Spacer()
                Text("\(DateHelper.hijriYear(date)) هـ")
            }
            .font(AppFont.uiBold(11))
            .foregroundStyle(Theme.gold)

            Spacer(minLength: 0)
            Text(DateHelper.hijriDay(date))
                .font(AppFont.number(52))
                .foregroundStyle(Theme.textPrimary)
            monthCalligraphy(height: 36)
        }
        .widgetContent()
    }

    private func monthCalligraphy(height: CGFloat) -> some View {
        Image(Calligraphy.hijriMonth(for: date))
            .calligraphy(height: height)
            .foregroundStyle(Theme.textPrimary)
            .accessibilityLabel(DateHelper.hijriMonth(date))
    }
}
