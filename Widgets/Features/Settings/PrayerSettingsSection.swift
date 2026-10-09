//
//  PrayerSettingsSection.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - إعدادات الصلاة
// في الإعدادات وفي صفحات ودجات الصلاة
struct PrayerSettingsSection: View {
    @State private var locator = LocationProvider()
    @AppStorage(PrayerSchedule.Key.method, store: AppGroup.defaults) private var method = PrayerMethod.ummAlQura
    @AppStorage(PrayerSchedule.Key.madhab, store: AppGroup.defaults) private var isHanafi = false

    var body: some View {
        SettingsSection("أوقات الصلاة") {
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

            Divider()
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
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
        .onChange(of: method) { PrayerWidgets.reload() }
        .onChange(of: isHanafi) { PrayerWidgets.reload() }
    }
}
