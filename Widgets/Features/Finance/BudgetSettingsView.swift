//
//  BudgetSettingsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import SwiftUI

// MARK: - مصروف اليوم
// في صفحة الودجت وفي الإعدادات: الرصيد، وتسجيل مصروف، وإعدادات الحساب
struct BudgetSettingsSection: View {
    var onChange: () -> Void = {}
    @State private var status = Budget.status()
    @State private var balanceText = ""
    @State private var spendText = ""
    @State private var showClear = false
    @FocusState private var focused: Bool
    @AppStorage(Budget.Key.payday, store: AppGroup.defaults) private var payday = Payday.salary
    @AppStorage(Budget.Key.subtractsObligations, store: AppGroup.defaults) private var subtractsObligations = true
    @AppStorage(Budget.Key.smallStep, store: AppGroup.defaults) private var smallStep = 20
    @AppStorage(Budget.Key.largeStep, store: AppGroup.defaults) private var largeStep = 100

    private static let steps = [5, 10, 20, 50, 100, 200, 500]

    var body: some View {
        VStack(spacing: 20) {
            if let status { summary(status) }
            balanceSection
            if status != nil { spendSection }
            optionsSection
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
        .onChange(of: payday) { changed() }
        .onChange(of: subtractsObligations) { changed() }
        .onChange(of: smallStep) { changed() }
        .onChange(of: largeStep) { changed() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("تم", systemImage: "checkmark") { focused = false }
            }
        }
    }

    private func changed() {
        status = Budget.status()
        Budget.reload()
        onChange()
    }

    private static func number(_ text: String) -> Int? {
        Int(text.compactMap(\.wholeNumberValue).map(String.init).joined().prefix(9))
    }

