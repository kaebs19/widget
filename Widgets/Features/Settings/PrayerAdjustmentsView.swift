//
//  PrayerAdjustmentsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI

// MARK: - تعديل دقائق الصلوات
// لمطابقة أذان المسجد القريب: كل صلاة تُقدَّم أو تُؤخَّر بالدقائق
struct PrayerAdjustmentsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var values: [PrayerName: Int] = Dictionary(
        uniqueKeysWithValues: PrayerName.allCases.map { ($0, PrayerSchedule.adjustment(for: $0)) })

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(PrayerName.allCases) { prayer in
                        row(prayer)
                    }
                } footer: {
                    Text("الوقت المعروض بعد التعديل. يتغيّر في الودجات والتنبيهات.")
                        .font(AppFont.ui(12))
                }
                Section {
                    Button("إرجاع الكل للحساب الأصلي", role: .destructive) {
                        for prayer in PrayerName.allCases { set(prayer, 0) }
                    }
                    .font(AppFont.ui(15))
                }
            }
            .navigationTitle("تعديل الدقائق")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
        }
        .tint(Theme.gold)
        .presentationDetents([.medium, .large])
    }

    private func row(_ prayer: PrayerName) -> some View {
        let value = values[prayer] ?? 0
        let time = PrayerSchedule.day(for: .now)?.time(prayer)
        return HStack {
            Image(systemName: prayer.symbol).foregroundStyle(Theme.gold).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.title).font(AppFont.uiBold(15))
                if let time {
                    Text(PrayerSchedule.format(time)).font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Text(value == 0 ? "—" : (value > 0 ? "+" : "−") + DateHelper.arabic(abs(value)) + " د")
                .font(AppFont.number(15))
                .foregroundStyle(value == 0 ? Theme.textSecondary : Theme.gold)
                .frame(minWidth: 52)
            Stepper(prayer.title, value: Binding(get: { value }, set: { set(prayer, $0) }), in: -30...30)
                .labelsHidden()
        }
    }

    private func set(_ prayer: PrayerName, _ value: Int) {
        values[prayer] = value
        AppGroup.defaults.set(value, forKey: PrayerSchedule.Key.adjustment(prayer))
        PrayerWidgets.reload()
    }
}
