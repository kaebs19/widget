//
//  GalleryCard.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - كرت في المعرض
struct GalleryCard: View {
    let kind: WidgetKind
    /// إذا كان مضافاً للشاشة: أين وكم نسخة
    var installed: InstalledWidget? = nil
    @Environment(WidgetStyleStore.self) private var styles

    var body: some View {
        // NavigationLink(value:) مع navigationDestination أخف من NavigationLink(destination:)
        // لأن صفحة التفاصيل ما تنبني إلا لما المستخدم يضغط
        NavigationLink(value: kind) {
            VStack(spacing: 8) {
                WidgetPreviewView(kind: kind, style: styles.style(for: kind))
                    .aspectRatio(kind.previewSize.aspectRatio, contentMode: .fit)
                    .cardStyle()
                    .overlay(alignment: .topTrailing) {
                        if installed != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white, Theme.gold)
                                .padding(8)
                                .accessibilityLabel("مضاف لشاشتك")
                        }
                    }
                VStack(spacing: 1) {
                    Text(kind.title)
                        .font(AppFont.ui(13))
                        .foregroundStyle(Theme.textSecondary)
                    if let installed {
                        Text(installed.detail)
                            .font(AppFont.ui(11))
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
