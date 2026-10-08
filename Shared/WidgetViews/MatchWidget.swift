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

    var body: some View {
        VStack(spacing: 8) {
            WidgetHeader(icon: .asset(.iconCategorySports), title: competition, trailing: "الجمعة")
            Spacer()
            HStack {
                team(home)
                Spacer()
                VStack(spacing: 2) {
                    Text(time).font(AppFont.number(22)).foregroundStyle(Theme.textPrimary)
                    Text("بعد ٥ أيام").font(AppFont.ui(11)).foregroundStyle(Theme.gold)
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
                .font(AppFont.uiBold(16))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 40, height: 40)
                .overlay(Circle().strokeBorder(Theme.border, lineWidth: 1.5))
            Text(name).font(AppFont.uiBold(12)).foregroundStyle(Theme.textPrimary)
        }
    }
}
