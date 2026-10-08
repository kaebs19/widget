//
//  WidgetsApp.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

@main
struct WidgetsApp: App {
    init() {
        AppFontFamily.validateRegistration()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                // التطبيق كله عربي RTL وداكن، فنحددها مرة وحدة هنا بدل كل شاشة
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}
