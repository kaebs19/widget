//
//  YearDotsWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

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
                    .widgetAccentable()
            }
            .font(style.font(.labelBold, 14))

            // Canvas يرسم كل النقاط في مرة وحدة، وأخف بكثير من ٣٦٥ Circle منفصلة.
            // نقطة اليوم في طبقة منفصلة حتى تأخذ لون التمييز في الوضع الملوّن
            Canvas { ctx, size in
                let grid = DotGrid(size: size, totalDays: progress.totalDays)
                for i in 0..<progress.totalDays where i != progress.dayOfYear - 1 {
                    ctx.fill(grid.dot(i), with: .color(i < progress.dayOfYear ? passed : upcoming))
                }
            }
            .overlay {
                Canvas { ctx, size in
                    let grid = DotGrid(size: size, totalDays: progress.totalDays)
                    ctx.fill(grid.dot(progress.dayOfYear - 1, scale: 1.6), with: .color(today))
                }
                .widgetAccentable()
            }
        }
        .widgetContent()
    }
}

/// مواقع النقاط: ٣٧ عموداً، والتعبئة تبدأ من اليمين (RTL)
private struct DotGrid {
    let columns = 37
    let cellW: CGFloat
    let cellH: CGFloat
    let radius: CGFloat

    init(size: CGSize, totalDays: Int) {
        let rows = Int(ceil(Double(totalDays) / Double(columns)))
        cellW = size.width / CGFloat(columns)
        cellH = size.height / CGFloat(rows)
        radius = min(cellW, cellH) * 0.3
    }

    func dot(_ index: Int, scale: CGFloat = 1) -> Path {
        let column = columns - 1 - (index % columns)
        let x = (CGFloat(column) + 0.5) * cellW
        let y = (CGFloat(index / columns) + 0.5) * cellH
        let r = radius * scale
        return Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
}