    // MARK: الملخص
    private func summary(_ status: BudgetStatus) -> some View {
        SettingsSection("اليوم") {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(DateHelper.arabic(abs(status.leftToday)))
                        .font(AppFont.number(34))
                        .foregroundStyle(status.isOver ? .red : Theme.textPrimary)
                    Text(status.isOver ? "ر.س تجاوزت حصة اليوم" : "ر.س باقي لليوم")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    line("حصة اليوم", PaydayFormat.amount(status.daily))
                    line("صرفت اليوم", PaydayFormat.amount(status.spentToday))
                    line(status.payday.displayName, PaydayFormat.remaining(status.days))
                }
            }
            ProgressView(value: status.progress).tint(status.isOver ? .red : Theme.gold)
            if status.obligations > 0 {
                Text("حُجز حسابيًا مبلغ \(PaydayFormat.amount(status.obligations)) للالتزامات المسجّلة قبل \(status.payday.displayName)، لتقدير حصة اليوم فقط. لا يتم سحب أو دفع أي مبلغ.")
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            if status.needsUpdate {
                Label("نزل \(status.payday.displayName)؟ حدّث رصيدك لتُحسب الأيام القادمة صح.",
                      systemImage: "exclamationmark.circle")
                    .font(AppFont.ui(13))
                    .foregroundStyle(Theme.gold)
            }
        }
    }

    private func line(_ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(title).foregroundStyle(Theme.textSecondary)
            Text(value).font(AppFont.uiBold(13))
        }
        .font(AppFont.ui(13))
    }

    // MARK: الرصيد
    private var balanceSection: some View {
        SettingsSection("ميزانية يدوية") {
            SettingRow(status == nil ? "مبلغ الميزانية" : "رصيد الميزانية المسجّل",
                       detail: status.map { PaydayFormat.amount($0.balance) }) {
                HStack(spacing: 8) {
                    TextField(status == nil ? "أدخل مبلغ الميزانية يدويًا" : "مبلغ ميزانية جديد", text: $balanceText)
                        .amountField()
                        .focused($focused)
                    Text("ر.س").foregroundStyle(Theme.textSecondary)
                }
                .padding(12)
                .background(Theme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
            }
            Button {
                guard let value = Self.number(balanceText) else { return }
                Budget.setBalance(value)
                balanceText = ""
                focused = false
                changed()
            } label: {
                Label(status == nil ? "احسب الميزانية" : "تحديث الميزانية", systemImage: "checkmark.circle")
                    .font(AppFont.uiBold(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(Theme.onAccent)
                    .background(Theme.gold, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(Self.number(balanceText) == nil)
            Text("هذه أداة حساب وتسجيل يدوي فقط. التطبيق لا يتصل بحسابك البنكي ولا يسحب أو يحوّل أو يدفع أي أموال. يُحفظ مبلغ الميزانية الذي تدخله على جهازك.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: تسجيل مصروف
    private var spendSection: some View {
        SettingsSection("تسجيل مصروف يدوي") {
            HStack(spacing: 10) {
                TextField("المبلغ", text: $spendText)
                    .amountField()
                    .focused($focused)
                    .padding(10)
                    .background(Theme.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                Button("سجّل") {
                    guard let value = Self.number(spendText), value > 0 else { return }
                    Budget.spend(value)
                    spendText = ""
                    focused = false
                    changed()
                }
                .font(AppFont.uiBold(15))
                .disabled((Self.number(spendText) ?? 0) == 0)
            }
            HStack(spacing: 8) {
                ForEach([smallStep, largeStep, largeStep * 5], id: \.self) { amount in
                    Button {
                        Budget.spend(amount)
                        changed()
                    } label: {
                        Text("سجّل \(DateHelper.arabic(amount))")
                            .font(AppFont.uiBold(14))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(Theme.gold.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            if Budget.lastSpend > 0 {
                Button {
                    Budget.undoLastSpend()
                    changed()
                } label: {
                    Label("تراجع عن آخر مصروف (\(DateHelper.arabic(Budget.lastSpend)))", systemImage: "arrow.uturn.backward")
                        .font(AppFont.ui(14))
                }
            }
        }
    }

    // MARK: الإعدادات
    private var optionsSection: some View {
        SettingsSection("الحساب") {
            HStack {
                Text("حتى موعد")
                Spacer()
                Picker("حتى موعد", selection: $payday) {
                    ForEach(Payday.allCases) { Text($0.displayName).tag($0) }
                }
                .labelsHidden()
            }
            Toggle("احتساب الالتزامات ضمن الميزانية", isOn: $subtractsObligations)
            Text("عند التفعيل، نستبعد قيمة الالتزامات التي أدخلتها من المبلغ المتاح لحساب حصة اليوم فقط. هذا حجز حسابي اختياري، ولا يسدّد الالتزامات أو يخصم أموالًا من حسابك البنكي.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            NavigationLink { ObligationsView() } label: {
                Label("التزاماتي", systemImage: "list.bullet.rectangle.portrait")
                    .font(AppFont.uiBold(14))
            }
            Divider()
            SettingRow("مبالغ التسجيل السريع في الودجت") {
                HStack {
                    stepPicker("الأول", selection: $smallStep)
                    Spacer()
                    stepPicker("الثاني", selection: $largeStep)
                }
            }
            if status != nil {
                Button("إيقاف الحساب ومسح الرصيد", role: .destructive) { showClear = true }
                    .font(AppFont.ui(14))
                    .confirmationDialog("مسح الرصيد والمصروف؟", isPresented: $showClear, titleVisibility: .visible) {
                        Button("مسح", role: .destructive) {
                            Budget.clear()
                            changed()
                        }
                    }
            }
        }
    }

    private func stepPicker(_ title: String, selection: Binding<Int>) -> some View {
        HStack(spacing: 4) {
            Text(title).foregroundStyle(Theme.textSecondary)
            Picker(title, selection: selection) {
                ForEach(Self.steps, id: \.self) { Text(DateHelper.arabic($0)).tag($0) }
            }
            .labelsHidden()
        }
        .font(AppFont.ui(14))
        .fixedSize()
    }
}

/// صفحة مصروف اليوم من الإعدادات
struct BudgetPage: View {
    var body: some View {
        ScrollView {
            BudgetSettingsSection().padding(16).readableWidth()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("مصروف اليوم")
        .navigationBarTitleDisplayMode(.inline)
    }
}
