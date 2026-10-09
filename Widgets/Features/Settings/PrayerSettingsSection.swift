//
//  PrayerSettingsSection.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import UserNotifications

// MARK: - إعدادات الصلاة
// في الإعدادات وفي صفحات ودجات الصلاة
struct PrayerSettingsSection: View {
    @State private var locator = LocationProvider()
    @AppStorage(PrayerSchedule.Key.method, store: AppGroup.defaults) private var method = PrayerMethod.ummAlQura
    @AppStorage(PrayerSchedule.Key.madhab, store: AppGroup.defaults) private var isHanafi = false
    @AppStorage(PrayerNotifications.Key.enabled, store: AppGroup.defaults) private var notify = false
    @AppStorage(PrayerNotifications.Key.minutesBefore, store: AppGroup.defaults) private var minutesBefore = 0
    @AppStorage(PrayerNotifications.Key.afterAdhkar, store: AppGroup.defaults) private var afterAdhkar = false
    @State private var selectedPrayers = PrayerNotifications.prayers
    @State private var showAdjustments = false
    @State private var showQibla = false
    @State private var notificationsDenied = false

    var body: some View {
        VStack(spacing: 20) {
        SettingsSection("الموقع") {
            HStack(spacing: 12) {
                Image(systemName: locator.location == nil ? "location.slash" : "location.fill")
                    .foregroundStyle(Theme.gold)
                    .frame(width: 36, height: 36)
                    .background(Theme.gold.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(locator.location?.city ?? "مكة المكرمة (افتراضي)")
                        .font(AppFont.uiBold(15))
                    Text(locator.errorMessage ?? (locator.location == nil ? "حدّد موقعك لأوقات مدينتك" : "يُحفظ موقعك على جهازك فقط"))
                        .font(AppFont.ui(12))
                        .foregroundStyle(locator.errorMessage == nil ? Theme.textSecondary : Color.red.opacity(0.85))
                }
                Spacer()
                Button {
                    locator.locate()
                } label: {
                    if locator.isLocating {
                        ProgressView()
                    } else {
                        Text(locator.location == nil ? "تحديد" : "تحديث")
                            .font(AppFont.uiBold(14))
                    }
                }
                .disabled(locator.isLocating)
            }
        }

        SettingsSection("طريقة الحساب") {
            HStack {
                Text("طريقة الحساب")
                Spacer()
                Picker("طريقة الحساب", selection: $method) {
                    ForEach(PrayerMethod.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
            }
            Toggle("العصر على المذهب الحنفي", isOn: $isHanafi)
            Text(method == .ummAlQura
                 ? "أم القرى: العشاء بعد المغرب بساعة ونصف، وساعتين في رمضان."
                 : "اختر الطريقة المعتمدة في بلدك.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }

        SettingsSection("التنبيهات") {
            Toggle(isOn: $notify) {
                Label("تنبيه الأذان", systemImage: "bell.badge")
            }
            if notify {
                HStack(spacing: 6) {
                    ForEach(PrayerName.fard) { prayer in
                        let isOn = selectedPrayers.contains(prayer)
                        Button {
                            if isOn { selectedPrayers.remove(prayer) } else { selectedPrayers.insert(prayer) }
                        } label: {
                            Text(prayer.title)
                                .font(AppFont.ui(13))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .foregroundStyle(isOn ? Theme.onAccent : Theme.textPrimary)
                                .background(isOn ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.cardTop), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                HStack {
                    Text("وقت التنبيه")
                    Spacer()
                    Picker("وقت التنبيه", selection: $minutesBefore) {
                        Text("عند الأذان").tag(0)
                        ForEach([5, 10, 15, 30], id: \.self) { Text("قبل \(DateHelper.arabic($0)) دقيقة").tag($0) }
                    }
                    .labelsHidden()
                }
                if notificationsDenied {
                    Text("التنبيهات مقفلة للتطبيق. فعّلها من إعدادات الجهاز.")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Color.red.opacity(0.85))
                }
            }
            Toggle(isOn: $afterAdhkar) {
                Label("تذكير بأذكار بعد الصلاة", systemImage: "text.book.closed")
            }
        }

        SettingsSection("أدوات") {
            HStack(spacing: 10) {
                Button { showAdjustments = true } label: {
                    Label("تعديل الدقائق", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
                Button { showQibla = true } label: {
                    Label("اتجاه القبلة", systemImage: "location.north.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .font(AppFont.uiBold(14))
            .foregroundStyle(Theme.gold)
        }
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
        .onChange(of: method) { PrayerWidgets.reload() }
        .onChange(of: isHanafi) { PrayerWidgets.reload() }
        .onChange(of: minutesBefore) { PrayerWidgets.reload() }
        .onChange(of: selectedPrayers) { _, prayers in
            PrayerNotifications.setPrayers(prayers)
            PrayerWidgets.reload()
        }
        .sheet(isPresented: $showAdjustments) { PrayerAdjustmentsView().appAppearance() }
        .fullScreenCover(isPresented: $showQibla) { QiblaView().appAppearance() }
        .onChange(of: afterAdhkar) { _, on in
            Task {
                if on {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                }
                await PrayerNotifications.reschedule()
            }
        }
        .onChange(of: notify) { _, on in
            Task {
                if on {
                    let granted = (try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .timeSensitive])) ?? false
                    notificationsDenied = !granted
                }
                await PrayerNotifications.reschedule()
            }
        }
    }
}
