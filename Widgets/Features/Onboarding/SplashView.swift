//
//  SplashView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

// MARK: - شاشة البداية
// الكاملة لأول تشغيل (٤٫٥ ث وينتقل الشعار لرأس التعريف)، والقصيرة لكل تشغيل بعدها (١٫٧ ث).
// كل عنصر يُحسب من الزمن منذ الظهور حسب flows في ملف التصميم.
struct SplashView: View {
    enum Variant { case full, everyday }

    let variant: Variant
    /// الشعار يُرسم هنا حتى يطير لرأس التعريف؛ بعدها يخفيه `LaunchView`
    var showsLogo = true
    var logoNamespace: Namespace.ID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    private let ringRadius: CGFloat = 115
    private let logoSize: CGFloat = 96

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSince(start)
            GeometryReader { proxy in
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.42)
                ZStack {
                    if reduceMotion {
                        still(center)
                    } else if variant == .full {
                        full(t, center)
                    } else {
                        everyday(t, center)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: أول تشغيل
    @ViewBuilder
    private func full(_ t: Double, _ center: CGPoint) -> some View {
        let fadeOut = Ease.move(t, 3.7, 0.6)
        // الحلقة: ٠→٧٨٪ ثم تكتمل، وتدور ببطء ١٤° في الثانية
        let draw = Ease.enter(t, 0.4, 1.6) * 0.78 + Ease.move(t, 2.2, 1.4) * 0.22
        let pops = (0..<4).map { Ease.pop(t, 0.8 + Double($0) * 0.12, 0.5) }
        Circle()
            .fill(RadialGradient(colors: [OB.accent.opacity(0.19), .clear], center: .center,
                                 startRadius: 0, endRadius: 156))
            .frame(width: 520, height: 520)
            .opacity(0.5 * Ease.enter(t, 0.6, 1.5) * (1 - fadeOut))
            .position(center)
        ring(draw: draw, track: true)
            .rotationEffect(.degrees(t * 14))
            .scaleEffect(1 + Ease.move(t, 3.5, 0.6) * 0.15)
            .opacity(1 - Ease.move(t, 3.5, 0.5))
            .position(center)
        logo(pops: pops)
            .position(center)
        wordmark
            .opacity(Ease.enter(t, 1.7, 0.7) * (1 - fadeOut))
            .offset(y: (1 - Ease.enter(t, 1.7, 0.7)) * 24)
            .position(x: center.x, y: center.y + 180)
        Text(L10n.text("كل ما تحتاجه في لمحة"))
            .font(OB.font(18))
            .foregroundStyle(OB.muted)
            .opacity(Ease.enter(t, 2.2, 0.7) * (1 - fadeOut))
            .offset(y: (1 - Ease.enter(t, 2.2, 0.7)) * 16)
            .position(x: center.x, y: center.y + 228)
    }

    // MARK: كل تشغيل
    @ViewBuilder
    private func everyday(_ t: Double, _ center: CGPoint) -> some View {
        let out = Ease.move(t, 1.3, 0.4)
        let pops = (0..<4).map { Ease.pop(t, 0.2 + Double($0) * 0.06, 0.4) }
        ZStack {
            ring(draw: Ease.enter(t, 0.2, 1.0), track: false)
                .opacity(1 - Ease.move(t, 1.1, 0.4))
                .position(center)
            logo(pops: pops)
                .scaleEffect(1 - out * 0.2)
                .position(center)
            wordmark
                .opacity(Ease.enter(t, 0.45, 0.5))
                .position(x: center.x, y: center.y + 180)
        }
        .opacity(1 - out)
    }

    /// تقليل الحركة: بدون دوران ولا قفز، والانتقال تلاشٍ فقط
    private func still(_ center: CGPoint) -> some View {
        ZStack {
            logo(pops: [1, 1, 1, 1]).position(center)
            wordmark.position(x: center.x, y: center.y + 180)
        }
    }

    private func ring(draw: Double, track: Bool) -> some View {
        ZStack {
            if track {
                Circle().stroke(OB.line, lineWidth: 5)
            }
            Circle()
                .trim(from: 0, to: draw)
                .stroke(OB.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: ringRadius * 2, height: ringRadius * 2)
        // الحلقة تُرسم مع عقارب الساعة من الأعلى مهما كان اتجاه اللغة
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    private func logo(pops: [Double]) -> some View {
        if showsLogo {
            WidgetLogo(pops: pops)
                .frame(width: logoSize, height: logoSize)
                .matchedGeometryEffect(id: "logo", in: logoNamespace)
        } else {
            Color.clear.frame(width: logoSize, height: logoSize)
        }
    }

    private var wordmark: some View {
        Text(L10n.text("ويدجت"))
            .font(OB.font(46, .bold))
            .foregroundStyle(OB.text)
    }
}
