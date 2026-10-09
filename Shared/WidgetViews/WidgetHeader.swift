//
//  WidgetHeader.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - عنوان صغير أعلى كل ودجت
struct WidgetHeader: View {
    let icon: AppIcon
    let title: String
    var trailing: String? = nil
    @Environment(\.widgetStyle) private var style

    var body: some View {
        HStack(spacing: 4) {
            AppIconView(icon: icon, size: 13).foregroundStyle(style.accent).widgetAccentable()
            Text(title)
            Spacer()
            if let trailing { Text(style.text(trailing)) }
        }
        .font(style.font(.label, 11))
        .foregroundStyle(style.secondary)
    }
}
