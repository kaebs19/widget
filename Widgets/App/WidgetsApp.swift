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
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppSettings.Key.accent, store: AppGroup.defaults) private var accent = AppAccent.gold
    @AppStorage(AppSettings.Key.hijriOffset, store: AppGroup.defaults) private var hijriOffset = 0
    @AppStorage(AppSettings.Key.weekStart, store: AppGroup.defaults) private var weekStart = 1

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
                // لون التمييز والتقويم يُقرأان من الإعدادات عند الرسم، فنعيد بناء الواجهة عند تغييرها
                .id("\(accent.rawValue)|\(hijriOffset)|\(weekStart)")
                .environment(styleStore)
                // عند كل فتح للتطبيق تمتد تنبيهات الأذان لأيام قادمة
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task {
                            await PrayerNotifications.reschedule()
                            await PaydayNotifications.reschedule()
                            await ObligationStore.scheduleReminders()
                        }
                    }
                }
        }
    }
}
