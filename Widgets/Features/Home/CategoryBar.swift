//
//  CategoryBar.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - شريط الأقسام
struct CategoryBar: View {
    let selected: WidgetCategory?
    let onSelect: (WidgetCategory?) -> Void
    /// «ودجاتي» مفعّل: لا يُميَّز أي قسم
    var showsInstalled = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("الكل", icon: .system("square.grid.2x2"), isOn: selected == nil && !showsInstalled) { onSelect(nil) }
                ForEach(WidgetCategory.available) { category in
                    chip(category.title, icon: category.icon, isOn: selected == category && !showsInstalled) {
                        onSelect(category)
                    }
                }
            }
        }
    }

    private func chip(_ title: String, icon: AppIcon, isOn: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                AppIconView(icon: icon, size: 17)
            }
                .font(AppFont.ui(14))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isOn ? Theme.onAccent : Theme.textPrimary)
                .background(isOn ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.cardTop),
                            in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
