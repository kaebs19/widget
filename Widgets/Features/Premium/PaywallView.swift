//
//  PaywallView.swift
//  Widgets
//
//  صفحة الاشتراك: معاينة الودجات المدفوعة، الخطتان، الاستعادة، والشروط.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(WidgetStyleStore.self) private var styles
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = Premium.yearlyID
    @State private var isPurchasing = false
    @State private var webPage: URL?
    @State private var showManage = false

    private let showcase: [WidgetKind] = [.styledDay, .bigNumber, .weekRibbon, .monthProgress, .hijriCountdown, .bothDates]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    gallery
                    features
                    if store.isActive { activeCard } else { plans }
                    if let message = store.errorMessage {
                        Text(message)
                            .font(AppFont.ui(13))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    footer
                }
                .padding(.vertical, 16)
                .readableWidth(560)
            }
            .background(Theme.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { if !store.isActive { subscribeButton } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text("إغلاق"), systemImage: "xmark") { dismiss() }
                }
            }
            .task { await store.load() }
            .sheet(item: $webPage) { url in SafariView(url: url).ignoresSafeArea() }
            .manageSubscriptionsSheet(isPresented: $showManage)
        }
        .tint(Theme.gold)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.gold)
            Text(L10n.text("ودجات الأيام والشهور"))
                .font(AppFont.uiBold(24))
            Text(L10n.text("أسماء الأيام والشهور الهجرية والميلادية بخطوط عربية فاخرة، تتغيّر وحدها كل يوم"))
                .font(AppFont.ui(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var gallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(showcase) { kind in
                    let size = kind.supportedSizes.contains(.medium) ? WidgetSize.medium : .small
                    WidgetPreviewView(kind: kind, size: size, style: styles.style(for: kind))
                        .frame(width: size.size.width, height: size.size.height)
                        .cardStyle(radius: 24)
                        .scaleEffect(0.72)
                        .frame(width: size.size.width * 0.72, height: size.size.height * 0.72)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 12) {
            feature("textformat", L10n.text("ستة خطوط: نسخ مشكّل، رقعة، نستعليق، كوفي، نقطي، وإنجليزي"))
            feature("square.grid.2x2.fill", L10n.text("١٢ ودجت للأيام والشهور، صغيرة ومتوسطة"))
            feature("calendar", L10n.text("هجري بتقويم أم القرى وميلادي، وعدّ تنازلي لرمضان والعيدين"))
            feature("paintpalette.fill", L10n.text("كل ودجت يقبل تخصيص الخلفية والألوان"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardTop, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
    }

    private func feature(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.gold)
                .frame(width: 22)
            Text(text).font(AppFont.ui(14))
        }
    }

    // MARK: الخطط
    private var plans: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty {
                if store.isLoading {
                    ProgressView().padding()
                } else {
                    Button(L10n.text("إعادة المحاولة")) { Task { await store.load() } }
                }
            }
            if let yearly = store.yearly { planCard(yearly, isYearly: true) }
            if let monthly = store.monthly { planCard(monthly, isYearly: false) }
        }
        .padding(.horizontal, 16)
    }

    private func planCard(_ product: Product, isYearly: Bool) -> some View {
        let isSelected = selectedID == product.id
        return Button { withAnimation(.snappy) { selectedID = product.id } } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.gold : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(isYearly ? L10n.text("سنوي") : L10n.text("شهري"))
                            .font(AppFont.uiBold(16))
                        if isYearly, let savings = store.yearlySavings {
                            Text(String(format: L10n.text("وفّر %lld٪"), savings))
                                .font(AppFont.uiBold(11))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .foregroundStyle(Theme.gold)
                                .background(Theme.gold.opacity(0.15), in: Capsule())
                        }
                        if isYearly && store.trialEligible {
                            Text(L10n.text("أسبوع مجاناً"))
                                .font(AppFont.uiBold(11))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .foregroundStyle(Theme.onAccent)
                                .background(Theme.gold, in: Capsule())
                        }
                    }
                    if isYearly {
                        Text("\((product.price / 12).formatted(product.priceFormatStyle)) \(L10n.text("شهرياً"))")
                            .font(AppFont.ui(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Text("\(product.displayPrice) / \(isYearly ? L10n.text("سنة") : L10n.text("شهر"))")
                    .font(AppFont.uiBold(15))
            }
            .padding(16)
            .background(Theme.cardTop, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(isSelected ? Theme.gold : .clear, lineWidth: 2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var selectedProduct: Product? {
        store.products.first { $0.id == selectedID } ?? store.yearly ?? store.monthly
    }

    private var subscribeButton: some View {
        let trial = selectedProduct?.id == Premium.yearlyID && store.trialEligible
        return Button {
            guard let product = selectedProduct else { return }
            isPurchasing = true
            Task {
                if await store.purchase(product) { dismiss() }
                isPurchasing = false
            }
        } label: {
            Group {
                if isPurchasing { ProgressView().tint(Theme.onAccent) }
                else { Text(trial ? L10n.text("ابدأ الأسبوع المجاني") : L10n.text("اشترك الآن")) }
            }
            .font(AppFont.uiBold(17))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Theme.onAccent)
            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 18))
        }
        .disabled(selectedProduct == nil || isPurchasing)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private var activeCard: some View {
        VStack(spacing: 10) {
            Label(L10n.text("أنت مشترك، وكل ودجات الأيام والشهور مفتوحة"), systemImage: "checkmark.seal.fill")
                .font(AppFont.uiBold(15))
                .foregroundStyle(Theme.gold)
            if let id = store.activeProductID {
                Text(id == Premium.yearlyID ? L10n.text("خطتك: سنوي") : L10n.text("خطتك: شهري"))
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            Button(L10n.text("إدارة الاشتراك")) { showManage = true }
                .font(AppFont.uiBold(15))
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.cardTop, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(L10n.text("استعادة المشتريات")) { Task { await store.restore() } }
                .font(AppFont.uiBold(14))
            Text(L10n.text("يتجدد الاشتراك تلقائياً بنفس السعر في نهاية كل فترة ما لم يُلغَ قبل ٢٤ ساعة على الأقل من موعد التجديد، ويُخصم المبلغ من حساب Apple. تُدار الاشتراكات وتُلغى من إعدادات حسابك في App Store. عند إلغاء التجربة المجانية قبل انتهائها لا يُخصم شيء."))
                .font(AppFont.ui(11))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                Button(L10n.text("شروط الاستخدام")) { webPage = AppLinks.terms }
                Button(L10n.text("سياسة الخصوصية")) { webPage = AppLinks.privacy }
            }
            .font(AppFont.ui(12))
        }
        .padding(.horizontal, 24)
    }
}
