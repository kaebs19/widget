//
//  NotificationSettingsPage.swift
//  Widgets
//
//  Created by Mohammed Saleh on 27/10/2026.
//

import SwiftUI
import UserNotifications
import WidgetKit

// MARK: - الإشعارات
// كل التنبيهات في صفحة واحدة: الصلاة، ووقت تذكير المناسبات ومواعيد الصرف، وحالة الإذن في الجهاز
struct NotificationSettingsPage: View {
    @AppStorage(AppSettings.Key.reminderHour, store: AppGroup.defaults) private var reminderHour = 9
    @State private var isDenied = false
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isDenied {
                    SettingsSection(L10n.text("الإذن")) {
                        Text(L10n.text("التنبيهات مقفلة للتطبيق. فعّلها من إعدادات الجهاز."))
                            .font(AppFont.ui(14))
                            .foregroundStyle(Color.red.opacity(0.85))
                        Button(L10n.text("فتح إعدادات الجهاز")) {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        .font(AppFont.uiBold(14))
                    }
                }
                PrayerNotificationSettings()
                SettingsSection(L10n.text("المناسبات ومواعيد الصرف")) {
                    HStack {
                        Text(L10n.text("وقت تذكير «قبل يوم»"))
                        Spacer()
                        Picker(L10n.text("وقت التذكير"), selection: $reminderHour) {
                            ForEach(Array(6...22), id: \.self) { hour in
                                Text(AppSettings.reminderTimeLabel(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                    }
                    .font(AppFont.ui(15))
                    .foregroundStyle(Theme.textPrimary)
                    Text(L10n.text("تفعيل التذكير لكل مناسبة أو موعد صرف من صفحته."))
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)
            .readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .task { await refreshStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshStatus() } }
        }
        .onChange(of: reminderHour) {
            OccasionStore.save(OccasionStore.all())
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.specialOccasion.rawValue)
            Task {
                await PaydayNotifications.reschedule()
                await ObligationStore.scheduleReminders()
            }
        }
    }

    private func refreshStatus() async {
        isDenied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }
}
