//
//  PaydaySettingsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 10/10/2026.
//

import SwiftUI
import UserNotifications

// MARK: - المال والأعمال
// صفحة الإعدادات: الدفعات الأربع، وما يظهر في ودجت «مواعيد الصرف»
struct FinanceSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SettingsSection("أدواتي") {
                    NavigationLink { ObligationsView() } label: {
                        FinanceToolRow(title: "التزاماتي", symbol: "list.bullet.rectangle.portrait.fill",
                                       detail: obligationsSummary)
                    }
                    .buttonStyle(.plain)
                    NavigationLink { BudgetPage() } label: {
                        FinanceToolRow(title: "مصروف اليوم", symbol: "wallet.bifold.fill", detail: budgetSummary)
                    }
                    .buttonStyle(.plain)
                }
                SettingsSection("الدفعات") {
                    ForEach(Payday.allCases) { payday in
                        NavigationLink { PaydayPage(payday: payday) } label: {
                            PaydaySummaryRow(payday: payday)
                        }
                        .buttonStyle(.plain)
                    }
                }
                PaydaysListSettings()
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("المال والأعمال")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension FinanceSettingsView {
    private var obligationsSummary: String {
        guard let first = ObligationStore.upcoming().first else { return "الإيجار والأقساط والفواتير" }
        let days = DateHelper.gregorian.dateComponents([.day], from: DateHelper.gregorian.startOfDay(for: .now),
                                                       to: first.date).day ?? 0
        return "\(first.obligation.displayName) \(PaydayFormat.remaining(days))"
    }

    private var budgetSummary: String {
        guard let status = Budget.status() else { return "كم تصرف كل يوم حتى الراتب" }
        return status.isOver ? "تجاوزت حصة اليوم" : "باقي لليوم \(PaydayFormat.amount(status.leftToday))"
    }
}

/// سطر أداة في صفحة المال
private struct FinanceToolRow: View {
    let title: String
    let symbol: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color(red: 0.16, green: 0.60, blue: 0.40), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.uiBold(15))
                Text(detail).font(AppFont.ui(12)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.left")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .foregroundStyle(Theme.textPrimary)
        .contentShape(Rectangle())
    }
}

/// صفحة دفعة واحدة
struct PaydayPage: View {
    let payday: Payday

