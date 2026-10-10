//
//  ObligationsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import SwiftUI
import UserNotifications

// MARK: - التزاماتي
struct ObligationsView: View {
    @State private var items = ObligationStore.all()
    @State private var editing: Obligation?

    private var sorted: [Obligation] {
        items.sorted { ($0.nextDate() ?? .distantFuture) < ($1.nextDate() ?? .distantFuture) }
    }

    /// ما بقي من التزامات حتى نهاية الشهر
    private var monthTotal: Int {
        let calendar = DateHelper.gregorian
        guard let end = calendar.dateInterval(of: .month, for: .now)?.end else { return 0 }
        return items.reduce(0) { $0 + $1.amount * $1.dates(from: .now, to: end).count }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if items.isEmpty {
                    emptyState
                } else {
                    if monthTotal > 0 {
                        HStack {
                            Text("باقي هذا الشهر")
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text(PaydayFormat.amount(monthTotal))
                                .font(AppFont.uiBold(17))
                                .foregroundStyle(Theme.gold)
                        }
                        .font(AppFont.ui(14))
                        .padding(14)
                        .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    ForEach(sorted) { item in
                        Button { editing = item } label: {
                            ObligationRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("حذف", systemImage: "trash", role: .destructive) { delete(item) }
                        }
                    }
                    Text("التذكير يصلك في اليوم السابق، بنفس ساعة تذكير المناسبات.")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(16).readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("التزاماتي")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { editing = Obligation(name: "", firstDate: .now) } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("إضافة التزام")
            }
        }
        .fullScreenCover(item: $editing) { item in
            ObligationEditor(item: item, isNew: !items.contains { $0.id == item.id },
                             onSave: save, onDelete: delete)
                .appAppearance()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gold)
            Text("أضف إيجارك وأقساطك وفواتيرك")
                .font(AppFont.uiBold(16))
                .foregroundStyle(Theme.textPrimary)
            Text("وتابع أقرب موعد من الشاشة الرئيسية، ويُخصم من مصروفك اليومي.")
                .font(AppFont.ui(14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Button { editing = Obligation(name: "", firstDate: .now) } label: {
                Label("إضافة التزام", systemImage: "plus")
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

    private func save(_ item: Obligation) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
        ObligationStore.save(items)
    }

    private func delete(_ item: Obligation) {
        items.removeAll { $0.id == item.id }
        ObligationStore.save(items)
    }
}

// MARK: - سطر التزام
private struct ObligationRow: View {
    let item: Obligation

    var body: some View {
        let next = item.nextDate()
        let days = next.map {
            DateHelper.gregorian.dateComponents([.day], from: DateHelper.gregorian.startOfDay(for: .now), to: $0).day ?? 0
        }
        HStack(spacing: 14) {
            Image(systemName: item.type.symbol)
                .font(.system(size: 18))
                .foregroundStyle(Theme.gold)
                .frame(width: 44, height: 44)
                .background(Theme.gold.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(AppFont.uiBold(16))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle(next: next))
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if let days {
                VStack(spacing: 0) {
                    Text(days <= 0 ? "اليوم" : DateHelper.arabic(days))
                        .font(AppFont.number(days <= 0 ? 15 : 22))
                        .foregroundStyle(Theme.textPrimary)
                    if days > 0 {
                        Text("يوم").font(AppFont.ui(11)).foregroundStyle(Theme.textSecondary)
                    }
                }
            } else {
                Text("انتهى").font(AppFont.ui(13)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func subtitle(next: Date?) -> String {
        var parts: [String] = []
        if let next { parts.append(DateHelper.weekdayDayMonth(next)) }
        if item.amount > 0 { parts.append(PaydayFormat.amount(item.amount)) }
        parts.append(item.frequency.title)
        if let count = item.remainingCount(), count > 0 { parts.append("باقي \(DateHelper.arabic(count))") }
        if item.remindsDayBefore { parts.append("🔔") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - إضافة وتعديل
private struct ObligationEditor: View {
    @State var item: Obligation
    let isNew: Bool
    let onSave: (Obligation) -> Void
    let onDelete: (Obligation) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsAllowed = true
    /// نص المبلغ كما يُكتب، ويُحوَّل لرقم عند كل تغيير
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SettingsSection("النوع") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(ObligationType.allCases) { type in
                                typeButton(type)
                            }
                        }
                    }
                    details
                    duration
                    SettingsSection("التذكير") {
                        Toggle("ذكّرني قبل يوم", isOn: $item.remindsDayBefore)
                        Text(notificationsAllowed
                             ? "يصلك تنبيه \(AppSettings.reminderTimeLabel()) في اليوم السابق."
                             : "التنبيهات غير مسموحة للتطبيق. فعّلها من إعدادات الجهاز.")
                            .font(AppFont.ui(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    if !isNew {
                        Button("حذف الالتزام", role: .destructive) {
                            onDelete(item)
                            dismiss()
                        }
                        .font(AppFont.ui(15))
                    }
                }
                .padding(16).readableWidth()
            }
            .font(AppFont.ui(15))
            .foregroundStyle(Theme.textPrimary)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isNew ? "التزام جديد" : "تعديل الالتزام")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ") {
                        item.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(item)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear { amountText = item.amount == 0 ? "" : String(item.amount) }
            .onChange(of: amountText) { _, text in
                item.amount = Self.amount(from: text)
            }
            .onChange(of: item.remindsDayBefore) { _, on in
                guard on else { return }
                Task {
                    let granted = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    notificationsAllowed = granted ?? false
                }
            }
        }
        .tint(Theme.gold)
    }

    private var details: some View {
        SettingsSection("التفاصيل") {
            TextField(item.type.title, text: $item.name)
                .font(AppFont.ui(16))
                .padding(12)
                .background(Theme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Text("المبلغ")
                Spacer()
                TextField("٠", text: $amountText)
                    .amountField()
                    .frame(maxWidth: 140)
                Text("ر.س").foregroundStyle(Theme.textSecondary)
            }
            DatePicker("الموعد القادم", selection: $item.firstDate, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "ar@numbers=arab;calendar=gregorian"))
                .environment(\.calendar, DateHelper.gregorian)
            SettingRow("التكرار") {
                Picker("التكرار", selection: $item.frequency) {
                    ForEach(ObligationFrequency.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var duration: some View {
        SettingsSection("المدة") {
            Toggle("له آخر دفعة", isOn: Binding(
                get: { item.endDate != nil },
                set: { item.endDate = $0 ? DateHelper.gregorian.date(byAdding: .year, value: 1, to: item.firstDate) : nil }))
            if let endDate = item.endDate {
                DatePicker("آخر دفعة", selection: Binding(get: { endDate }, set: { item.endDate = $0 }),
                           in: item.firstDate..., displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "ar@numbers=arab;calendar=gregorian"))
                    .environment(\.calendar, DateHelper.gregorian)
                if let count = item.remainingCount() {
                    Label("باقي \(DateHelper.arabic(count)) دفعة", systemImage: "number")
                        .font(AppFont.ui(13))
                        .foregroundStyle(Theme.gold)
                }
            }
            Text("للأقساط: حدّد آخر قسط، فيختفي الالتزام بعده ويظهر عدد الأقساط الباقية.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private static func amount(from text: String) -> Int {
        Int(text.compactMap(\.wholeNumberValue).map(String.init).joined().prefix(9)) ?? 0
    }

    private func typeButton(_ type: ObligationType) -> some View {
        let isOn = item.type == type
        return Button {
            withAnimation(.snappy) {
                item.type = type
                item.frequency = type.defaultFrequency
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.symbol).font(.system(size: 17))
                Text(type.title).font(AppFont.ui(11)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(isOn ? Theme.onAccent : Theme.textPrimary)
            .background(isOn ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.cardTop),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
