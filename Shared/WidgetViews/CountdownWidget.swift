//
//  CountdownWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

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
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(style.text(title))
                Spacer()
                AppIconView(icon: icon, size: 15).foregroundStyle(style.accent).widgetAccentable()
            }
            .font(style.font(.label, 11))
            .foregroundStyle(style.secondary)

            Spacer(minLength: 0)
            if let name {
                Text(style.text(name))
                    .font(style.font(.textBold, 22))
                    .foregroundStyle(style.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    daysText(size: 38)
                    if days > 0 {
                        Text("يومًا").font(style.font(.label, 12)).foregroundStyle(style.secondary)
                    }
                }
            } else {
                daysText(size: 46)
                Text(days == 0 ? "كل عام وأنتم بخير" : "يومًا متبقيًا")
                    .font(style.font(.label, 12))
                    .foregroundStyle(style.secondary)
            }
            if let progress {
                ProgressView(value: progress)
                    .tint(style.accent)
                    .widgetAccentable()
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
            if let footnote {
                Text(style.text(footnote))
                    .font(style.font(footnoteIsAccent ? .labelBold : .label, 11))
                    .foregroundStyle(footnoteIsAccent ? style.accent : style.secondary)
                    .widgetAccentable(footnoteIsAccent)
            }
        }
        .widgetContent()
    }

    private func daysText(size: CGFloat) -> some View {
        Text(days == 0 ? "اليوم" : style.number(days))
            .font(style.font(.number, size))
            .foregroundStyle(style.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .widgetAccentable()
    }
}
