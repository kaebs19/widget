//
//  ScreenshotSeed.swift
//  Widgets
//
//  Created by Mohammed Saleh on 11/10/2026.
//

#if DEBUG
import Foundation
import UIKit

// MARK: - بيانات لقطات المتجر
// عند التشغيل بـ `-screenshots` (نسخ التطوير فقط) نملأ التطبيق ببيانات واقعية لتصوير لقطات App Store.
// لا يدخل في نسخة المتجر.
@MainActor
enum ScreenshotSeed {
    static var isActive: Bool { ProcessInfo.processInfo.arguments.contains("-screenshots") }

    static func applyIfNeeded() {
        guard isActive else {
            AppGroup.defaults.removeObject(forKey: QuranLibrary.pinnedKey)
            return
        }
        // الرعد ٢٨: ﴿أَلَا بِذِكۡرِ ٱللَّهِ تَطۡمَئِنُّ ٱلۡقُلُوبُ﴾
        AppGroup.defaults.set("13:28", forKey: QuranLibrary.pinnedKey)
        let calendar = DateHelper.gregorian
        let now = Date.now
        func days(_ n: Int, hour: Int = 0) -> Date {
            let day = calendar.date(byAdding: .day, value: n, to: calendar.startOfDay(for: now)) ?? now
            return calendar.date(byAdding: .hour, value: hour, to: day) ?? day
        }

        PrayerLocation(latitude: 24.7136, longitude: 46.6753, city: "الرياض").save()

        OccasionStore.save([
            Occasion(name: "عيد ميلاد سارة", type: .birthday,
                     date: calendar.date(byAdding: .year, value: -7, to: days(13)) ?? now, remindsDayBefore: true),
            Occasion(name: "ذكرى زواجنا", type: .wedding,
                     date: calendar.date(byAdding: .year, value: -5, to: days(41)) ?? now),
            Occasion(name: "رحلة العمرة", type: .travel, date: days(23), repeatsYearly: false),
        ])

        ObligationStore.save([
            Obligation(name: "إيجار الشقة", type: .rent, firstDate: days(24), frequency: .semiannual, amount: 18_000,
                       remindsDayBefore: true),
            Obligation(name: "قسط السيارة", type: .loan, firstDate: days(16), amount: 1_850,
                       endDate: calendar.date(byAdding: .month, value: 22, to: days(16))),
            Obligation(name: "فاتورة الكهرباء", type: .bill, firstDate: days(5), amount: 320),
            Obligation(name: "الإنترنت المنزلي", type: .subscription, firstDate: days(8), amount: 299),
        ])

        AppGroup.defaults.set(12_500, forKey: Payday.Key.amount(.salary))
        Budget.setBalance(9_800)
        Budget.spend(85)

        TasbeehCounter.resetToday()
        for _ in 0..<67 { TasbeehCounter.increment(.istighfar) }

        #if targetEnvironment(macCatalyst)
        // نافذة الماك بمقاس لقطات المتجر: ١٤٤٠×٩٠٠ نقطة (٢٨٨٠×١٨٠٠ بكسل)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
                scene.sizeRestrictions?.minimumSize = CGSize(width: 1440, height: 900)
                scene.sizeRestrictions?.maximumSize = CGSize(width: 1440, height: 900)
                scene.requestGeometryUpdate(.Mac(systemFrame: CGRect(x: 60, y: 60, width: 1440, height: 900)))
            }
        }
        #endif

        // الصحة: المعرض يعرض مثالاً واقعياً حين لا تكون مربوطة
        AppGroup.defaults.set(false, forKey: HealthCache.connectedKey)
    }
}
#endif
