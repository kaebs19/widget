//
//  WidgetDetailView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// المعاينة وتحتها التخصيص مباشرة. التعديلات تظهر في المعاينة، ولا تُحفظ إلا بزر ✓.
struct WidgetDetailView: View {
    let kind: WidgetKind
    @Environment(WidgetStyleStore.self) private var styles
    @Environment(\.dismiss) private var dismiss
    @State private var size: WidgetSize
    /// التعديلات غير المحفوظة؛ nil تعني الشكل المحفوظ كما هو
    @State private var draft: WidgetStyle?
    @State private var isFavorite = false
    @State private var showHowTo = false
    @State private var showDiscard = false
    /// الذكر المعروض في معاينة ودجت العدّاد (في الشاشة الرئيسية يُختار من «تعديل الودجت»)
    @State private var tasbeeh: TasbeehDhikr = .istighfar
    /// يزيد مع كل تغيير في إعدادات المال، فتُرسم المعاينات من جديد
    @State private var revision = 0
    /// خيارات «الأيام والشهور»: تُحفظ فوراً لأنها ليست جزءاً من الشكل
    @State private var nameOptions: NameOptions
    @State private var showPaywall = false
    @Environment(StoreManager.self) private var store
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }

    init(kind: WidgetKind) {
        self.kind = kind
        _nameOptions = State(initialValue: NameOptions.load(for: kind))
        // نبدأ بالحجم اللي ظهر في المعرض
        #if DEBUG
        let requestedSize = UserDefaults.standard.string(forKey: "screenshotSize").flatMap(WidgetSize.init(rawValue:))
        _size = State(initialValue: requestedSize.flatMap { kind.supportedSizes.contains($0) ? $0 : nil } ?? kind.previewSize)
        #else
        _size = State(initialValue: kind.previewSize)
        #endif
    }

    private var saved: WidgetStyle { styles.style(for: kind) }
    private var style: WidgetStyle { draft ?? saved }
    private var hasChanges: Bool { draft.map { $0 != saved } ?? false }

    private var styleBinding: Binding<WidgetStyle> {
        Binding(get: { style }, set: { draft = $0 })
    }

    private var preview: some View {
        VStack(spacing: 12) {
            // يُرسم بمقاس الودجت الحقيقي ثم يُصغَّر كاملاً، فالمعاينة تطابق الشاشة الرئيسية
            // ولا يُقص نص (آية طويلة مثلاً) لأن المساحة أصغر من الودجت
            GeometryReader { proxy in
                WidgetPreviewView(kind: kind, size: size, style: style, tasbeeh: tasbeeh, nameOptions: nameOptions)
                    .id(revision)
                    .frame(width: size.size.width, height: size.size.height)
                    .cardStyle(radius: 24)
                    .scaleEffect(proxy.size.width / size.size.width)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .aspectRatio(size.aspectRatio, contentMode: .fit)
            // الآيباد والماك يتسعان لمعاينة أكبر
            .frame(maxWidth: size == .small ? (isWide ? 220 : 170) : (isWide ? 480 : .infinity),
                   maxHeight: isWide ? (size == .large ? 420 : 240) : (kind == .weather && size == .large ? 300 : 200))
            .animation(.snappy, value: size)
            .animation(.snappy, value: style)

            if kind.supportedSizes.count > 1 {
                Picker("الحجم", selection: $size) {
                    ForEach(kind.supportedSizes, id: \.self) { s in
                        Text(s.title).tag(s)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding([.horizontal, .top], 16)
        .padding(.bottom, 8)
    }

    var body: some View {
        VStack(spacing: 0) {
            // المعاينة ثابتة أعلى الصفحة، فتشوف أثر كل تعديل وأنت تمرّر الخيارات
            preview
            ScrollView {
                VStack(spacing: 20) {
                    Text(kind.subtitle)
                        .font(AppFont.ui(14))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if kind.isPremium {
                        if !store.isActive { premiumBanner }
                        NameOptionsSection(kind: kind, options: $nameOptions)
                    }

                    if kind == .weather { WeatherSettingsView() }

                    if kind.category == .prayer {
                        PrayerSettingsSection()
                    }

                    if let payday = kind.payday {
                        PaydaySettingsSection(payday: payday) { revision += 1 }
                    }

                    if kind == .paydays {
                        SettingsSection("الدفعات") {
                            ForEach(Payday.allCases) { payday in
                                NavigationLink { PaydayPage(payday: payday) } label: {
                                    PaydaySummaryRow(payday: payday)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        PaydaysListSettings { revision += 1 }
                    }

                    if kind == .quranGoal {
                        QuranGoalSettings { revision += 1 }
                    }

                    if kind == .subscriptions {
                        NavigationLink("إدارة الاشتراكات") { SubscriptionsView() }
                            .font(AppFont.uiBold(15))
                    }

                    if kind == .dailyOverview {
                        PrayerSettingsSection()
                        NavigationLink("إدارة المناسبات") { OccasionsView() }
                            .font(AppFont.uiBold(15))
                    }

                    if kind == .obligations {
                        NavigationLink { ObligationsView() } label: {
                            Label("التزاماتي: أضف إيجاراً أو قسطاً", systemImage: "list.bullet.rectangle.portrait")
                                .font(AppFont.uiBold(15))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(Theme.onAccent)
                                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    if kind == .healthWater {
                        NavigationLink("هدف الماء وحجم الكوب وسجل اليوم") { WaterTrackingView() }
                            .font(AppFont.uiBold(15))
                    } else if kind.category == .health {
                        if kind == .healthWeekly {
                            NavigationLink("تفاصيل أسبوعي الصحي") { HealthInsightsPage(mode: .weekly) }
                        } else if kind == .healthStreak {
                            NavigationLink("الاستمرارية وتقويم الإنجاز") { HealthInsightsPage(mode: .streak) }
                        } else if kind == .healthWorkouts {
                            NavigationLink("تفاصيل التمارين") { HealthInsightsPage(mode: .workouts) }
                        } else if kind == .healthSleepWeek {
                            NavigationLink("تفاصيل نوم الأسبوع") { HealthMetricDetailView(metric: .sleep) }
                        }
                        HealthSettingsSection { revision += 1 }
                    }

                    if kind == .budget {
                        BudgetSettingsSection { revision += 1 }
                    }

                    if kind == .specialOccasion {
                        NavigationLink { OccasionsView() } label: {
                            Label("مناسباتي: أضف عيد ميلاد أو ذكرى", systemImage: "birthday.cake")
                                .font(AppFont.uiBold(15))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .foregroundStyle(Theme.onAccent)
                                .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16))
                        }
                        ReminderPermissionView()
                    }

                    if kind == .istighfar {
                        SettingsSection("الذكر") {
                            ChoiceChips(options: TasbeehDhikr.allCases, selection: $tasbeeh) { dhikr in
                                Text(dhikr.isLong ? "\(dhikr.title) · \(dhikr.goal == 1 ? L10n.text("مرة") : "١٠٠")" : dhikr.title)
                                    .font(AppFont.ui(14))
                            }
                            Text("كل ذكر له عدده اليومي. لتغيير الذكر في الشاشة الرئيسية: اضغط مطولاً على الودجت ثم «تعديل الودجت».")
                                .font(AppFont.ui(12))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    WidgetCustomizeView(kind: kind, style: styleBinding)

                    LockScreenPreview(kind: kind, style: style, tasbeeh: tasbeeh)
                        .id(revision)
                }
                .padding(16)
                .readableWidth()
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
        // فيه تعديلات غير محفوظة: زر رجوع يسأل قبل ما تضيع
        .navigationBarBackButtonHidden(hasChanges)
        .toolbar {
            if hasChanges {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showDiscard = true } label: {
                        Label(L10n.text("رجوع"), systemImage: "chevron.backward")
                    }
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    var favorites = Set(UserDefaults.standard.stringArray(forKey: "favoriteWidgetKinds") ?? [])
                    if favorites.contains(kind.rawValue) {
                        favorites.remove(kind.rawValue)
                    } else {
                        favorites.insert(kind.rawValue)
                    }
                    UserDefaults.standard.set(favorites.sorted(), forKey: "favoriteWidgetKinds")
                    isFavorite = favorites.contains(kind.rawValue)
                } label: {
                    Label(L10n.text(isFavorite ? "إزالة من المفضلة" : "إضافة إلى المفضلة"), systemImage: isFavorite ? "heart.fill" : "heart")
                }
                .accessibilityValue(L10n.text(isFavorite ? "في المفضلة" : "غير مضاف"))
                Button { showHowTo = true } label: {
                    Label(L10n.text("طريقة إضافة الودجت"), systemImage: "questionmark.circle")
                }
                Button {
                    styles.save(style, for: [kind])
                    draft = nil
                } label: {
                    Image(systemName: "checkmark")
                }
                .disabled(!hasChanges)
                .accessibilityLabel("حفظ")
            }
        }
        .onAppear {
            revision += 1
            isFavorite = (UserDefaults.standard.stringArray(forKey: "favoriteWidgetKinds") ?? []).contains(kind.rawValue)
        }
        .tint(Theme.gold)
        .confirmationDialog("عندك تعديلات ما حفظتها", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("حفظ والرجوع") {
                styles.save(style, for: [kind])
                dismiss()
            }
            Button("تجاهل التعديلات", role: .destructive) { dismiss() }
        }
        .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
        .sheet(isPresented: $showPaywall) { PaywallView().environment(store).environment(styles).appAppearance() }
        .onChange(of: nameOptions) { _, options in
            NameOptions.save(options, for: kind)
            revision += 1
            // الخط المختار يغيّر ألوان التصميم الافتراضية للنوع
            styles.reload()
            WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
        }
    }

    private var premiumBanner: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill").font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.text("هذا الودجت ضمن الاشتراك")).font(AppFont.uiBold(15))
                    Text(L10n.text("جرّبه هنا كما تشاء، ويُفتح في شاشتك بعد الاشتراك")).font(AppFont.ui(12)).opacity(0.85)
                }
                Spacer()
                Image(systemName: "chevron.forward").font(.system(size: 13, weight: .semibold))
            }
            .padding(16)
            .foregroundStyle(Theme.onAccent)
            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - خيارات الأيام والشهور
private struct NameOptionsSection: View {
    let kind: WidgetKind
    @Binding var options: NameOptions

    var body: some View {
        if kind.usesShape {
            SettingsSection(L10n.text("الخط")) {
                ChoiceChips(options: NameShape.allCases, selection: $options.shape) { Text($0.title).font(AppFont.ui(14)) }
            }
        }
        if kind == .monthBehind || kind == .monthNumber {
            SettingsSection(L10n.text("التقويم")) {
                ChoiceChips(options: NameCalendar.allCases, selection: $options.calendar) { Text($0.title).font(AppFont.ui(14)) }
            }
        }
        if kind == .dayNumber {
            SettingsSection(L10n.text("التخطيط")) {
                ChoiceChips(options: DayNumberLayout.allCases, selection: $options.dayLayout) { Text($0.title).font(AppFont.ui(14)) }
            }
        }
        if kind == .monthNumber {
            SettingsSection(L10n.text("التخطيط")) {
                ChoiceChips(options: MonthNumberLayout.allCases, selection: $options.monthLayout) { Text($0.title).font(AppFont.ui(14)) }
            }
        }
        if kind == .hijriCountdown {
            SettingsSection(L10n.text("المناسبة")) {
                ChoiceChips(options: HijriTarget.allCases, selection: $options.target) { Text($0.title).font(AppFont.ui(14)) }
            }
        }
    }
}
