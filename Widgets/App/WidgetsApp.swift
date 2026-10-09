//
//  WidgetsApp.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

@main
struct WidgetsApp: App {
    @State private var styleStore = WidgetStyleStore()
    @AppStorage(AppSettings.Key.accent, store: AppGroup.defaults) private var accent = AppAccent.gold

    init() {
        AppFontFamily.validateRegistration()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                // التطبيق كله عربي RTL، فنحددها مرة وحدة هنا بدل كل شاشة
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .appAppearance()
                .tint(Theme.gold)
                // Theme.gold يُقرأ من الإعدادات، فنعيد بناء الواجهة كلها عند تغيير اللون
                .id(accent)
                .environment(styleStore)
        }
    }
}
