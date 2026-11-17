//
//  ProBanner.swift
//  Widgets
//
//  بطاقة «ويدجت برو» أعلى الرئيسية: تعرض ودجتين من القسم المدفوع وتفتح صفحة الاشتراك.
//

import SwiftUI

struct ProBanner: View {
    let action: () -> Void
    @Environment(StoreManager.self) private var store
    @Environment(WidgetStyleStore.self) private var styles

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(L10n.text("ويدجت برو"), systemImage: "crown.fill")
                        .font(AppFont.uiBold(13))
                        .foregroundStyle(Color(red: 0.96, green: 0.80, blue: 0.48))
                    Text(L10n.text("الأيام والشهور بخطوط عربية فاخرة"))
                        .font(AppFont.uiBold(18))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.text("١٢ ودجت بألوان وخطوط مختلفة"))
                        .font(AppFont.ui(12))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(store.trialEligible ? L10n.text("جرّب أسبوعاً مجاناً") : L10n.text("اكتشف برو"))
                        .font(AppFont.uiBold(13))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .foregroundStyle(Color(white: 0.1))
                        .background(Color(red: 0.96, green: 0.80, blue: 0.48), in: Capsule())
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // ودجتان صغيرتان متداخلتان كمعاينة
                ZStack {
                    mini(.circleBadge).rotationEffect(.degrees(-8)).offset(x: -18, y: 6)
                    mini(.styledDay).rotationEffect(.degrees(6)).offset(x: 14, y: -4)
                }
                .frame(width: 120, height: 120)
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.17, green: 0.22, blue: 0.56),
                                                  Color(red: 0.27, green: 0.16, blue: 0.35)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Color(red: 0.96, green: 0.80, blue: 0.48).opacity(0.35), lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
        .task { await store.load() }
    }

    private func mini(_ kind: WidgetKind) -> some View {
        WidgetPreviewView(kind: kind, size: .small, style: styles.style(for: kind))
            .frame(width: 170, height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .scaleEffect(0.5)
            .frame(width: 85, height: 85)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            .allowsHitTesting(false)
    }
}
