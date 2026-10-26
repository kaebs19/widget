//
//  SettingsView.swift
//  Widgets
//
//  Created by Mohammed Saleh on 09/10/2026.
//

import SwiftUI
import WidgetKit

// MARK: - الإعدادات
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WidgetStyleStore.self) private var styles
    @State private var showResetAll = false
    @State private var showResetCounter = false
    @State private var showHowTo = false
    @State private var webPage: URL?
    @Environment(\.openURL) private var openURL
    @AppStorage(AppSettings.Key.haptics, store: AppGroup.defaults) private var haptics = true
    @AppStorage(AppSettings.Key.hijriOffset, store: AppGroup.defaults) private var hijriOffset = 0
    @AppStorage(AppSettings.Key.weekStart, store: AppGroup.defaults) private var weekStart = 1
    @AppStorage(AppSettings.Key.colorScheme, store: AppGroup.defaults) private var colorScheme = ColorSchemeChoice.dark
    @AppStorage(AppSettings.Key.accent, store: AppGroup.defaults) private var accent = AppAccent.gold
    @AppStorage(AppSettings.Key.numerals, store: AppGroup.defaults) private var numerals = Numerals.latin

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    generalGroup
                    group("المحتوى") {
                        row(.prayer)
                        #if !targetEnvironment(macCatalyst)
                        row(.health)
                        #endif
                        row(.occasions)
                        row(.finance)
                        row(.counter)
                    }
                    group("الدعم") {
                        actionRow("طريقة الإضافة", "للشاشة الرئيسية وشاشة القفل", symbol: "questionmark.circle.fill",
                                  color: Color(red: 0.20, green: 0.60, blue: 0.86), chevron: true) { showHowTo = true }
                        actionRow("الأسئلة الشائعة", "إجابات سريعة لأكثر الأسئلة", symbol: "bubble.left.and.text.bubble.right.fill",
                                  color: Color(red: 0.36, green: 0.42, blue: 0.86), external: true) { webPage = AppLinks.faq }
                        actionRow("تواصل معنا", AppLinks.supportEmail, symbol: "envelope.fill",
                                  color: Color(red: 0.18, green: 0.62, blue: 0.52), external: true) {
                            if let url = AppLinks.mail(subject: "دعم تطبيق ويدجت") { openURL(url) }
                        }
                        actionRow("إبلاغ عن خطأ في نص", "آية أو ذكر يحتاج تصحيح", symbol: "exclamationmark.bubble.fill",
                                  color: Color(red: 0.90, green: 0.45, blue: 0.20), external: true) {
                            if let url = AppLinks.mail(subject: "خطأ في نص",
                                                       body: "اسم الودجت:\nالنص الذي فيه الخطأ:\nالتصحيح المقترح:\n") {
                                openURL(url)
                            }
                        }
                        actionRow("قيّم التطبيق", "رأيك يساعدنا نتحسّن", symbol: "star.fill",
                                  color: Color(red: 0.95, green: 0.70, blue: 0.15), external: true) { openURL(AppLinks.writeReview) }
                        ShareLink(item: AppLinks.appStore,
                                  message: Text("جرّب تطبيق ويدجت: ودجات الصلاة والأذكار والتقويم الهجري")) {
                            rowLabel("شارك التطبيق", "أرسله لمن تحب", symbol: "square.and.arrow.up.fill",
                                     color: Color(red: 0.55, green: 0.42, blue: 0.85))
                        }
                        .buttonStyle(.plain)
                        actionRow("تابعنا على X", "@B_c_Arab", symbol: "at",
                                  color: Color(white: 0.2), external: true) { openURL(AppLinks.x) }
                    }
                    group("قانوني") {
                        row(.about)
                        actionRow("سياسة الخصوصية", "كيف نتعامل مع بياناتك", symbol: "hand.raised.fill",
                                  color: Color(red: 0.25, green: 0.52, blue: 0.90), external: true) { webPage = AppLinks.privacy }
                        actionRow("شروط الاستخدام", "شروط استخدام التطبيق", symbol: "doc.text.fill",
                                  color: Color(white: 0.5), external: true) { webPage = AppLinks.terms }
                        NavigationLink { CreditsView() } label: {
                            rowLabel("المصادر والتراخيص", "مصادر النصوص والخطوط والمكتبات", symbol: "books.vertical.fill",
                                     color: Color(red: 0.62, green: 0.48, blue: 0.30), chevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("ويدجت \(AppLinks.version)")
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(16)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("الإعدادات")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("تم") { dismiss() }
                }
            }
            .navigationDestination(for: SettingsPage.self) { page in
                destination(page)
            }
            .sheet(isPresented: $showHowTo) { HowToAddView().appAppearance() }
            #if targetEnvironment(macCatalyst)
            // على الماك تُفتح الصفحات في المتصفح، فهو المعتاد هناك
            .onChange(of: webPage) { _, url in
                if let url { openURL(url) }
                webPage = nil
            }
            #else
            .sheet(item: $webPage) { url in SafariView(url: url).ignoresSafeArea() }
            #endif
        }
        .tint(Theme.accent(accent))
    }

    // MARK: الإعدادات العامة
    // أول ما يراه المستخدم: ما يُختار مرة ويشمل التطبيق والودجات كلها، والسريع منه يتغيّر في مكانه
    private var generalGroup: some View {
        group(L10n.text("الإعدادات العامة")) {
            NavigationLink {
                LanguageSettingsView()
            } label: {
                rowLabel(L10n.text("اللغة"), language.title,
                         symbol: "globe", color: Color(red: 0.28, green: 0.46, blue: 0.88),
                         chevron: true)
            }
            .buttonStyle(.plain)
            controlRow(L10n.text("الأرقام"), symbol: "number", color: Color(red: 0.36, green: 0.42, blue: 0.86)) {
                Picker(L10n.text("الأرقام"), selection: numeralsBinding) {
                    Text("123").tag(Numerals.latin)
                    Text("١٢٣").tag(Numerals.arabic)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
            }
            controlRow(L10n.text("الثيم"), symbol: "circle.lefthalf.filled", color: Color(white: 0.35)) {
                Picker(L10n.text("الثيم"), selection: $colorScheme) {
                    Text(ColorSchemeChoice.dark.title).tag(ColorSchemeChoice.dark)
                    Text(ColorSchemeChoice.light.title).tag(ColorSchemeChoice.light)
                    Text(L10n.text("تلقائي")).tag(ColorSchemeChoice.system)
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }
            controlRow(L10n.text("لون التطبيق"), symbol: "paintpalette.fill", color: Color(red: 0.93, green: 0.58, blue: 0.20)) {
                HStack(spacing: 8) {
                    ForEach(AppAccent.allCases) { option in
                        AccentSwatch(accent: option, isSelected: option == accent, size: 24) {
                            withAnimation(.snappy) { accent = option }
                        }
                    }
                }
            }
            row(.location)
            row(.notifications)
            row(.widgetDefaults)
            row(.calendar)
            controlRow(L10n.text("الاهتزاز"), symbol: "iphone.radiowaves.left.and.right", color: Color(red: 0.55, green: 0.42, blue: 0.85)) {
                Toggle(L10n.text("الاهتزاز"), isOn: $haptics).labelsHidden()
            }
        }
    }

    /// الأرقام تشمل كل الودجات حتى المخصّصة، فالتغيير يمر من المتجر
    private var numeralsBinding: Binding<Numerals> {
        Binding(get: { numerals }, set: { styles.applyNumerals($0) })
    }

    /// سطر فيه عنصر تحكم مباشر بدل فتح صفحة
    private func controlRow<Control: View>(_ title: String, symbol: String, color: Color,
                                           @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(AppFont.uiBold(15))
                .lineLimit(1)
                .fixedSize()
            Spacer(minLength: 8)
            control()
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.uiBold(14))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 6)
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.cardTop.opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func row(_ page: SettingsPage) -> some View {
        NavigationLink(value: page) {
            HStack(spacing: 12) {
                Image(systemName: page.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(page.color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(page.title).font(AppFont.uiBold(15))
                    Text(summary(page))
                        .font(AppFont.ui(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.left")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// سطر يفتح رابطاً أو ينفّذ إجراءً بدل صفحة
    private func actionRow(_ title: String, _ subtitle: String, symbol: String, color: Color,
                           external: Bool = false, chevron: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowLabel(title, subtitle, symbol: symbol, color: color, chevron: chevron, external: external)
        }
        .buttonStyle(.plain)
    }

    private func rowLabel(_ title: String, _ subtitle: String, symbol: String, color: Color,
                          chevron: Bool = false, external: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.uiBold(15))
                Text(subtitle)
                    .font(AppFont.ui(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if external || chevron {
                Image(systemName: external ? "arrow.up.left" : "chevron.left")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    /// سطر صغير تحت كل قسم يلخّص إعداده الحالي
    private func summary(_ page: SettingsPage) -> String {
        switch page {
        case .prayer:
            "\(PrayerLocation.current.city) · \(PrayerSchedule.method.title)"
        case .occasions:
            OccasionStore.all().isEmpty ? "أعياد الميلاد والذكريات" : "\(DateHelper.arabic(OccasionStore.all().count)) مناسبة"
        case .health:
            HealthCache.isConnected
                ? HealthCache.load().map { "\(HealthMetric.steps.format($0.value(.steps))) خطوة اليوم" } ?? "مربوط بتطبيق الصحة"
                : "الخطوات والسعرات والنوم"
        case .finance:
            Payday.allCases.map { $0.cycle() }.min { $0.next < $1.next }
                .map { "\($0.payday.displayName) \(PaydayFormat.remaining($0.days))" } ?? ""
        case .counter:
            haptics ? "الاهتزاز مفعّل" : "الاهتزاز متوقف"
        case .location:
            PrayerLocation.saved?.city ?? L10n.text("مكة المكرمة (افتراضي)")
        case .notifications:
            PrayerNotifications.isEnabled ? L10n.text("تنبيه الأذان مفعّل") : L10n.text("الأذان والتذكيرات")
        case .widgetDefaults:
            L10n.text("الخلفية والخط للودجات")
        case .calendar:
            "تصحيح الهجري: \(offsetLabel)"
        case .about:
            "الإصدار \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        }
    }

    @ViewBuilder
    private func destination(_ page: SettingsPage) -> some View {
        switch page {
        case .occasions:
            OccasionsView()
        case .finance:
            FinanceSettingsView()
        case .health:
            HealthSettingsPage()
        case .notifications:
            NotificationSettingsPage()
                .navigationTitle(page.title)
                .navigationBarTitleDisplayMode(.inline)
        default:
            ScrollView {
                VStack(spacing: 20) {
                    switch page {
                    case .prayer: PrayerSettingsSection()
                    case .counter: counterSection
                    case .location: locationSection
                    case .widgetDefaults: widgetDefaultsSection
                    case .calendar: calendarSection
                    case .about, .occasions, .finance, .health, .notifications: aboutSection
                    }
                }
                .padding(16)
                .readableWidth()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: الموقع
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PrayerLocationSettings()
            Text(L10n.text("موقعك يحسب أوقات الصلاة واتجاه القبلة، ويبقى على جهازك ولا يُشارك مع أحد."))
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 6)
        }
    }

    // MARK: افتراضيات الودجات
    private var defaultStyle: Binding<WidgetStyle> {
        Binding(get: { styles.defaultStyle }, set: { styles.saveDefault($0) })
    }

    private var widgetDefaultsSection: some View {
        SettingsSection("الشكل الافتراضي للودجات") {
            WidgetPreviewView(kind: .hijriDate, size: .medium, style: styles.defaultStyle)
                .aspectRatio(WidgetSize.medium.aspectRatio, contentMode: .fit)
                .cardStyle(radius: 20)
                .animation(.snappy, value: styles.defaultStyle)
            SettingRow("الخلفية") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(BackgroundPreset.allCases) { preset in
                            PresetSwatch(preset: preset, isSelected: styles.defaultStyle.background == .preset(preset)) {
                                withAnimation(.snappy) { defaultStyle.wrappedValue.apply(preset) }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            SettingRow("خط النص") {
                ChoiceChips(options: AppFontFamily.customizable, selection: defaultStyle.contentFont) { family in
                    Text(family.displayName).font(.app(family, size: 16))
                }
            }
            Text("يظهر في كل ودجت ما خصّصته من صفحته. الودجات المخصّصة تبقى على شكلها.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            Button { showResetAll = true } label: {
                Label("تطبيق على كل الودجات", systemImage: "square.on.square")
                    .font(AppFont.uiBold(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            .confirmationDialog("إلغاء تخصيص كل الودجات؟", isPresented: $showResetAll, titleVisibility: .visible) {
                Button("تطبيق الشكل الافتراضي على الكل", role: .destructive) { styles.resetAllToDefault() }
            } message: {
                Text("كل ودجت خصّصته يرجع للشكل الافتراضي. أنماطك المحفوظة تبقى.")
            }
        }
    }

    // MARK: العدّاد والتنبيهات
    private var counterSection: some View {
        SettingsSection("عدّاد الذكر") {
            Toggle("اهتزاز عند العدّ داخل التطبيق", isOn: $haptics)
            Button(role: .destructive) { showResetCounter = true } label: {
                Label("تصفير عدّاد اليوم", systemImage: "arrow.counterclockwise")
            }
            .confirmationDialog("تصفير عدد اليوم لكل الأذكار؟", isPresented: $showResetCounter, titleVisibility: .visible) {
                Button("تصفير", role: .destructive) {
                    TasbeehCounter.resetToday()
                    WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.istighfar.rawValue)
                }
            }
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }

    // MARK: التقويم
    private var calendarSection: some View {
        SettingsSection("التقويم") {
            SettingRow("تصحيح التاريخ الهجري", detail: offsetLabel) {
                HStack {
                    Text(DateHelper.hijriDayMonth(.now) + " " + DateHelper.hijriYear(.now) + " هـ")
                        .font(AppFont.uiBold(16))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Stepper("تصحيح التاريخ الهجري", value: $hijriOffset, in: -2...2)
                        .labelsHidden()
                }
            }
            Text("حسب تقويم أم القرى. إذا اختلف إعلان رؤية الهلال، زِد أو أنقص يوماً، ويتعدّل التاريخ وعدّاد رمضان والعيد.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
            Divider()
            SettingRow("بداية الأسبوع") {
                Picker("بداية الأسبوع", selection: $weekStart) {
                    Text("السبت").tag(7)
                    Text("الأحد").tag(1)
                    Text("الاثنين").tag(2)
                }
                .pickerStyle(.segmented)
            }
        }
        .onChange(of: hijriOffset) { WidgetCenter.shared.reloadAllTimelines() }
        .onChange(of: weekStart) { WidgetCenter.shared.reloadAllTimelines() }
    }

    private var offsetLabel: String {
        switch hijriOffset {
        case 0: "بدون تصحيح"
        case let days where days > 0: "+\(DateHelper.arabic(days)) يوم"
        default: "−\(DateHelper.arabic(-hijriOffset)) يوم"
        }
    }

    // MARK: عن التطبيق
    private var aboutSection: some View {
        SettingsSection("عن التطبيق") {
            HStack {
                Text("الإصدار")
                Spacer()
                Text(AppLinks.version)
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack {
                Text("الموقع")
                Spacer()
                Link("kaebs19.github.io", destination: AppLinks.site)
                    .environment(\.layoutDirection, .leftToRight)
            }
            Text("نص القرآن الكريم وخطه من مجمع الملك فهد لطباعة المصحف الشريف.")
                .font(AppFont.ui(12))
                .foregroundStyle(Theme.textSecondary)
        }
        .font(AppFont.ui(15))
        .foregroundStyle(Theme.textPrimary)
    }
}

// MARK: - دائرة لون التطبيق
private struct AccentSwatch: View {
    let accent: AppAccent
    let isSelected: Bool
    var size: CGFloat = 34
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let hex = colorScheme == .light ? accent.hex.light : accent.hex.dark
        Button(action: action) {
            Circle()
                .fill(Color(Color.Resolved(hex: hex)))
                .frame(width: size, height: size)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.38, weight: .bold))
                            .foregroundStyle(colorScheme == .light ? .white : .black)
                    }
                }
                .overlay(Circle().strokeBorder(Theme.textPrimary.opacity(isSelected ? 0.8 : 0), lineWidth: 2).padding(-size * 0.12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accent.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - أقسام الإعدادات
enum SettingsPage: Hashable {
    case prayer, health, occasions, finance, counter, location, notifications, widgetDefaults, calendar, about

    var title: String {
        switch self {
        case .prayer:         "أوقات الصلاة"
        case .occasions:      "مناسباتي"
        case .finance:        "المال والأعمال"
        case .health:         "الصحة"
        case .counter:        "عدّاد الذكر"
        case .location:       L10n.text("الموقع")
        case .notifications:  L10n.text("الإشعارات")
        case .widgetDefaults: L10n.text("الشكل العام")
        case .calendar:       "التقويم"
        case .about:          "عن التطبيق"
        }
    }

    var symbol: String {
        switch self {
        case .prayer:         "moon.stars.fill"
        case .occasions:      "birthday.cake.fill"
        case .finance:        "banknote.fill"
        case .health:         "heart.fill"
        case .counter:        "circle.dotted.circle"
        case .location:       "location.fill"
        case .notifications:  "bell.badge.fill"
        case .widgetDefaults: "square.on.square.fill"
        case .calendar:       "calendar"
        case .about:          "info.circle.fill"
        }
    }

    /// لون مربع الأيقونة، على طريقة إعدادات iOS
    var color: Color {
        switch self {
        case .prayer:         Color(red: 0.11, green: 0.49, blue: 0.33)
        case .occasions:      Color(red: 0.85, green: 0.36, blue: 0.47)
        case .finance:        Color(red: 0.16, green: 0.60, blue: 0.40)
        case .health:         Color(red: 1.0, green: 0.22, blue: 0.37)
        case .counter:        Color(red: 0.55, green: 0.42, blue: 0.85)
        case .location:       Color(red: 0.20, green: 0.55, blue: 0.95)
        case .notifications:  Color(red: 0.92, green: 0.30, blue: 0.30)
        case .widgetDefaults: Color(red: 0.25, green: 0.52, blue: 0.90)
        case .calendar:       Color(red: 0.88, green: 0.30, blue: 0.27)
        case .about:          Color(white: 0.55)
        }
    }
}
