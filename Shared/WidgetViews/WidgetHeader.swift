//
//  WidgetHeader.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - عنوان صغير أعلى كل ودجت
struct WidgetHeader: View {
    let icon: AppIcon
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            AppIconView(icon: icon, size: 13).foregroundStyle(Theme.gold)
            Text(title)
            Spacer()
            if let trailing { Text(trailing) }
        }
        .font(AppFont.ui(11))
        .foregroundStyle(Theme.textSecondary)
    }
}
