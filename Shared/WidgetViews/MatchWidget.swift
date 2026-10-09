//
//  MatchWidget.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - المباراة القادمة
struct MatchWidget: View {
    var home = "الهلال"
    var away = "النصر"
    var time = "٩:٠٠ م"
    var competition = "دوري روشن"
    @Environment(\.widgetStyle) private var style

    var body: some View {
        VStack(spacing: 8) {
            WidgetHeader(icon: .asset(.iconCategorySports), title: competition, trailing: "الجمعة")
            Spacer()
            HStack {
                team(home)
                Spacer()
                VStack(spacing: 2) {
                    Text(style.text(time)).font(style.font(.number, 22)).foregroundStyle(style.primary)
                    Text(style.text("بعد ٥ أيام")).font(style.font(.label, 11)).foregroundStyle(style.accent)
                }
                Spacer()
                team(away)
            }
            Spacer()
        }
        .widgetContent()
    }

    // دائرة بالحرف الأول بدال شعار النادي (الشعارات علامات تجارية)
    private func team(_ name: String) -> some View {
        VStack(spacing: 6) {
            Text(String(name.dropFirst(2).prefix(1)))
                .font(style.font(.labelBold, 16))
                .foregroundStyle(style.primary)
                .frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(style.primary.opacity(0.15), lineWidth: 1.5))
            Text(name).font(style.font(.labelBold, 12)).foregroundStyle(style.primary)
        }
    }
}
