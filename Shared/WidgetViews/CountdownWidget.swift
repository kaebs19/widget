//
//  CountdownWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - عداد المناسبات (قالب واحد لكل المناسبات)
struct CountdownWidget: View {
    let title: String
    let icon: AppIcon
    let days: Int
    /// اسم المناسبة بخط كبير (يوم التأسيس). بدونه يكون العدد هو الأبرز (رمضان).
    var name: String? = nil
    /// كم مضى من الانتظار (٠ إلى ١)، يظهر شريطاً تحت العدد
    var progress: Double? = nil
    var footnote: String? = nil
    var footnoteIsAccent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                AppIconView(icon: icon, size: 15).foregroundStyle(Theme.gold)
            }
            .font(AppFont.ui(11))
            .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 0)
            if let name {
                Text(name)
                    .font(AppFont.zikrBold(22))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    daysText(size: 38)
                    if days > 0 {
                        Text("يومًا").font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                daysText(size: 46)
                Text(days == 0 ? "كل عام وأنتم بخير" : "يومًا متبقيًا")
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            if let progress {
                ProgressView(value: progress)
                    .tint(Theme.gold)
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
            if let footnote {
                Text(footnote)
                    .font(footnoteIsAccent ? AppFont.uiBold(11) : AppFont.ui(11))
                    .foregroundStyle(footnoteIsAccent ? Theme.gold : Theme.textSecondary)
            }
        }
        .widgetContent()
    }

    private func daysText(size: CGFloat) -> some View {
        Text(days == 0 ? "اليوم" : DateHelper.arabic(days))
            .font(AppFont.number(size))
            .foregroundStyle(Theme.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}
