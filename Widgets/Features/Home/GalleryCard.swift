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

    var body: some View {
        // NavigationLink(value:) مع navigationDestination أخف من NavigationLink(destination:)
        // لأن صفحة التفاصيل ما تنبني إلا لما المستخدم يضغط
        NavigationLink(value: kind) {
            VStack(spacing: 8) {
                WidgetPreviewView(kind: kind)
                    .aspectRatio(kind.previewSize.aspectRatio, contentMode: .fit)
                    .cardStyle()
                Text(kind.title)
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
