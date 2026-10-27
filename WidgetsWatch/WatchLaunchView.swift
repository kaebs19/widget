//
//  WatchLaunchView.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

// MARK: - مسار التشغيل
// أول مرة: شاشة البداية ثم التعريف والشعار ينتقل لأعلى الشاشة. بعدها: شاشة قصيرة ثم الأوقات.
struct WatchLaunchView: View {
    private enum Stage { case splash, onboarding, home }

    @State private var stage: Stage
    @State private var showsSplash = true
    private let isFirstLaunch = !AppGroup.defaults.bool(forKey: AppSettings.Key.onboardingCompleted)
    @Namespace private var logo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        _stage = State(initialValue: AppGroup.defaults.bool(forKey: AppSettings.Key.onboardingCompleted) ? .home : .splash)
    }

    var body: some View {
        ZStack {
            W.background.ignoresSafeArea()
            switch stage {
            case .home:
                // الصلاة أولاً، ثم العدّاد والتقويم بالسحب للأسفل
                TabView {
                    WatchHomeView()
                    NavigationStack { WatchTasbeehView() }
                    WatchCalendarView()
                }
                .tabViewStyle(.verticalPage)
                .transition(.opacity)
            case .onboarding:
                WatchOnboardingView(logoNamespace: logo) {
                    AppGroup.defaults.set(true, forKey: AppSettings.Key.onboardingCompleted)
                    withAnimation(W.move(0.75)) { stage = .home }
                }
                .transition(.asymmetric(insertion: .identity, removal: .opacity))
            case .splash:
                EmptyView()
            }
            if showsSplash {
                WatchSplashView(isFull: isFirstLaunch, showsLogo: stage == .splash || !isFirstLaunch, logoNamespace: logo)
                    .background(isFirstLaunch ? Color.clear : W.background)
                    .transition(.opacity)
            }
        }
        .task { await run() }
    }

    private func run() async {
        if isFirstLaunch {
            try? await Task.sleep(for: .seconds(reduceMotion ? 1 : 3.7))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : W.move(0.9)) { stage = .onboarding }
            try? await Task.sleep(for: .seconds(0.9))
            showsSplash = false
        } else {
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.3))
            withAnimation(W.move(0.4)) { showsSplash = false }
        }
    }
}

// MARK: - شاشة البداية
/// نفس توقيت شاشة الآيفون بمقاسات الساعة من ملف التصميم
struct WatchSplashView: View {
    let isFull: Bool
    var showsLogo = true
    var logoNamespace: Namespace.ID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date.now

    var body: some View {
        TimelineView(.animation) { context in
            let t = reduceMotion ? 3 : context.date.timeIntervalSince(start)
            GeometryReader { proxy in
                let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height * 0.41)
                if isFull { full(t, center) } else { everyday(t, center) }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func full(_ t: Double, _ center: CGPoint) -> some View {
        let fadeOut = Ease.move(t, 3.7, 0.6)
        let draw = Ease.enter(t, 0.4, 1.6) * 0.78 + Ease.move(t, 2.2, 1.4) * 0.22
        Circle()
            .fill(RadialGradient(colors: [W.accent().opacity(0.19), .clear], center: .center, startRadius: 0, endRadius: 46))
            .frame(width: 140, height: 140)
            .opacity(0.6 * Ease.enter(t, 0.6, 1.5) * (1 - fadeOut))
            .position(center)
        ring(draw: draw, track: true)
            .rotationEffect(.degrees(t * 14))
            .scaleEffect(1 + Ease.move(t, 3.5, 0.6) * 0.15)
            .opacity(1 - Ease.move(t, 3.5, 0.5))
            .position(center)
        logo((0..<4).map { Ease.pop(t, 0.8 + Double($0) * 0.12, 0.5) })
            .position(center)
        Text(L10n.text("ويدجت"))
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(W.text)
            .opacity(Ease.enter(t, 1.7, 0.7) * (1 - fadeOut))
            .position(x: center.x, y: center.y + 90)
        Text(L10n.text("كل ما تحتاجه في لمحة"))
            .font(.system(size: 11))
            .foregroundStyle(W.muted)
            .opacity(Ease.enter(t, 2.2, 0.7) * (1 - fadeOut))
            .position(x: center.x, y: center.y + 114)
    }

    private func everyday(_ t: Double, _ center: CGPoint) -> some View {
        let out = Ease.move(t, 1.3, 0.4)
        return ZStack {
            ring(draw: Ease.enter(t, 0.2, 1.0), track: false)
                .opacity(1 - Ease.move(t, 1.1, 0.4))
                .position(center)
            logo((0..<4).map { Ease.pop(t, 0.2 + Double($0) * 0.06, 0.4) })
                .scaleEffect(1 - out * 0.2)
                .position(center)
            Text(L10n.text("ويدجت"))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(W.text)
                .opacity(Ease.enter(t, 0.45, 0.5))
                .position(x: center.x, y: center.y + 90)
        }
        .opacity(1 - out)
    }

    private func ring(draw: Double, track: Bool) -> some View {
        ZStack {
            if track { Circle().stroke(Color(white: 0.14), lineWidth: 4) }
            Circle()
                .trim(from: 0, to: draw)
                .stroke(W.accent(), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 124, height: 124)
        // الحلقة تُرسم مع عقارب الساعة من الأعلى مهما كان اتجاه اللغة
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    private func logo(_ pops: [Double]) -> some View {
        if showsLogo {
            WatchLogo(pops: pops)
                .frame(width: 56, height: 56)
                .matchedGeometryEffect(id: "logo", in: logoNamespace)
        } else {
            Color.clear.frame(width: 56, height: 56)
        }
    }
}
