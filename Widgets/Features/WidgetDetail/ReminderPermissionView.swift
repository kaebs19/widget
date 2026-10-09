//
//  ReminderPermissionView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import UserNotifications
import WidgetKit

// MARK: - إذن تذكير المناسبة
// الـ Widget يجدول التذكير بنفسه، لكنه ما يقدر يطلب الإذن، فنطلبه من هنا.
struct ReminderPermissionView: View {
    @State private var status: UNAuthorizationStatus?
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("تذكير قبل المناسبة", systemImage: "bell.badge")
                .font(AppFont.uiBold(15))
                .foregroundStyle(Theme.textPrimary)
            Text("فعّل «ذكّرني قبل يوم» من «تعديل الودجت»، ويصلك تنبيه الساعة ٩ صباح اليوم السابق.")
                .font(AppFont.ui(13))
                .foregroundStyle(Theme.textSecondary)
            action
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task(id: scenePhase) { await refresh() }
    }

    @ViewBuilder
    private var action: some View {
        switch status {
        case .authorized, .provisional, .ephemeral:
            Label("التنبيهات مفعّلة", systemImage: "checkmark.circle.fill")
                .font(AppFont.ui(14))
                .foregroundStyle(Theme.gold)
        case .denied:
            Button("فتح الإعدادات للسماح بالتنبيهات") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
            }
            .font(AppFont.uiBold(14))
        case .notDetermined:
            Button("السماح بالتنبيهات") {
                Task { await requestAuthorization() }
            }
            .font(AppFont.uiBold(14))
        default:
            EmptyView()
        }
    }

    private func refresh() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        await refresh()
        // الودجات المضافة تجدول تذكيراتها الآن بدل انتظار تحديثها القادم
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.specialOccasion.rawValue)
    }
}
