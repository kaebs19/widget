//
//  WatchSession.swift
//  WidgetsWatch
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import WatchConnectivity
import WidgetKit

// MARK: - مزامنة الآيفون
// الآيفون يرسل إعدادات الصلاة والعرض فنحفظها هنا، وما يغيّره المستخدم على الساعة نرسله له.
final class WatchSession: NSObject, WCSessionDelegate {
    static let shared = WatchSession()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// يحفظ القيمة هنا ويرسلها للآيفون؛ تصل حتى لو كان التطبيق مغلقاً هناك
    func set(_ value: Any, forKey key: String) {
        AppGroup.defaults.set(value, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo([key: value])
    }

    private func apply(_ context: [String: Any]) {
        for (key, value) in context {
            AppGroup.defaults.set(value, forKey: key)
        }
        // وجه الساعة يعيد الحساب بالموقع والأرقام الجديدة
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: WCSessionDelegate
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.apply(context) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in self.apply(applicationContext) }
    }
}

/// مفاتيح يملكها الآيفون (جدولة التنبيهات هناك)، وتغيّرها الساعة بالمزامنة
enum WatchKeys {
    static let notifyEnabled = "prayer.notify.enabled"
    static let notifyBefore = "prayer.notify.before"
    static let location = "prayer.location"
}
