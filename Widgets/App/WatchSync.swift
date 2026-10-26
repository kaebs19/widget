//
//  WatchSync.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

#if canImport(WatchConnectivity) && !targetEnvironment(macCatalyst)
import WatchConnectivity
import WidgetKit

// MARK: - مزامنة الساعة
// الساعة جهاز مستقل لا يرى المساحة المشتركة، فنرسل لها إعدادات الصلاة والعرض،
// ونستقبل منها ما يغيّره المستخدم على معصمه (التنبيهات والأرقام والاهتزاز).
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    /// كل ما تحتاجه الساعة لتحسب الأوقات وتعرضها مثل الآيفون
    static let sentKeys: [String] = [
        "prayer.location", PrayerSchedule.Key.method, PrayerSchedule.Key.madhab,
        AppSettings.Key.numerals, AppLanguage.preferenceKey, AppSettings.Key.hijriOffset, AppSettings.Key.accent,
        AppSettings.Key.haptics, PrayerNotifications.Key.enabled, PrayerNotifications.Key.minutesBefore,
    ] + PrayerName.allCases.map { PrayerSchedule.Key.adjustment($0) }

    /// ما يُسمح للساعة بتغييره هنا
    static let receivedKeys: Set<String> = [
        "prayer.location", AppSettings.Key.numerals, AppSettings.Key.haptics,
        PrayerNotifications.Key.enabled, PrayerNotifications.Key.minutesBefore,
    ]

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// يُستدعى عند فتح التطبيق وبعد أي تغيير؛ النظام يوصل آخر نسخة فقط
    func push() {
        let session = WCSession.default
        guard WCSession.isSupported(), session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        var context: [String: Any] = TasbeehCounter.snapshot()
        for key in Self.sentKeys {
            if let value = AppGroup.defaults.object(forKey: key) { context[key] = value }
        }
        try? session.updateApplicationContext(context)
    }

    /// تصفير اليوم من الإعدادات يصل للساعة؛ الدمج وحده لا ينزّل العدد
    func sendTasbeehReset() {
        let session = WCSession.default
        guard WCSession.isSupported(), session.activationState == .activated, session.isWatchAppInstalled else { return }
        session.transferUserInfo([TasbeehCounter.resetKey: TasbeehCounter.dayID(for: .now)])
    }

    private func apply(_ values: [String: Any]) {
        if TasbeehCounter.merge(values) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.istighfar.rawValue)
        }
        var changed = false
        for (key, value) in values where Self.receivedKeys.contains(key) {
            AppGroup.defaults.set(value, forKey: key)
            changed = true
        }
        guard changed else { return }
        Task { @MainActor in
            PrayerWidgets.reload()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    // MARK: WCSessionDelegate
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.push() }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.apply(userInfo) }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // عند تبديل الساعة المقترنة نعيد التفعيل للساعة الجديدة
        session.activate()
    }
}
#endif
