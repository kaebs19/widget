//
//  OccasionsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import UserNotifications

// MARK: - مناسباتي
// المناسبات المحفوظة هنا تظهر في «تعديل الودجت» لودجت «مناسبة خاصة».
struct OccasionsView: View {
    @State private var occasions = OccasionStore.all()
    @State private var editing: Occasion?

    private var sorted: [Occasion] {
        occasions.sorted { $0.nextDate() < $1.nextDate() }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if occasions.isEmpty {
                    emptyState
                } else {
                    ForEach(sorted) { occasion in
                        Button { editing = occasion } label: {
                            OccasionRow(occasion: occasion)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("حذف", systemImage: "trash", role: .destructive) { delete(occasion) }
                        }
                    }
                    Text("اختر أي مناسبة لودجت «مناسبة خاصة»: اضغط عليه مطولاً ثم «تعديل الودجت» ← «من مناسباتي».")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("مناسباتي")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = Occasion(name: "", date: .now) } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("إضافة مناسبة")
            }
        }
        .fullScreenCover(item: $editing) { occasion in
            OccasionEditor(occasion: occasion, isNew: !occasions.contains { $0.id == occasion.id },
                           onSave: save, onDelete: delete)
                .appAppearance()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "birthday.cake")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gold)
            Text("أضف أعياد الميلاد والذكريات ومواعيدك المهمة")
                .font(AppFont.uiBold(16))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("وتابع العدّ التنازلي لها من الشاشة الرئيسية.")
                .font(AppFont.ui(14))
                .foregroundStyle(Theme.textSecondary)
            Button { editing = Occasion(name: "", date: .now) } label: {
                Label("إضافة مناسبة", systemImage: "plus")
                    .font(AppFont.uiBold(15))
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .foregroundStyle(Theme.onAccent)
                    .background(Theme.gold, in: Capsule())
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func save(_ occasion: Occasion) {
        if let index = occasions.firstIndex(where: { $0.id == occasion.id }) {
            occasions[index] = occasion
        } else {
            occasions.append(occasion)
        }
        OccasionStore.save(occasions)
    }

    private func delete(_ occasion: Occasion) {
        occasions.removeAll { $0.id == occasion.id }
        OccasionStore.save(occasions)
    }
}

// MARK: - سطر مناسبة
private struct OccasionRow: View {
    let occasion: Occasion

    var body: some View {
        let next = occasion.nextDate()
        let days = DateHelper.gregorian.dateComponents([.day], from: DateHelper.gregorian.startOfDay(for: .now),
                                                       to: DateHelper.gregorian.startOfDay(for: next)).day ?? 0
        HStack(spacing: 14) {
            Image(systemName: occasion.type.symbol)
                .font(.system(size: 18))
                .foregroundStyle(Theme.gold)
                .frame(width: 44, height: 44)
                .background(Theme.gold.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(occasion.name)
                    .font(AppFont.uiBold(16))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle(next: next))
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(spacing: 0) {
                Text(days <= 0 ? "اليوم" : DateHelper.arabic(days))
                    .font(AppFont.number(days <= 0 ? 15 : 22))
                    .foregroundStyle(Theme.textPrimary)
                if days > 0 {
                    Text("يوم").font(AppFont.ui(11)).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(14)
        .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func subtitle(next: Date) -> String {
        var parts = [DateHelper.weekdayDayMonth(next)]
        if let years = occasion.yearsAtNext() {
            parts.append(occasion.type == .birthday ? "يكمل \(DateHelper.arabic(years)) سنة" : "الذكرى \(DateHelper.arabic(years))")
        }
        if occasion.remindsDayBefore { parts.append("🔔") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - إضافة وتعديل
private struct OccasionEditor: View {
    @State var occasion: Occasion
    let isNew: Bool
    let onSave: (Occasion) -> Void
    let onDelete: (Occasion) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsAllowed = true

    private var trimmedName: String { occasion.name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsSection("النوع") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(OccasionType.allCases) { type in
                                typeButton(type)
                            }
                        }
                    }
                    SettingsSection("التفاصيل") {
                        TextField(placeholder, text: $occasion.name)
                            .font(AppFont.ui(16))
                            .padding(12)
                            .background(Theme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        DatePicker(occasion.type == .birthday ? "تاريخ الميلاد" : "التاريخ",
                                   selection: $occasion.date, displayedComponents: .date)
                            // ميلادي بأرقام عربية، مثل بقية التطبيق
                            .environment(\.locale, Locale(identifier: "ar@numbers=arab;calendar=gregorian"))
                            .environment(\.calendar, DateHelper.gregorian)
                        Toggle("تتكرر كل سنة", isOn: $occasion.repeatsYearly)
                        if occasion.type.countsYears, occasion.repeatsYearly, let years = occasion.yearsAtNext() {
                            Label(occasion.type == .birthday ? "يكمل \(DateHelper.arabic(years)) سنة في الموعد القادم"
                                                             : "الذكرى \(DateHelper.arabic(years)) في الموعد القادم",
                                  systemImage: "sparkles")
                                .font(AppFont.ui(13))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                    SettingsSection("التذكير") {
                        Toggle("ذكّرني قبل يوم", isOn: $occasion.remindsDayBefore)
                        Text(notificationsAllowed
                             ? "يصلك تنبيه \(AppSettings.reminderTimeLabel()) في اليوم السابق."
                             : "التنبيهات غير مسموحة للتطبيق. فعّلها من إعدادات الجهاز.")
                            .font(AppFont.ui(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if !isNew {
                        Button("حذف المناسبة", role: .destructive) {
                            onDelete(occasion)
                            dismiss()
                        }
                        .font(AppFont.ui(15))
                    }
                }
                .padding(16)
            }
            .font(AppFont.ui(15))
            .foregroundStyle(Theme.textPrimary)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "مناسبة جديدة" : "تعديل المناسبة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        occasion.name = trimmedName
                        onSave(occasion)
                        dismiss()
                    }
                    .bold()
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onChange(of: occasion.remindsDayBefore) { _, on in
                guard on else { return }
                Task {
                    let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    notificationsAllowed = granted ?? false
                }
            }
        }
        .tint(Theme.gold)
    }

    private var placeholder: String {
        switch occasion.type {
        case .birthday:   "مثلاً: عيد ميلاد سارة"
        case .wedding:    "مثلاً: ذكرى زواجنا"
        case .graduation: "مثلاً: تخرّج أحمد"
        case .newborn:    "مثلاً: قدوم المولود"
        case .travel:     "مثلاً: رحلة العمرة"
        case .custom:     "اسم المناسبة"
        }
    }

    private func typeButton(_ type: OccasionType) -> some View {
        let isOn = occasion.type == type
        return Button {
            withAnimation(.snappy) {
                occasion.type = type
                occasion.repeatsYearly = type.repeatsByDefault
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.symbol).font(.system(size: 18))
                Text(type.title).font(AppFont.ui(12))
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .foregroundStyle(isOn ? Theme.onAccent : Theme.textPrimary)
            .background(isOn ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.cardTop), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
