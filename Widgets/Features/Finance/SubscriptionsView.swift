import SwiftUI

struct SubscriptionsView: View {
    @State private var items = SubscriptionStore.all()
    @State private var editing: Subscription?

    var body: some View {
        List {
            Section {
                LabeledContent("المجموع الشهري التقريبي", value: SubscriptionStore.amountLabel(items.filter(\.isActive).reduce(0) { $0 + $1.monthlyAmount }))
            } footer: {
                Text("المبالغ بالريال السعودي. يُقسم الاشتراك السنوي على ١٢ لحساب المتوسط الشهري. نفترض استمرار التجديد حتى توقف الاشتراك هنا.")
            }
            Section("الاشتراكات") {
                if items.isEmpty {
                    Text("أضف أول اشتراك من زر +")
                        .foregroundStyle(.secondary)
                }
                ForEach(items.sorted { $0.nextRenewal() < $1.nextRenewal() }) { item in
                    Button { editing = item } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.name).foregroundStyle(Theme.textPrimary)
                                Text(item.isActive ? "التجديد: " + DateHelper.weekdayDayMonth(item.nextRenewal()) : "متوقف")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 5) {
                                Text(SubscriptionStore.amountLabel(item.amount))
                                Text(item.cycle.title).font(.caption).foregroundStyle(.secondary)
                            }
                            .foregroundStyle(Theme.gold)
                        }
                    }
                    .swipeActions {
                        Button("حذف", role: .destructive) {
                            items.removeAll { $0.id == item.id }
                            SubscriptionStore.save(items)
                        }
                    }
                }
            }
        }
        .navigationTitle("اشتراكاتي")
        .toolbar {
            Button { editing = Subscription(name: "", amount: 0) } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("إضافة اشتراك")
        }
        .sheet(item: $editing) { item in
            SubscriptionEditor(item: item) { updated in
                if let index = items.firstIndex(where: { $0.id == updated.id }) {
                    items[index] = updated
                } else {
                    items.append(updated)
                }
                SubscriptionStore.save(items)
            }
            .appAppearance()
        }
    }
}

private struct SubscriptionEditor: View {
    @State var item: Subscription
    let onSave: (Subscription) -> Void
    @Environment(\.dismiss) private var dismiss

    private var valid: Bool {
        !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && item.amount.isFinite && item.amount >= 0.01 && item.amount <= 1_000_000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("التفاصيل") {
                    TextField("اسم الاشتراك", text: $item.name)
                    TextField("المبلغ بالريال لكل دورة", value: $item.amount, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("دورة التجديد", selection: $item.cycle) {
                        ForEach(SubscriptionCycle.allCases) { cycle in
                            Text(cycle.title).tag(cycle)
                        }
                    }
                    DatePicker("تاريخ التجديد", selection: $item.renewalDate, displayedComponents: .date)
                        .environment(\.calendar, DateHelper.gregorian)
                    Toggle("اشتراك نشط", isOn: $item.isActive)
                }
            }
            .navigationTitle("تفاصيل الاشتراك")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("إلغاء", systemImage: "xmark") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("حفظ", systemImage: "checkmark") {
                        item.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        item.amount = (item.amount * 100).rounded() / 100
                        onSave(item)
                        dismiss()
                    }
                    .disabled(!valid)
                }
            }
        }
    }
}
