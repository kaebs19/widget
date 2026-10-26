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

    init() {
        AppFontFamily.validateRegistration()
        #if DEBUG
        ScreenshotSeed.applyIfNeeded()
        #endif
        // الصحة توقظ التطبيق في الخلفية عند خطوات جديدة، فتتحدث ودجاتها
        #if !targetEnvironment(macCatalyst)
        HealthWidgets.startBackgroundUpdates()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            LaunchView()
                // التطبيق كله عربي RTL، فنحددها مرة وحدة هنا بدل كل شاشة
                .environment(\.layoutDirection, .rightToLeft)
                .environment(\.locale, Locale(identifier: "ar"))
                .appAppearance()
                // يُعاد حسابه مع كل تغيير للون التمييز؛ والرئيسية تعيد بناء محتواها عند إغلاق الإعدادات،
                // فلا نعيد بناء الجذر حتى لا تُغلق الإعدادات نفسها أثناء التعديل
                .tint(Theme.accent(accent))
                .environment(styleStore)
                // عند كل فتح للتطبيق تمتد تنبيهات الأذان لأيام قادمة
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task {
                            await PrayerNotifications.reschedule()
                            await PaydayNotifications.reschedule()
                            await ObligationStore.scheduleReminders()
                            if HealthCache.isConnected {
                                await HealthReader.refresh()
                                HealthWidgets.reload()
                            }
                        }
                    }
                }
        }
    }
}
