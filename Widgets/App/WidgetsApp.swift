//
//  WidgetsApp.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

@main
struct WidgetsApp: App {
    @AppStorage(AppLanguage.preferenceKey, store: AppGroup.defaults) private var language = AppLanguage.system
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
        WatchSync.shared.activate()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            LaunchView()
                // Resolve the interface locale and direction from the shared language preference.
                .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
                .environment(\.locale, language.locale)
                .appAppearance()
                // يُعاد حسابه مع كل تغيير للون التمييز؛ والرئيسية تعيد بناء محتواها عند إغلاق الإعدادات،
                // فلا نعيد بناء الجذر حتى لا تُغلق الإعدادات نفسها أثناء التعديل
                .tint(Theme.accent(accent))
                .environment(styleStore)
                // عند كل فتح للتطبيق تمتد تنبيهات الأذان لأيام قادمة
                #if !targetEnvironment(macCatalyst)
                // أي تغيير في الإعدادات المشتركة يصل للساعة
                .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                    WatchSync.shared.push()
                }
                #endif
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        #if !targetEnvironment(macCatalyst)
                        WatchSync.shared.push()
                        #endif
                        Task {
                            await OccasionStore.scheduleReminders(for: OccasionStore.all())
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