    var body: some View {
        ScrollView {
            PaydaySettingsSection(payday: payday).padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(payday.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// اسم الدفعة وموعدها القادم
struct PaydaySummaryRow: View {
    let payday: Payday

    var body: some View {
        let cycle = payday.cycle()
        HStack(spacing: 12) {
            Image(systemName: payday.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 34, height: 34)
                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(payday.displayName).font(AppFont.uiBold(15))
                Text("\(DateHelper.weekdayDayMonth(cycle.next)) · \(PaydayFormat.remaining(cycle.days))")
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.left")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .foregroundStyle(Theme.textPrimary)
        .contentShape(Rectangle())
    }
}

// MARK: - ودجت «مواعيد الصرف»
struct PaydaysListSettings: View {
    var onChange: () -> Void = {}
    @State private var listed = Set(Payday.allCases.filter(\.isListed))
    @AppStorage(Payday.Key.showsAmount, store: AppGroup.defaults) private var showsAmount = true

    var body: some View {
        SettingsSection("ودجت مواعيد الصرف") {
            ForEach(Payday.allCases) { payday in
                Toggle(isOn: Binding(
                    get: { listed.contains(payday) },
                    set: { on in
                        if on { listed.insert(payday) } else { listed.remove(payday) }
                        AppGroup.defaults.set(on, forKey: Payday.Key.listed(payday))
                        Payday.settingsChanged()
                        onChange()
                    })) {
                    Label(payday.displayName, systemImage: payday.symbol)
                }
            }
            Divider()
            Toggle(isOn: $showsAmount) {
                Label("إظهار المبالغ في الودجات", systemImage: "eye")
            }
            Text("المبالغ تظهر في الودجات المتوسطة والكبيرة فقط، ولا تظهر على شاشة القفل.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
        .onChange(of: showsAmount) {
            Payday.settingsChanged()
            onChange()
        }
    }
}

// MARK: - إعدادات دفعة
// في صفحة الودجت وفي الإعدادات. كل تغيير يحدّث الودجات والتنبيهات مباشرة.
struct PaydaySettingsSection: View {
    let payday: Payday
    /// لتحديث المعاينات في صفحة الودجت
    var onChange: () -> Void = {}
    @AppStorage private var day: Int
    @AppStorage private var shift: WeekendShift
    @AppStorage private var reminder: PaydayReminder
    @AppStorage private var amount: Int
    @AppStorage private var name: String
    @State private var override: Date?
    @State private var notificationsDenied = false
    @State private var amountText = ""

    init(payday: Payday, onChange: @escaping () -> Void = {}) {
        self.payday = payday
        self.onChange = onChange
        let store = AppGroup.defaults
        _day = AppStorage(wrappedValue: payday.officialDay, Payday.Key.day(payday), store: store)
        _shift = AppStorage(wrappedValue: payday.officialShift, Payday.Key.shift(payday), store: store)
        _reminder = AppStorage(wrappedValue: .off, Payday.Key.reminder(payday), store: store)
        _amount = AppStorage(wrappedValue: 0, Payday.Key.amount(payday), store: store)
        _name = AppStorage(wrappedValue: "", Payday.Key.name(payday), store: store)
        _override = State(initialValue: payday.activeOverride())
    }

    var body: some View {
        VStack(spacing: 20) {
            upcoming
            schedule
            exception
            details
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
        .onChange(of: day) { changed() }
        .onChange(of: shift) { changed() }
        .onChange(of: amount) { changed() }
        .onChange(of: name) { changed() }
        .onChange(of: reminder) { _, value in
            Task {
                if value != .off {
                    let granted = (try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound])) ?? false
                    notificationsDenied = !granted
                }
                await PaydayNotifications.reschedule()
            }
        }
    }

    private func changed() {
        Payday.settingsChanged()
        onChange()
    }

    // MARK: الدفعات القادمة
    /// الدفعة القادمة والتي بعدها، ليتأكد المستخدم من أثر الإعدادات
    private var upcoming: some View {
        let first = payday.cycle()
        let calendar = DateHelper.gregorian
        let later = (1...2).reduce(into: [first.next]) { dates, _ in
            let after = calendar.date(byAdding: .day, value: 1, to: dates.last ?? first.next) ?? first.next
            dates.append(payday.cycle(from: after).next)
        }
        return SettingsSection("الدفعات القادمة") {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(DateHelper.weekdayFull(first.next)).font(AppFont.uiBold(17))
                    Text(first.isMoved || first.eid != nil ? movedNote(first) : "في موعدها المعتاد")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(PaydayFormat.remaining(first.days))
                    .font(AppFont.uiBold(15))
                    .foregroundStyle(Theme.gold)
            }
            ProgressView(value: first.progress).tint(Theme.gold)
            ForEach(later.dropFirst(), id: \.self) { date in
                HStack {
                    Text(DateHelper.weekdayDayMonth(date))
                    Spacer()
                    if let eid = PaydayCycle.eidHoliday(on: date) {
                        Text("قد يُقدَّم قبل \(eid)").foregroundStyle(Theme.gold)
                    } else {
                        Text(DateHelper.gregorianMonthName(date)).foregroundStyle(Theme.textSecondary)
                    }
                }
                .font(AppFont.ui(13))
            }
        }
        .animation(.snappy, value: day)
        .animation(.snappy, value: shift)
    }

    private func movedNote(_ cycle: PaydayCycle) -> String {
        if let eid = cycle.eid {
            return "يوافق إجازة \(eid)، وغالباً يُقدَّم الصرف قبلها. إذا أُعلن موعده عدّله من «موعد استثنائي»."
        }
        return payday.activeOverride() != nil ? "موعد استثنائي حدّدته" : "نُقل من يوم \(DateHelper.arabic(day)) بسبب الإجازة"
    }

    // MARK: الموعد
    private var schedule: some View {
        SettingsSection("الموعد") {
            if payday == .salary {
                SettingRow("القطاع") {
                    ChoiceChips(options: [true, false], selection: Binding(
                        get: { day == payday.officialDay && shift == payday.officialShift },
                        set: { isGovernment in
                            // الضغط على الاختيار الحالي لا يغيّر يوم الخاص الذي حدّده المستخدم
                            guard isGovernment != (day == payday.officialDay && shift == payday.officialShift) else { return }
                            if isGovernment {
                                day = payday.officialDay
                                shift = payday.officialShift
                            } else {
                                day = 25
                                shift = .before
                            }
                        })) { isGovernment in
                        Text(isGovernment ? "حكومي وعسكري" : "خاص أو آخر").font(AppFont.ui(14))
                    }
                }
            }
            HStack {
                Text("يوم الصرف في الشهر")
                Spacer()
                Picker("يوم الصرف", selection: $day) {
                    ForEach(1...31, id: \.self) { value in
                        Text(value == 31 ? "آخر يوم" : DateHelper.arabic(value)).tag(value)
                    }
                }
                .labelsHidden()
            }
            SettingRow("إذا صادف الجمعة أو السبت", detail: shift.title) {
                Picker("النقل", selection: $shift) {
                    ForEach(WeekendShift.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Text(shift.detail)
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            Text(payday.officialNote)
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            if day != payday.officialDay || shift != payday.officialShift {
                Button {
                    payday.resetToOfficial()
                    day = payday.officialDay
                    shift = payday.officialShift
                    override = nil
                    changed()
                } label: {
                    Label("الرجوع للموعد الرسمي", systemImage: "arrow.counterclockwise")
                        .font(AppFont.uiBold(14))
                }
            }
        }
    }

    // MARK: موعد استثنائي
    private var exception: some View {
        SettingsSection("موعد استثنائي") {
            Toggle(isOn: Binding(
                get: { override != nil },
                set: { on in setOverride(on ? payday.cycle().next : nil) })) {
                Label("تغيير موعد الدفعة القادمة", systemImage: "calendar.badge.exclamationmark")
            }
            if let override {
                DatePicker("الموعد الجديد", selection: Binding(get: { override }, set: { setOverride($0) }),
                           in: DateHelper.gregorian.startOfDay(for: .now)..., displayedComponents: .date)
                    .environment(\.calendar, DateHelper.gregorian)
            }
            Text("إذا أُعلن تقديم الصرف قبل العيد أو إجازة رسمية. يرجع الموعد المعتاد تلقائياً بعد هذه الدفعة.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func setOverride(_ date: Date?) {
        payday.setOverride(date)
        override = payday.activeOverride()
        changed()
    }

    // MARK: التفاصيل
    private var details: some View {
        SettingsSection("التفاصيل") {
            HStack {
                Text("الاسم في الودجت")
                Spacer()
                TextField(payday.title, text: $name)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 170)
            }
            HStack {
                Text("المبلغ (اختياري)")
                Spacer()
                TextField("٠", text: $amountText)
                    // الأرقام العربية والإنجليزية كلها تُقبل
                    .onAppear { amountText = amount == 0 ? "" : String(amount) }
                    .onChange(of: amountText) { _, text in
                        amount = Int(text.compactMap(\.wholeNumberValue).map(String.init).joined().prefix(9)) ?? 0
                    }
                    .amountField()
                    .frame(maxWidth: 120)
                Text("ر.س").foregroundStyle(Theme.textSecondary)
            }
            Divider()
            SettingRow("التنبيه", detail: reminder == .off ? nil : AppSettings.reminderTimeLabel()) {
                Picker("التنبيه", selection: $reminder) {
                    ForEach(PaydayReminder.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            if notificationsDenied {
                Text("التنبيهات مقفلة للتطبيق. فعّلها من إعدادات الجهاز.")
                    .font(AppFont.ui(12))
                    .foregroundStyle(Color.red.opacity(0.85))
            }
            Text("المبلغ يُحفظ على جهازك فقط. وقت التنبيه نفسه وقت تذكير المناسبات في الإعدادات.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
