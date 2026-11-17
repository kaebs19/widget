//
//  Premium.swift
//  Widgets
//
//  الاشتراك المدفوع (شهري وسنوي) الذي يفتح ودجات «الأيام والشهور».
//  التطبيق والـ Widget يتحققان من StoreKit مباشرة، ويحفظان النتيجة في المساحة المشتركة
//  حتى يرسم الـ Widget بسرعة دون انتظار.
//

import Foundation
import StoreKit
import WidgetKit

nonisolated enum Premium {
    /// معرّفات المنتجات كما تُنشأ في App Store Connect داخل مجموعة اشتراك واحدة
    static let monthlyID = "com.widgetar.app.pro.monthly"
    static let yearlyID = "com.widgetar.app.pro.yearly"
    static let productIDs = [yearlyID, monthlyID]

    private static let activeKey = "premium.active"
    private static let expiryKey = "premium.expiry"

    /// آخر حالة معروفة. تنتهي تلقائياً بعد تاريخ التجديد إن لم يتحقق التطبيق من جديد.
    static var isActive: Bool {
        let defaults = AppGroup.defaults
        guard defaults.bool(forKey: activeKey) else { return false }
        guard let expiry = defaults.object(forKey: expiryKey) as? Date else { return true }
        // مهلة يوم واحد حتى لا يُقفل الودجت لحظة التجديد قبل أن يصل الإيصال الجديد
        return expiry.addingTimeInterval(24 * 3600) > .now
    }

    static func store(active: Bool, expiry: Date?) {
        let defaults = AppGroup.defaults
        let changed = defaults.bool(forKey: activeKey) != active
        defaults.set(active, forKey: activeKey)
        defaults.set(expiry, forKey: expiryKey)
        if changed { reloadWidgets() }
    }

    /// يقرأ الاشتراكات السارية من StoreKit ويحدّث الحالة المحفوظة
    @discardableResult
    static func refresh() async -> Bool {
        var active = false
        var expiry: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  productIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            if let date = transaction.expirationDate, date < .now { continue }
            active = true
            expiry = max(expiry ?? .distantPast, transaction.expirationDate ?? .distantFuture)
        }
        store(active: active, expiry: expiry)
        return active
    }

    static func reloadWidgets() {
        for kind in WidgetKind.allCases where kind.isPremium {
            WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        }
    }
}

extension WidgetKind {
    /// ودجات تحتاج الاشتراك: قسم «الأيام والشهور» كاملاً
    nonisolated var isPremium: Bool { category == .names }
}
