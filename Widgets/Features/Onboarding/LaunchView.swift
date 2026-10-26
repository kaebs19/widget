//
//  LaunchView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

// MARK: - مسار التشغيل
// أول مرة: شاشة البداية الكاملة ثم التعريف، والشعار ينتقل بينهما. بعدها: شاشة قصيرة ثم الودجات مباشرة.
struct LaunchView: View {
    private enum Stage { case splash, onboarding, home }

    /// شاشة البداية مرة واحدة لكل تشغيل، حتى لو أُعيد بناء الواجهة بعد تغيير لون التطبيق
    @MainActor private static var hasLaunched = false

    @State private var stage: Stage
    @State private var showsSplash: Bool
    private let isFirstLaunch: Bool
    @Namespace private var logo
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init() {
        let skip = Self.hasLaunched || ProcessInfo.processInfo.arguments.contains("-screenshots")
        isFirstLaunch = !AppGroup.defaults.bool(forKey: AppSettings.Key.onboardingCompleted)
            && !ProcessInfo.processInfo.arguments.contains("-screenshots")
        _stage = State(initialValue: skip ? (isFirstLaunch ? .onboarding : .home) : (isFirstLaunch ? .splash : .home))
        _showsSplash = State(initialValue: !skip)
        Self.hasLaunched = true
    }

    var body: some View {
        ZStack {
            switch stage {
            case .home:
                HomeView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(logoNamespace: logo, showsLogo: true) {
                    withAnimation(OB.move(0.75)) { stage = .home }
                }
                .transition(.asymmetric(insertion: .identity, removal: .opacity))
            case .splash:
                OB.background.ignoresSafeArea()
            }
            if showsSplash {
                if !isFirstLaunch {
                    OB.background.ignoresSafeArea().transition(.opacity)
                }
                SplashView(variant: isFirstLaunch ? .full : .everyday,
                           showsLogo: stage == .splash || !isFirstLaunch,
                           logoNamespace: logo)
                    .transition(.opacity)
            }
        }
        .task { await runSplash() }
    }

    private func runSplash() async {
        guard showsSplash else { return }
        if isFirstLaunch {
            // الشعار يطير لرأس التعريف عند ٣٫٧ ث، وبقية الشاشة تتلاشى بعدها
            try? await Task.sleep(for: .seconds(reduceMotion ? 1 : 3.7))
            withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : OB.move(0.9)) { stage = .onboarding }
            try? await Task.sleep(for: .seconds(0.9))
            showsSplash = false
        } else {
            // الودجات تُبنى خلف الشاشة القصيرة، فتظهر جاهزة عند التلاشي
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.3))
            withAnimation(OB.move(0.4)) { showsSplash = false }
        }
    }
}
