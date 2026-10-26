//
//  WidgetsWatchApp.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI

@main
struct WidgetsWatchApp: App {
    @AppStorage(AppLanguage.preferenceKey, store: AppGroup.defaults) private var language = AppLanguage.system
    @AppStorage(AppSettings.Key.accent, store: AppGroup.defaults) private var accent = AppAccent.gold

    init() {
        WatchSession.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchLaunchView()
                .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
                .environment(\.locale, language.locale)
                .tint(W.accent(accent))
        }
    }
}
