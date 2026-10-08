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

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("الكل", icon: .system("square.grid.2x2"), isOn: selected == nil) { onSelect(nil) }
                ForEach(WidgetCategory.allCases) { category in
                    chip(category.title, icon: category.icon, isOn: selected == category) {
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
                .foregroundStyle(isOn ? .black : Theme.textPrimary)
                .background(isOn ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.cardTop),
                            in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
