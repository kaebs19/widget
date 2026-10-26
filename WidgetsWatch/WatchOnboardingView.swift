//
//  WatchOnboardingView.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

// MARK: - التعريف على الساعة
// ثلاث صفحات في كل منها عنوان ووصف وسطران، كما في تصميم الساعة. الاختيارات تُرسل للآيفون.
struct WatchOnboardingView: View {
    var logoNamespace: Namespace.ID
    let onFinish: () -> Void

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var progress = 0.0
    @State private var appeared = false
    @State private var locator = WatchLocator()
    @State private var autoLocation = false
    @State private var adhan = AppGroup.defaults.object(forKey: WatchKeys.notifyEnabled) as? Bool ?? true
    @State private var prePrayer = AppGroup.defaults.integer(forKey: WatchKeys.notifyBefore) > 0
    @State private var haptics = AppGroup.defaults.object(forKey: AppSettings.Key.haptics) as? Bool ?? true
    @State private var numerals = AppSettings.numerals
    @State private var showsSampleAlert = false

    private var isRTL: Bool { layoutDirection == .rightToLeft }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // الشعار يسار الشاشة في الاتجاهين، فالساعة في يمينها
            ZStack {
                WatchStepper(progress: progress)
                    .opacity(appeared ? 1 : 0)
                WatchLogo()
                    .frame(width: 16, height: 16)
                    .matchedGeometryEffect(id: "logo", in: logoNamespace)
                    .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
            }
            ZStack(alignment: .topLeading) {
                ForEach(0..<3, id: \.self) { index in
                    pageContent(index)
                        .allowsHitTesting(index == page)
                        .accessibilityHidden(index != page)
                }
            }
            .padding(.top, 8)
            Spacer(minLength: 6)
            Button(action: next) {
                HStack(spacing: 4) {
                    Text(page < 2 ? L10n.text("التالي") : L10n.text("ابدأ"))
                    Image(systemName: isRTL ? "arrow.left" : "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .buttonStyle(WatchPrimaryButtonStyle())
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 6)
        .overlay { if showsSampleAlert { sampleAlert } }
        .onAppear {
            withAnimation(W.enter(reduceMotion ? 0.2 : 0.8).delay(reduceMotion ? 0 : 0.4)) { appeared = true }
        }
        .onChange(of: autoLocation) { _, on in if on { locator.locate() } }
        .onChange(of: locator.isDenied) { _, denied in if denied { autoLocation = false } }
        .onChange(of: adhan) { saveNotifications() }
        .onChange(of: prePrayer) { _, on in
            saveNotifications()
            if on { showSample() }
        }
        .onChange(of: haptics) { _, on in WatchSession.shared.set(on, forKey: AppSettings.Key.haptics) }
        .onChange(of: numerals) { _, value in WatchSession.shared.set(value.rawValue, forKey: AppSettings.Key.numerals) }
    }

    @ViewBuilder
    private func pageContent(_ index: Int) -> some View {
        let distance = Double(index) - progress
        let shift = (distance * 40 + (appeared ? 0 : 20)) * (isRTL ? -1 : 1)
        let opacity = max(0, 1 - abs(distance) * 2.2) * (appeared ? 1 : 0)
        VStack(alignment: .leading, spacing: 0) {
            text(index)
                .offset(x: shift)
            VStack(spacing: 6) {
                rows(index)
            }
            .padding(.top, 10)
            .offset(x: shift * 1.3)
        }
        .opacity(opacity)
    }

    private func text(_ index: Int) -> some View {
        let copy: (title: String, body: String) = switch index {
        case 0: (L10n.text("الموقع"), L10n.text("لمواقيت صلاة دقيقة حسب مدينتك."))
        case 1: (L10n.text("التنبيهات"), L10n.text("اهتزاز خفيف مع كل تنبيه على معصمك."))
        default: (L10n.text("عام"), L10n.text("تفضيلات تنطبق على جميع الودجات."))
        }
        return VStack(alignment: .leading, spacing: 3) {
            Text(copy.title)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(W.text)
            Text(copy.body)
                .font(.system(size: 11))
                .foregroundStyle(W.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func rows(_ index: Int) -> some View {
        switch index {
        case 0:
            WatchRow(symbol: "location.circle", title: L10n.text("تلقائي")) { WatchToggle(isOn: $autoLocation) }
            WatchRow(symbol: locator.isLocating ? "dot.radiowaves.left.and.right" : "building.2", title: L10n.text("المدينة")) {
                Text(cityLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(locator.location == nil || locator.isLocating ? W.muted : W.accent())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        case 1:
            WatchRow(symbol: "bell.badge", title: L10n.text("الأذان")) { WatchToggle(isOn: $adhan) }
            WatchRow(symbol: "clock", title: L10n.text("قبل الصلاة")) { WatchToggle(isOn: $prePrayer) }
        default:
            WatchRow(symbol: "iphone.radiowaves.left.and.right", title: L10n.text("الاهتزاز")) { WatchToggle(isOn: $haptics) }
            WatchRow(symbol: "number", title: L10n.text("الأرقام")) {
                WatchSegmented(options: [("123", Numerals.latin), ("١٢٣", Numerals.arabic)], selection: $numerals)
            }
        }
    }

    private var cityLabel: String {
        if locator.isLocating { return L10n.text("جارٍ…") }
        if locator.isDenied && locator.location == nil { return L10n.text("من الآيفون") }
        return locator.location?.city ?? "—"
    }

    // MARK: التنبيهات
    /// الآيفون يجدول التنبيهات والساعة تعرضها، فنرسل له الاختيار
    private func saveNotifications() {
        WatchSession.shared.set(adhan || prePrayer, forKey: WatchKeys.notifyEnabled)
        WatchSession.shared.set(prePrayer ? 10 : 0, forKey: WatchKeys.notifyBefore)
    }

    /// معاينة: بطاقة تنبيه على كامل الشاشة تظهر قليلاً ثم تختفي
    private func showSample() {
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(W.enter(0.5)) { showsSampleAlert = true }
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(W.move(0.4)) { showsSampleAlert = false }
        }
    }

    private var sampleAlert: some View {
        let moment = PrayerSchedule.moment(at: .now)
        let upcoming = moment.map { $0.next == .sunrise ? PrayerName.dhuhr : $0.next } ?? .fajr
        return VStack(spacing: 4) {
            WatchLogo()
                .frame(width: 22, height: 22)
                .frame(width: 36, height: 36)
                .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(DateHelper.digits(L10n.text("بعد ١٠ دقائق")))
                .font(.system(size: 12))
                .foregroundStyle(W.muted)
                .padding(.top, 4)
            Text("\(L10n.text("صلاة")) \(upcoming.title)")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(W.text)
            Text(moment.map { PrayerSchedule.format($0.today.time(upcoming)) } ?? "")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(W.accent())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.118), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color(white: 0.2), lineWidth: 1))
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onTapGesture { withAnimation(W.move(0.3)) { showsSampleAlert = false } }
    }

    // MARK: التنقل
    private func next() {
        W.tap()
        guard page < 2 else { return onFinish() }
        page += 1
        withAnimation(W.move(reduceMotion ? 0.2 : 0.8)) { progress = Double(page) }
    }
}
