//
//  YearDotsWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - نقاط السنة
struct YearDotsWidget: View {
    let date: Date
    @Environment(\.widgetStyle) private var style

    var body: some View {
        let progress = DateHelper.yearProgress(date)
        // Canvas ما يقرأ البيئة، فنمرر الألوان جاهزة
        let today = style.accent, passed = style.primary, upcoming = style.primary.opacity(0.18)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(style.number(DateHelper.gregorian.component(.year, from: date)))
                    .foregroundStyle(style.secondary)
                Spacer()
                Text(style.text("٪\(DateHelper.arabic(progress.percent))"))
                    .foregroundStyle(style.accent)
            }
            .font(style.font(.labelBold, 14))

            // Canvas يرسم كل النقاط في مرة وحدة، وأخف بكثير من ٣٦٥ Circle منفصلة
            Canvas { ctx, size in
                let columns = 37
                let rows = Int(ceil(Double(progress.totalDays) / Double(columns)))
                let cellW = size.width / CGFloat(columns)
                let cellH = size.height / CGFloat(rows)
                let radius = min(cellW, cellH) * 0.3

                for i in 0..<progress.totalDays {
                    // نعكس العمود عشان التعبئة تبدأ من اليمين (RTL)
                    let column = columns - 1 - (i % columns)
                    let x = (CGFloat(column) + 0.5) * cellW
                    let y = (CGFloat(i / columns) + 0.5) * cellH

                    let isToday = i == progress.dayOfYear - 1
                    let r = isToday ? radius * 1.6 : radius
                    let color = isToday ? today : (i < progress.dayOfYear ? passed : upcoming)

                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(color))
                }
            }
        }
        .widgetContent()
    }
}
